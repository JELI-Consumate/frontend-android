import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../learning/data/models/learning_module.dart';
import '../../data/models/module_detail.dart';

/// Header dipakai seragam di kelima layar konsumsi konten -- chip tipe
/// module + estimasi durasi, judul, dan deskripsi opsional.
class ModuleHeader extends StatelessWidget {
  const ModuleHeader({super.key, required this.module});

  final ModuleDetail module;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _TypeChip(type: module.type),
            const Spacer(),
            Icon(Icons.schedule_outlined, size: 14, color: AppColors.inkMuted),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              '${module.estimatedMinutes} menit',
              style: AppTypography.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(module.title, style: AppTypography.displaySmall),
        if (module.description case final description?) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(description, style: AppTypography.bodyMedium),
        ],
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});

  final ModuleContentType type;

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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconFor(type), size: 13, color: AppColors.primary),
          const SizedBox(width: 3),
          Text(
            type.shortLabel,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(ModuleContentType type) => switch (type) {
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
}
