import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/learning_module.dart';

class ModuleRow extends StatelessWidget {
  const ModuleRow({
    super.key,
    required this.module,
    required this.isCurrent,
    required this.onTap,
  });

  final LearningModule module;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isCompleted = module.progress.status.isCompleted;
    final isLocked = module.locked;

    final titleStyle = AppTypography.bodyLarge.copyWith(
      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
    );
    final subtitleStyle = AppTypography.bodySmall;

    final rowHeight =
        (titleStyle.fontSize ?? 15) * (titleStyle.height ?? 1) * 2 +
        2 +
        (subtitleStyle.fontSize ?? 13) * (subtitleStyle.height ?? 1);

    final content = SizedBox(
      height: rowHeight,
      child: Row(
        children: [
          _StatusIcon(
            type: module.type,
            isCompleted: isCompleted,
            isCurrent: isCurrent,
            isLocked: isLocked,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${module.order}. ${module.title}',
                  style: titleStyle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                if (isLocked)
                  Row(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 13,
                        color: AppColors.inkMuted,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          'Selesaikan modul sebelumnya',
                          style: subtitleStyle.copyWith(
                            color: AppColors.inkMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                else
                  _Subtitle(
                    type: module.type,
                    isCompleted: isCompleted,
                    module: module,
                  ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.muted),
        ],
      ),
    );

    return Opacity(
      opacity: isLocked ? 0.5 : 1,
      child: Material(
        color: AppColors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(
            color: isCurrent ? AppColors.primary : AppColors.border,
            width: isCurrent ? 1.4 : 1,
          ),
        ),
        child: InkWell(
          onTap: isLocked ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: content,
          ),
        ),
      ),
    );
  }
}

class _Subtitle extends StatelessWidget {
  const _Subtitle({
    required this.type,
    required this.isCompleted,
    required this.module,
  });

  final ModuleContentType type;
  final bool isCompleted;
  final LearningModule module;

  @override
  Widget build(BuildContext context) {
    final labelStyle = AppTypography.bodySmall.copyWith(
      color: AppColors.inkMuted,
    );

    return Row(
      children: [
        Icon(_labelIconFor(type), size: 13, color: AppColors.inkMuted),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            type.shortLabel,
            style: labelStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.xxs),
        Text('•', style: labelStyle),
        const SizedBox(width: AppSpacing.xxs),
        if (isCompleted) ...[
          Icon(Icons.check_circle_outline, size: 13, color: AppColors.success),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              'Selesai',
              style: labelStyle.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ] else
          Flexible(
            child: Text(
              '${module.estimatedMinutes} menit',
              style: labelStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({
    required this.type,
    required this.isCompleted,
    required this.isCurrent,
    required this.isLocked,
  });

  final ModuleContentType type;
  final bool isCompleted;
  final bool isCurrent;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    if (isLocked) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.background,
        child: Icon(Icons.lock_outline, color: AppColors.inkMuted, size: 18),
      );
    }

    if (isCurrent) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.primary,
        child: Icon(_avatarIconFor(type), color: AppColors.white, size: 20),
      );
    }

    if (isCompleted) {
      return const CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.success,
        child: Icon(Icons.check, color: AppColors.white, size: 20),
      );
    }

    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.primarySoft,
      child: Icon(_avatarIconFor(type), color: AppColors.primary, size: 18),
    );
  }
}

IconData _avatarIconFor(ModuleContentType type) => switch (type) {
  ModuleContentType.opening => Icons.trip_origin,
  ModuleContentType.video => Icons.play_circle_outline,
  ModuleContentType.materi => Icons.description_outlined,
  ModuleContentType.infografis => Icons.bar_chart_outlined,
  ModuleContentType.komik => Icons.auto_stories_outlined,
  ModuleContentType.kuis => Icons.help_outline,
  ModuleContentType.simulasi => Icons.sports_esports_outlined,
  ModuleContentType.refleksi => Icons.edit_outlined,
  ModuleContentType.unknown => Icons.circle_outlined,
};

IconData _labelIconFor(ModuleContentType type) =>
    type == ModuleContentType.opening
    ? Icons.info_outline
    : _avatarIconFor(type);
