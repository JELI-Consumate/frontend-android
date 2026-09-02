import 'package:flutter/material.dart' hide Badge;
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/badge.dart';
import 'badge_avatar.dart';
import 'badge_detail_sheet.dart';

class BadgeTile extends StatelessWidget {
  const BadgeTile({super.key, required this.badge});

  final Badge badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => showBadgeDetailSheet(context, badge),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BadgeAvatar(badge: badge),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      badge.name,
                      style: AppTypography.titleMedium.copyWith(
                        color: badge.earned
                            ? AppColors.ink
                            : AppColors.inkMuted,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      badge.description,
                      style: AppTypography.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (badge.earned)
                      _EarnedLabel(earnedAt: badge.earnedAt)
                    else
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
                              'Selesaikan journey terkait untuk meraih ini',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.inkMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
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

class _EarnedLabel extends StatelessWidget {
  const _EarnedLabel({required this.earnedAt});

  final DateTime? earnedAt;

  @override
  Widget build(BuildContext context) {
    final label = earnedAt == null
        ? 'Sudah diraih'
        : 'Diraih ${DateFormat('d MMMM y', 'id_ID').format(earnedAt!)}';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, size: 14, color: AppColors.success),
        const SizedBox(width: AppSpacing.xxs),
        Flexible(
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
