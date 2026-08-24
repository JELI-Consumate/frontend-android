import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_alert_dialog.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/google_button.dart';
import '../../../../core/widgets/labeled_divider.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../application/auth_controller.dart';
import '../otp_verification_screen.dart';
import 'auth_error_mapper.dart';
import 'auth_footer_link.dart';

class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({
    super.key,
    required this.onSwitchToRegister,
    required this.onGooglePressed,
    required this.onForgotPassword,
  });

  final VoidCallback onSwitchToRegister;
  final VoidCallback onGooglePressed;
  final VoidCallback onForgotPassword;

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  Map<String, String> _errors = {};
  bool _submitting = false;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
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

    if (_password.text.isEmpty) {
      errors['password'] = 'Kata sandi wajib diisi.';
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
          .login(email: email, password: _password.text);
    } catch (error) {
      if (!mounted) return;

      if (error is ApiException && error.isEmailNotVerified) {
        // Kredensial-nya benar, cuma belum verifikasi -- langsung dorong ke
        // layar OTP (kode lama dari saat daftar, kalau masih berlaku, masih
        // bisa dipakai di sana; kalau tidak, ada tombol kirim ulang).
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => OtpVerificationScreen(email: email),
          ),
        );
        return;
      }

      final presentation = presentAuthError(
        error,
        knownFields: const {'email', 'password'},
      );
      setState(() => _errors = presentation.fieldErrors);

      final message = presentation.message;
      if (message != null) {
        showAppAlert(
          context,
          type: AppAlertType.error,
          title: 'Gagal Masuk',
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
            controller: _password,
            hintText: 'Kata sandi',
            icon: Icons.lock_outline,
            obscure: true,
            textInputAction: TextInputAction.done,
            enabled: !isLoading,
            errorText: _errors['password'],
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => _submit(),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: isLoading ? null : widget.onForgotPassword,
              child: Text(
                'Lupa kata sandi?',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          PrimaryButton(
            label: 'Masuk',
            trailingIcon: null,
            isLoading: isLoading,
            onPressed: _submit,
          ),
          const SizedBox(height: AppSpacing.lg),
          const LabeledDivider(label: 'atau masuk dengan'),
          const SizedBox(height: AppSpacing.md),
          GoogleButton(onPressed: isLoading ? null : widget.onGooglePressed),
          const SizedBox(height: AppSpacing.xs),
          AuthFooterLink(
            question: 'Belum punya akun?',
            action: 'Daftar di sini',
            onTap: widget.onSwitchToRegister,
          ),
        ],
      ),
    );
  }
}
