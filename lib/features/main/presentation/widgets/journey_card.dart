import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../learning/data/models/journey.dart';

/// Kartu journey dipakai di dua tempat: preview di dashboard dan daftar
/// penuh di tab Perjalanan. Journey terkunci ditampilkan pudar dengan
/// gembok — sesuai BR-01 di backend (journey terbuka berurutan).
class JourneyCard extends StatelessWidget {
  const JourneyCard({
    super.key,
    required this.journey,
    required this.label,
    required this.onTap,
    this.forceLocked = false,
    this.lockReason,
  });

  final Journey journey;

  /// Mis. "Journey 1" — dihitung pemanggil dari posisi dalam daftar, bukan
  /// dari field backend (backend cuma punya `order`, bukan label siap pakai).
  final String label;

  final VoidCallback onTap;

  /// Kunci kartu ini walau backend bilang `is_unlocked` — dipakai gerbang
  /// pre-test di aplikasi (journey 1 terkunci sampai survei pre-test diisi,
  /// lihat `SectorDetail.pretestGateActive`).
  final bool forceLocked;

  /// Teks kecil di bawah judul saat terkunci. Default:
  /// "Selesaikan journey sebelumnya".
  final String? lockReason;

  @override
  Widget build(BuildContext context) {
    final isLocked = forceLocked || !journey.isUnlocked;

    return Material(
      color: AppColors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: isLocked ? null : onTap,
        child: Opacity(
          opacity: isLocked ? 0.5 : 1,
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
                      _JourneyBadge(label: label),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        journey.title,
                        style: AppTypography.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      if (isLocked)
                        Row(
                          children: [
                            Icon(
                              Icons.lock_outline,
                              size: 14,
                              color: AppColors.inkMuted,
                            ),
                            const SizedBox(width: AppSpacing.xxs),
                            Expanded(
                              child: Text(
                                lockReason ?? 'Selesaikan journey sebelumnya',
                                style: AppTypography.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        )
                      else ...[
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_outlined,
                              size: 14,
                              color: AppColors.inkMuted,
                            ),
                            const SizedBox(width: AppSpacing.xxs),
                            Text(
                              '${journey.modulesCount} Materi',
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _ProgressBar(percent: journey.progress.percent),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Chip label "Journey N" di atas judul -- latar biru muda, teks biru,
/// gantinya teks abu-abu polos di desain lama.
class _JourneyBadge extends StatelessWidget {
  const _JourneyBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: AppTypography.labelMedium.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
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
      width: 76,
      height: 92,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: locked
          ? Icon(Icons.lock_outline, color: AppColors.inkMuted)
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
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text('$percent%', style: AppTypography.bodySmall),
      ],
    );
  }
}
