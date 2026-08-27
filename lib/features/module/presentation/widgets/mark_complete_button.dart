import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';

/// Tombol "Tandai Selesai" -- dipakai modul pasif (video/artikel) yang tidak
/// punya mekanisme selesai otomatis di server, beda dari kuis/simulasi/
/// refleksi yang selesai otomatis lewat submit/jawabannya masing-masing
/// (lihat `ModuleRepository.completeModulePage`).
class MarkCompleteButton extends StatelessWidget {
  const MarkCompleteButton({
    super.key,
    required this.completed,
    required this.busy,
    required this.onPressed,
  });

  final bool completed;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (completed) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.successSoft,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 20),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Sudah selesai',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return PrimaryButton(
      label: 'Tandai Selesai',
      trailingIcon: Icons.check,
      isLoading: busy,
      onPressed: onPressed,
    );
  }
}
