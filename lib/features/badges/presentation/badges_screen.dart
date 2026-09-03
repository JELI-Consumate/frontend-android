import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../learning/application/learning_providers.dart';
import '../application/badge_providers.dart';
import '../data/models/badge.dart';
import 'widgets/badge_tile.dart';

/// Lencana milik sektor aktif saja, diurutkan mengikuti urutan journey-nya.
///
/// Komposisi dua fitur (`badges` + `learning`) hidup di layer presentation
/// supaya `badges/application` tetap jadi leaf tanpa tahu soal `learning`.
final _sectorBadgesProvider = FutureProvider.autoDispose<List<Badge>>((
  ref,
) async {
  final badges = await ref.watch(badgesProvider.future);
  final sectorDetail = await ref.watch(primarySectorDetailProvider.future);
  final journeys = sectorDetail?.journeys ?? const [];

  final orderByJourneyId = {
    for (final journey in journeys) journey.id: journey.order,
  };

  return badges
      .where((badge) => orderByJourneyId.containsKey(badge.journeyId))
      .toList()
    ..sort(
      (a, b) => orderByJourneyId[a.journeyId]!.compareTo(
        orderByJourneyId[b.journeyId]!,
      ),
    );
});

class BadgesScreen extends ConsumerWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgesAsync = ref.watch(_sectorBadgesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pencapaian')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(badgesProvider);
            return ref.refresh(_sectorBadgesProvider.future);
          },
          child: switch (badgesAsync) {
            AsyncData(:final value) when value.isNotEmpty => ListView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              children: [
                _SummaryCard(badges: value),
                const SizedBox(height: AppSpacing.lg),
                for (final badge in value) ...[
                  BadgeTile(badge: badge),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
            AsyncError() => ListView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              children: const [_ErrorMessage()],
            ),
            AsyncData() => ListView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              children: const [_EmptyMessage()],
            ),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.badges});

  final List<Badge> badges;

  @override
  Widget build(BuildContext context) {
    final earnedCount = badges.where((badge) => badge.earned).length;
    final percent = badges.isEmpty
        ? 0
        : (earnedCount / badges.length * 100).round();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium, color: AppColors.white, size: 36),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$earnedCount/${badges.length} Lencana diraih',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: percent / 100,
                    minHeight: 6,
                    backgroundColor: AppColors.white.withValues(alpha: 0.24),
                    valueColor: const AlwaysStoppedAnimation(AppColors.white),
                  ),
                ),
              ],
            ),
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
            'Gagal memuat lencana. Tarik ke bawah untuk coba lagi.',
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxl),
      child: Text(
        'Belum ada lencana tersedia di sektor ini.',
        style: AppTypography.bodySmall,
        textAlign: TextAlign.center,
      ),
    );
  }
}
