import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'primary_button.dart';

enum AppAlertType { success, error, warning, info }

class _AlertVisual {
  const _AlertVisual(this.icon, this.color, this.softColor);

  final IconData icon;
  final Color color;
  final Color softColor;
}

_AlertVisual _visualFor(AppAlertType type) => switch (type) {
  AppAlertType.success => _AlertVisual(
    Icons.check_rounded,
    AppColors.success,
    AppColors.successSoft,
  ),
  AppAlertType.error => _AlertVisual(
    Icons.priority_high_rounded,
    AppColors.danger,
    AppColors.dangerSoft,
  ),
  AppAlertType.warning => _AlertVisual(
    Icons.warning_amber_rounded,
    AppColors.warning,
    AppColors.warningSoft,
  ),
  AppAlertType.info => _AlertVisual(
    Icons.info_outline_rounded,
    AppColors.primary,
    AppColors.primarySoft,
  ),
};

Future<void> showAppAlert(
  BuildContext context, {
  required AppAlertType type,
  required String title,
  String? message,
  String confirmLabel = 'OK',
  VoidCallback? onConfirm,
  String? cancelLabel,
  VoidCallback? onCancel,
}) {
  final visual = _visualFor(type);

  return showDialog<void>(
    context: context,
    barrierDismissible: cancelLabel == null,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: visual.softColor,
                shape: BoxShape.circle,
              ),
              child: Icon(visual.icon, color: visual.color, size: 34),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: AppTypography.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                message,
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: confirmLabel,
              trailingIcon: null,
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onConfirm?.call();
              },
            ),
            if (cancelLabel != null) ...[
              const SizedBox(height: AppSpacing.xxs),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  onCancel?.call();
                },
                child: Text(cancelLabel),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
