import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../learning/data/models/journey_detail.dart';

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
    final imageUrl = journeyDetail.journey.imageUrl;

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
            SizedBox(
              height: 130,
              width: double.infinity,
              child: ColoredBox(
                color: AppColors.primarySoft,
                child: _CoverImage(imageUrl: imageUrl),
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

class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) return const _CoverFallback();
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : const _CoverFallback(),
      errorBuilder: (_, _, _) => const _CoverFallback(),
    );
  }
}

class _CoverFallback extends StatelessWidget {
  const _CoverFallback();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: SvgPicture.asset(
          'assets/images/journey_illustration.svg',
          height: 104,
        ),
      ),
    );
  }
}
