import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_alert_dialog.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../application/auth_controller.dart';
import 'widgets/auth_error_mapper.dart';

const _kOtpLength = 6;

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  late final _email = TextEditingController(text: widget.initialEmail ?? '');
  final _otp = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirmation = TextEditingController();

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  Map<String, String> _errors = {};
  bool _submitting = false;

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    _password.dispose();
    _passwordConfirmation.dispose();
    super.dispose();
  }

  Map<String, String> _validate() {
    final errors = <String, String>{};

    final email = _email.text.trim();
    if (email.isEmpty) {
      errors['email'] = 'Email wajib diisi.';
    } else if (!_emailPattern.hasMatch(email)) {
      errors['email'] = 'Format email belum benar.';
    }

    if (_otp.text.trim().isEmpty) {
      errors['otp'] = 'Kode reset wajib diisi.';
    } else if (_otp.text.trim().length != _kOtpLength) {
      errors['otp'] = 'Kode reset harus $_kOtpLength digit.';
    }

    if (_password.text.isEmpty) {
      errors['password'] = 'Kata sandi baru wajib diisi.';
    } else if (_password.text.length < 8) {
      errors['password'] = 'Kata sandi minimal 8 karakter.';
    }

    if (_passwordConfirmation.text != _password.text) {
      errors['password_confirmation'] = 'Konfirmasi kata sandi belum cocok.';
    }

    return errors;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final errors = _validate();
    setState(() => _errors = errors);
    if (errors.isNotEmpty) return;

    setState(() => _submitting = true);
    try {
      final message = await ref
          .read(authControllerProvider.notifier)
          .resetPassword(
            email: _email.text.trim(),
            otp: _otp.text.trim(),
            password: _password.text,
            passwordConfirmation: _passwordConfirmation.text,
          );
      if (!mounted) return;

      Navigator.of(context).popUntil((route) => route.isFirst);
      showAppAlert(
        context,
        type: AppAlertType.success,
        title: 'Berhasil',
        message: message,
      );
    } catch (error) {
      if (!mounted) return;

      final presentation = presentAuthError(
        error,
        knownFields: const {
          'email',
          'otp',
          'password',
          'password_confirmation',
        },
      );
      setState(() => _errors = presentation.fieldErrors);

      final message = presentation.message;
      if (message != null) {
        showAppAlert(
          context,
          type: AppAlertType.error,
          title: 'Gagal Reset Kata Sandi',
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

    return Scaffold(
      appBar: AppBar(title: const Text('Reset Kata Sandi')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Salin kode reset dari email kamu, lalu buat kata sandi baru.',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: AppSpacing.lg),
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
                  controller: _otp,
                  hintText: 'Kode Reset',
                  icon: Icons.vpn_key_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(_kOtpLength),
                  ],
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                  errorText: _errors['otp'],
                ),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  controller: _password,
                  hintText: 'Kata Sandi Baru',
                  icon: Icons.lock_outline,
                  obscure: true,
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                  errorText: _errors['password'],
                  autofillHints: const [AutofillHints.newPassword],
                ),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  controller: _passwordConfirmation,
                  hintText: 'Konfirmasi Kata Sandi Baru',
                  icon: Icons.lock_outline,
                  obscure: true,
                  textInputAction: TextInputAction.done,
                  enabled: !isLoading,
                  errorText: _errors['password_confirmation'],
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: 'Reset Kata Sandi',
                  trailingIcon: null,
                  isLoading: isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
