import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../learning/data/models/journey_detail.dart';

/// Kartu "Lanjutkan Belajar" di dashboard. Judulnya diambil dari module
/// yang sedang dikerjakan (bukan judul journey) — itu yang secara konkret
/// mau dilanjutkan pengguna, sesuai desain.
class ContinueLearningCard extends StatelessWidget {
  const ContinueLearningCard({
    super.key,
    required this.journeyDetail,
    required this.onTap,
  });

  final JourneyDetail journeyDetail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final currentModule = journeyDetail.currentModule;
    if (currentModule == null) return const SizedBox.shrink();

    final percent = journeyDetail.journey.progress.percent;

    return Material(
      color: AppColors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Belum ada foto/banner per module dari backend (cuma teks +
            // durasi), jadi ilustrasi journey yang sama dipakai lagi di
            // sini diperbesar mengisi lebar kartu -- konsisten dengan
            // ilustrasi di kartu journey di bawahnya.
            Container(
              height: 130,
              width: double.infinity,
              alignment: Alignment.center,
              color: AppColors.primarySoft,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SvgPicture.asset(
                'assets/images/journey_illustration.svg',
                height: 104,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentModule.title,
                    style: AppTypography.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        size: 14,
                        color: AppColors.inkMuted,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(
                        '${currentModule.estimatedMinutes} menit tersisa',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: LinearProgressIndicator(
                            value: percent / 100,
                            minHeight: 6,
                            backgroundColor: AppColors.border,
                            valueColor: const AlwaysStoppedAnimation(
                              AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text('$percent%', style: AppTypography.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
