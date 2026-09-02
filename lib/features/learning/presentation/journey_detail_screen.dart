import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../badges/application/badge_providers.dart';
import '../../badges/data/models/badge.dart';
import '../../module/presentation/module_screen.dart';
import '../application/learning_providers.dart';
import '../data/models/journey_detail.dart';
import 'journey_celebration_screen.dart';
import 'widgets/module_row.dart';

class JourneyDetailScreen extends ConsumerWidget {
  const JourneyDetailScreen({super.key, required this.journeyId});

  final String journeyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(journeyDetailProvider(journeyId));

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(journeyDetailProvider(journeyId).future),
          child: switch (detailAsync) {
            AsyncData(:final value) => _JourneyDetailBody(
              journeyId: journeyId,
              detail: value,
            ),
            AsyncError() => ListView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              children: const [_ErrorMessage()],
            ),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ),
    );
  }
}

class _JourneyDetailBody extends ConsumerWidget {
  const _JourneyDetailBody({required this.journeyId, required this.detail});

  final String journeyId;
  final JourneyDetail detail;

  Future<void> _openModule(
    BuildContext context,
    WidgetRef ref,
    String moduleId,
  ) async {
    final wasCompleted = detail.journey.progress.status.isCompleted;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ModuleScreen(
          moduleId: moduleId,
          journeyModuleIds: detail.modules.map((module) => module.id).toList(),
        ),
      ),
    );

    ref.invalidate(journeyDetailProvider(journeyId));
    ref.invalidate(primarySectorDetailProvider);

    if (wasCompleted || !context.mounted) return;

    final refreshed = await ref.read(journeyDetailProvider(journeyId).future);
    if (!refreshed.journey.progress.status.isCompleted) return;
    if (!context.mounted) return;

    await _showCelebration(context, ref, refreshed);
  }

  Future<void> _showCelebration(
    BuildContext context,
    WidgetRef ref,
    JourneyDetail refreshed,
  ) async {
    ref.invalidate(badgesProvider);
    final badges = await ref.read(badgesProvider.future);
    if (!context.mounted) return;

    Badge? earnedBadge;
    for (final candidate in badges) {
      if (candidate.journeyId == journeyId) {
        earnedBadge = candidate;
        break;
      }
    }

    final sectorDetail = await ref.read(primarySectorDetailProvider.future);
    if (!context.mounted) return;

    String? nextJourneyId;
    for (final journey in sectorDetail?.journeys ?? const []) {
      if (journey.order == refreshed.journey.order + 1) {
        nextJourneyId = journey.id;
        break;
      }
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => JourneyCelebrationScreen(
          journeyOrder: refreshed.journey.order,
          badge: earnedBadge ?? _fallbackBadge(refreshed),
          modulesCompleted: refreshed.completedModuleCount,
          modulesTotal: refreshed.modules.length,
          quizScore: refreshed.quizScore,
          nextJourneyId: nextJourneyId,
        ),
      ),
    );
  }

  Badge _fallbackBadge(JourneyDetail refreshed) {
    return Badge(
      id: '',
      journeyId: journeyId,
      name: '${refreshed.journey.title} Selesai',
      description: 'Kamu telah menuntaskan seluruh materi journey ini.',
      congratulationMessage:
          'Selamat! Kamu telah menuntaskan seluruh materi journey ini.',
      motivationalMessage: null,
      iconUrl: null,
      earned: true,
      earnedAt: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journey = detail.journey;
    final currentModule = detail.currentModule;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        0,
        AppSpacing.screenPadding,
        AppSpacing.xl,
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: _JourneyBadge(order: journey.order),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(journey.title, style: AppTypography.displaySmall),
        if (journey.description case final description?) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(description, style: AppTypography.bodySmall),
        ],
        const SizedBox(height: AppSpacing.lg),
        _ProgressCard(
          completed: detail.completedModuleCount,
          total: detail.modules.length,
          percent: journey.progress.percent,
        ),
        const SizedBox(height: AppSpacing.lg),
        ...detail.modules.map(
          (module) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ModuleRow(
              module: module,
              isCurrent: currentModule?.id == module.id,
              onTap: () => _openModule(context, ref, module.id),
            ),
          ),
        ),
      ],
    );
  }
}

class _JourneyBadge extends StatelessWidget {
  const _JourneyBadge({required this.order});

  final int order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_stories_outlined,
            size: 14,
            color: AppColors.white,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            'Journey $order',
            style: AppTypography.labelMedium.copyWith(color: AppColors.white),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.completed,
    required this.total,
    required this.percent,
  });

  final int completed;
  final int total;
  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Progres Belajar',
                  style: AppTypography.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '$completed/$total',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Selesaikan semua langkah untuk membuka simulasi.',
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxl),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.muted, size: 40),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Gagal memuat journey ini. Tarik ke bawah untuk coba lagi.',
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
