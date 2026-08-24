import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/learning_module.dart';

/// Satu baris di checklist journey. Tiga tampilan berbeda: selesai (ikon
/// centang hijau), sedang dikerjakan (kartu biru menonjol — module pertama
/// yang belum selesai), dan belum dikerjakan (baris polos).
///
/// Catatan: backend tidak mengunci module satu-satu di dalam journey
/// (cuma journey yang dikunci berurutan — lihat JourneyAccessService), jadi
/// semua baris di sini tetap bisa disentuh, tidak ada gembok per-module.
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

    final subtitle = isCompleted
        ? '${module.type.shortLabel} · Selesai'
        : '${module.type.shortLabel} · ${module.estimatedMinutes} menit';

    final content = Row(
      children: [
        _StatusIcon(
          type: module.type,
          isCompleted: isCompleted,
          isCurrent: isCurrent,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${module.order}. ${module.title}',
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: isCompleted ? AppColors.success : AppColors.inkMuted,
                  fontWeight: isCompleted ? FontWeight.w600 : null,
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.chevron_right, color: AppColors.muted),
      ],
    );

    if (!isCurrent) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: content,
        ),
      );
    }

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.primary, width: 1.4),
          ),
          child: content,
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({
    required this.type,
    required this.isCompleted,
    required this.isCurrent,
  });

  final ModuleContentType type;
  final bool isCompleted;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    if (isCompleted) {
      return const CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.success,
        child: Icon(Icons.check, color: AppColors.white, size: 20),
      );
    }

    if (isCurrent) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.primary,
        child: Icon(_iconFor(type), color: AppColors.white, size: 18),
      );
    }

    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.primarySoft,
      child: Icon(_iconFor(type), color: AppColors.primary, size: 18),
    );
  }

  IconData _iconFor(ModuleContentType type) => switch (type) {
    ModuleContentType.opening => Icons.flag_outlined,
    ModuleContentType.video => Icons.play_circle_outline,
    ModuleContentType.materi => Icons.menu_book_outlined,
    ModuleContentType.infografis => Icons.insights_outlined,
    ModuleContentType.komik => Icons.auto_stories_outlined,
    ModuleContentType.kuis => Icons.quiz_outlined,
    ModuleContentType.simulasi => Icons.sports_esports_outlined,
    ModuleContentType.refleksi => Icons.edit_note_outlined,
    ModuleContentType.unknown => Icons.circle_outlined,
  };
}
