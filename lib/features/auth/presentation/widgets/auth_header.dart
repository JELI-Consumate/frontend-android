import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.white,
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -20,
            child: _Blob(size: 130, opacity: 0.06),
          ),
          Positioned(top: 40, right: 60, child: _Blob(size: 70, opacity: 0.05)),
          Positioned(top: -10, left: 10, child: _Blob(size: 60, opacity: 0.04)),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.xxl,
              AppSpacing.screenPadding,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text.rich(
                  TextSpan(
                    style: AppTypography.displayLarge.copyWith(
                      color: AppColors.ink,
                      fontSize: 32,
                    ),
                    children: [
                      const TextSpan(text: 'Siap untuk\nmulai perjalanan\n'),
                      TextSpan(
                        text: 'belajarmu?',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ],
                  ),
                  semanticsLabel: 'Siap untuk mulai perjalanan belajarmu?',
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Masuk atau daftar untuk mengakses semua materi dan fitur '
                  'pembelajaran.',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: opacity),
      ),
    );
  }
}
