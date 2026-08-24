import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/learning_module.dart';

/// Satu baris di checklist journey -- selalu kartu putih bertepi, dengan dua
/// varian border: module yang sedang dikerjakan (tepi biru menonjol) dan
/// sisanya (tepi abu-abu tipis biasa).
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
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
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
    );

    return Material(
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
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: content,
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
  });

  final ModuleContentType type;
  final bool isCompleted;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    // Module yang sedang dikerjakan tetap ditandai kartu biru menonjol
    // meski kebetulan sudah selesai (mis. "Opening Journey" di awal) --
    // status "Selesai"-nya tetap kelihatan lewat subtitle, bukan lewat
    // ikon lingkaran ini.
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

/// Ikon lingkaran besar di kiri baris. "Opening" pakai lambang titik-awal
/// (bukan ikon info) supaya terasa beda dari module isi lainnya.
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

/// Ikon kecil di depan label tipe ("Video", "Materi", dst). Sama dengan
/// ikon lingkaran untuk semua tipe, kecuali "Opening" -- di situ dipakai
/// ikon info supaya bedanya dengan lambang titik-awal di lingkaran.
IconData _labelIconFor(ModuleContentType type) =>
    type == ModuleContentType.opening
    ? Icons.info_outline
    : _avatarIconFor(type);
