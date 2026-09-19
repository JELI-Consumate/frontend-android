import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';

class DeleteAccountDialog extends StatefulWidget {
  final String userEmail;

  const DeleteAccountDialog({
    super.key,
    required this.userEmail,
  });

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _emailController = TextEditingController();
  bool _canSubmit = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _validateEmail() {
    final canSubmit = _emailController.text == widget.userEmail;
    if (_canSubmit != canSubmit) {
      setState(() {
        _canSubmit = canSubmit;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.background,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.delete_forever, color: AppColors.danger, size: 28),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Hapus Akun',
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            RichText(
              text: TextSpan(
                style: AppTypography.bodyMedium.copyWith(color: AppColors.muted),
                children: [
                  const TextSpan(text: 'Tindakan ini '),
                  TextSpan(
                    text: 'permanen dan tidak dapat dibatalkan',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                  const TextSpan(text: '. Semua progres belajar, sertifikat, dan data akunmu akan dihapus selamanya.\n\n'),
                  const TextSpan(text: 'Untuk melanjutkan, silakan ketik emailmu di bawah ini:\n'),
                  TextSpan(
                    text: widget.userEmail,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _emailController,
              hintText: 'Ketik emailmu...',
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Ya, Hapus Akun Saya',
              onPressed: _canSubmit
                  ? () {
                      Navigator.of(context).pop(true);
                    }
                  : null,
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text(
                'Batal',
                style: AppTypography.labelLarge.copyWith(color: AppColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
