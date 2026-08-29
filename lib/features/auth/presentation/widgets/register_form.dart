import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_alert_dialog.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/google_button.dart';
import '../../../../core/widgets/labeled_divider.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../application/auth_controller.dart';
import '../otp_verification_screen.dart';
import 'auth_error_mapper.dart';
import 'auth_footer_link.dart';

const _kPasswordMismatchError = 'Konfirmasi kata sandi belum cocok.';

class RegisterForm extends ConsumerStatefulWidget {
  const RegisterForm({
    super.key,
    required this.onSwitchToLogin,
    required this.onGooglePressed,
    this.isGoogleLoading = false,
  });

  final VoidCallback onSwitchToLogin;
  final Future<void> Function() onGooglePressed;
  final bool isGoogleLoading;

  @override
  ConsumerState<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends ConsumerState<RegisterForm> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _dateOfBirthText = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirmation = TextEditingController();

  DateTime? _dateOfBirth;
  Map<String, String> _errors = {};
  bool _submitting = false;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _dateOfBirthFormat = DateFormat('d MMMM yyyy', 'id_ID');

  @override
  void initState() {
    super.initState();
    // Cek kecocokan kata sandi & konfirmasi secara langsung saat mengetik
    // (bukan cuma pas submit) — cukup trigger rebuild, pesannya dihitung
    // ulang lewat _confirmPasswordLiveError di setiap build.
    _password.addListener(_onPasswordEdited);
    _passwordConfirmation.addListener(_onPasswordConfirmationEdited);
  }

  @override
  void dispose() {
    _password.removeListener(_onPasswordEdited);
    _passwordConfirmation.removeListener(_onPasswordConfirmationEdited);
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _dateOfBirthText.dispose();
    _password.dispose();
    _passwordConfirmation.dispose();
    super.dispose();
  }

  void _onPasswordEdited() {
    if (_errors.containsKey('password')) {
      setState(() => _errors.remove('password'));
    } else {
      setState(() {});
    }
  }

  void _onPasswordConfirmationEdited() {
    if (_errors.containsKey('password_confirmation')) {
      setState(() => _errors.remove('password_confirmation'));
    } else {
      setState(() {});
    }
  }

  /// Pesan real-time di bawah kotak konfirmasi kata sandi begitu isinya
  /// berbeda dari kata sandi — tidak menunggu submit dulu.
  String? get _confirmPasswordLiveError {
    if (_passwordConfirmation.text.isEmpty) return null;
    if (_passwordConfirmation.text == _password.text) return null;
    return _kPasswordMismatchError;
  }

  Future<void> _pickDateOfBirth() async {
    FocusScope.of(context).unfocus();

    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 17, now.month, now.day),
      firstDate: DateTime(now.year - 120),
      lastDate: now,
      helpText: 'Pilih tanggal lahir',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      _dateOfBirth = picked;
      _dateOfBirthText.text = _dateOfBirthFormat.format(picked);
      _errors.remove('date_of_birth');
    });
  }

  Map<String, String> _validate() {
    final errors = <String, String>{};

    if (_name.text.trim().isEmpty) {
      errors['name'] = 'Nama lengkap wajib diisi.';
    }

    final email = _email.text.trim();
    if (email.isEmpty) {
      errors['email'] = 'Email wajib diisi.';
    } else if (!_emailPattern.hasMatch(email)) {
      errors['email'] = 'Format email belum benar.';
    }

    if (_phone.text.trim().isEmpty) {
      errors['phone'] = 'Nomor HP wajib diisi.';
    }

    if (_dateOfBirth == null) {
      errors['date_of_birth'] = 'Tanggal lahir wajib diisi.';
    } else if (_dateOfBirth!.isAfter(DateTime.now())) {
      errors['date_of_birth'] =
          'Tanggal lahir tidak boleh lebih dari hari ini.';
    }

    if (_password.text.isEmpty) {
      errors['password'] = 'Kata sandi wajib diisi.';
    } else if (_password.text.length < 8) {
      errors['password'] = 'Kata sandi minimal 8 karakter.';
    }

    if (_passwordConfirmation.text != _password.text) {
      errors['password_confirmation'] = _kPasswordMismatchError;
    }

    return errors;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final errors = _validate();
    setState(() => _errors = errors);
    if (errors.isNotEmpty) return;

    final email = _email.text.trim();

    setState(() => _submitting = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .register(
            name: _name.text.trim(),
            email: email,
            password: _password.text,
            phone: _phone.text.trim(),
            dateOfBirth: _dateOfBirth,
          );
      if (!mounted) return;

      // Register tidak membuat sesi (lihat AuthController.register) — dorong
      // pengguna ke layar OTP secara eksplisit, bukan menunggu
      // authControllerProvider berubah seperti alur lama.
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => OtpVerificationScreen(email: email),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      final presentation = presentAuthError(
        error,
        knownFields: const {
          'name',
          'email',
          'phone',
          'date_of_birth',
          'password',
        },
      );
      setState(() => _errors = presentation.fieldErrors);

      final message = presentation.message;
      if (message != null) {
        showAppAlert(
          context,
          type: AppAlertType.error,
          title: 'Pendaftaran Gagal',
          message: message,
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _submitting;

    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _name,
            hintText: 'Nama Lengkap',
            icon: Icons.person_outline,
            textInputAction: TextInputAction.next,
            enabled: !isLoading,
            errorText: _errors['name'],
            autofillHints: const [AutofillHints.name],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            controller: _email,
            hintText: 'Email',
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            enabled: !isLoading,
            errorText: _errors['email'],
            autofillHints: const [AutofillHints.email],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            controller: _phone,
            hintText: 'Nomor HP',
            icon: Icons.phone_iphone_outlined,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            enabled: !isLoading,
            errorText: _errors['phone'],
            autofillHints: const [AutofillHints.telephoneNumber],
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
              LengthLimitingTextInputFormatter(20),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            controller: _dateOfBirthText,
            hintText: 'Tanggal Lahir',
            icon: Icons.calendar_month_outlined,
            enabled: !isLoading,
            readOnly: true,
            onTap: isLoading ? null : _pickDateOfBirth,
            errorText: _errors['date_of_birth'],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            controller: _password,
            hintText: 'Kata sandi',
            icon: Icons.lock_outline,
            obscure: true,
            textInputAction: TextInputAction.next,
            enabled: !isLoading,
            errorText: _errors['password'],
            helperText: 'Kata sandi minimal 8 karakter.',
            autofillHints: const [AutofillHints.newPassword],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            controller: _passwordConfirmation,
            hintText: 'Konfirmasi Kata sandi',
            icon: Icons.lock_outline,
            obscure: true,
            textInputAction: TextInputAction.done,
            enabled: !isLoading,
            errorText:
                _errors['password_confirmation'] ?? _confirmPasswordLiveError,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Daftar',
            trailingIcon: null,
            isLoading: isLoading,
            onPressed: _submit,
          ),
          const SizedBox(height: AppSpacing.lg),
          const LabeledDivider(label: 'atau daftar dengan'),
          const SizedBox(height: AppSpacing.md),
          GoogleButton(
            onPressed: (isLoading || widget.isGoogleLoading)
                ? null
                : widget.onGooglePressed,
            isLoading: widget.isGoogleLoading,
          ),
          const SizedBox(height: AppSpacing.xs),
          AuthFooterLink(
            question: 'Sudah punya akun?',
            action: 'Masuk di sini',
            onTap: widget.onSwitchToLogin,
          ),
        ],
      ),
    );
  }
}
