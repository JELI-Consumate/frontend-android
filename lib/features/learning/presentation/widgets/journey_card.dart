import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/journey.dart';

/// Kartu journey dipakai di dua tempat: preview di dashboard dan daftar
/// penuh di tab Perjalanan. Journey terkunci ditampilkan pudar dengan
/// gembok — sesuai BR-01 di backend (journey terbuka berurutan).
class JourneyCard extends StatelessWidget {
  const JourneyCard({
    super.key,
    required this.journey,
    required this.label,
    required this.onTap,
  });

  final Journey journey;

  /// Mis. "Journey 1" — dihitung pemanggil dari posisi dalam daftar, bukan
  /// dari field backend (backend cuma punya `order`, bukan label siap pakai).
  final String label;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isLocked = !journey.isUnlocked;

    return Material(
      color: isLocked
          ? AppColors.muted.withValues(alpha: 0.5)
          : AppColors.primary,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: isLocked ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumbnail(locked: isLocked),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      journey.title,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${journey.modulesCount} Materi',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (isLocked)
                      Row(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 16,
                            color: AppColors.white.withValues(alpha: 0.75),
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                          Expanded(
                            child: Text(
                              'Selesaikan journey sebelumnya',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.white.withValues(alpha: 0.75),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    else
                      _ProgressBar(percent: journey.progress.percent),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.locked});

  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: locked
          ? Icon(
              Icons.lock_outline,
              color: AppColors.white.withValues(alpha: 0.85),
            )
          : SvgPicture.asset('assets/images/journey_illustration.svg'),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 6,
              backgroundColor: AppColors.white.withValues(alpha: 0.22),
              valueColor: const AlwaysStoppedAnimation(AppColors.white),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '$percent%',
          style: AppTypography.bodySmall.copyWith(color: AppColors.white),
        ),
      ],
    );
  }
}
