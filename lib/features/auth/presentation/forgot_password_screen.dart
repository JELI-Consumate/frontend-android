import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_alert_dialog.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../application/auth_controller.dart';
import 'reset_password_screen.dart';
import 'widgets/auth_error_mapper.dart';

/// Layar "Lupa Kata Sandi": minta email, lalu backend mengirim kode reset
/// lewat email. Selalu menampilkan pesan sukses yang sama baik email itu
/// terdaftar atau tidak — itu keputusan sengaja dari backend supaya
/// endpoint ini tidak bisa dipakai menebak email mana yang punya akun.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  String? _emailError;
  bool _submitting = false;
  String? _confirmationMessage;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _emailError = 'Email wajib diisi.');
      return;
    }
    if (!_emailPattern.hasMatch(email)) {
      setState(() => _emailError = 'Format email belum benar.');
      return;
    }
    setState(() => _emailError = null);

    setState(() => _submitting = true);
    try {
      final message = await ref
          .read(authControllerProvider.notifier)
          .forgotPassword(email);
      if (!mounted) return;
      setState(() => _confirmationMessage = message);
    } catch (error) {
      if (!mounted) return;

      final presentation = presentAuthError(
        error,
        knownFields: const {'email'},
      );
      setState(() => _emailError = presentation.fieldErrors['email']);

      final message = presentation.message;
      if (message != null) {
        showAppAlert(
          context,
          type: AppAlertType.error,
          title: 'Gagal Mengirim',
          message: message,
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final confirmation = _confirmationMessage;

    return Scaffold(
      appBar: AppBar(title: const Text('Lupa Kata Sandi')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: confirmation == null
              ? _buildForm()
              : _buildConfirmation(confirmation),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Masukkan email akunmu', style: AppTypography.titleLarge),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Kami akan mengirim kode untuk mengatur ulang kata sandi ke '
          'email tersebut.',
          style: AppTypography.bodySmall,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          controller: _email,
          hintText: 'Email',
          icon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          enabled: !_submitting,
          errorText: _emailError,
          autofillHints: const [AutofillHints.email],
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: 'Kirim Kode Reset',
          trailingIcon: null,
          isLoading: _submitting,
          onPressed: _submit,
        ),
      ],
    );
  }

  Widget _buildConfirmation(String message) {
    final email = _email.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xl),
        const Icon(
          Icons.mark_email_read_outlined,
          size: 56,
          color: AppColors.primary,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Cek email kamu',
          style: AppTypography.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          message,
          style: AppTypography.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: 'Sudah Punya Kode?',
          trailingIcon: null,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ResetPasswordScreen(initialEmail: email),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Kembali ke Masuk'),
        ),
      ],
    );
  }
}
