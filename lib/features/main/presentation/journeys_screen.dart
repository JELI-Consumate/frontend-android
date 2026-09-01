import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../learning/application/learning_providers.dart';
import '../../learning/data/learning_repository.dart';
import '../../learning/data/models/sector_detail.dart';
import '../../learning/presentation/journey_detail_screen.dart';
import '../../learning/presentation/widgets/sector_survey_card.dart';
import 'widgets/journey_card.dart';

/// Tab "Perjalanan": seluruh journey di sektor, berurutan sesuai BR-01 —
/// journey pertama selalu terbuka, sisanya terbuka satu-satu setelah
/// journey sebelumnya selesai.
class JourneysScreen extends ConsumerWidget {
  const JourneysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectorAsync = ref.watch(primarySectorDetailProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Perjalanan Belajarmu')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(primarySectorDetailProvider.future),
          child: switch (sectorAsync) {
            AsyncData(:final value)
                when value != null && value.journeys.isNotEmpty =>
              _JourneyList(detail: value),
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

class _JourneyList extends ConsumerWidget {
  const _JourneyList({required this.detail});

  final SectorDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sector = detail.sector;
    final surveys = sector.surveys;
    final allJourneysCompleted = detail.journeys.every(
      (journey) => journey.progress.status.isCompleted,
    );

    final showPretestSurvey =
        surveys.pretest.isConfigured && !surveys.pretest.isCompleted;
    final showPosttestSurvey =
        allJourneysCompleted &&
        surveys.posttest.isConfigured &&
        !surveys.posttest.isCompleted;

    Future<void> refresh() => ref.refresh(primarySectorDetailProvider.future);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Text(
            'Selesaikan setiap journey untuk menjadi konsumen '
            'yang cerdas dan berdaya.',
            style: AppTypography.bodySmall,
          ),
        ),
        if (showPretestSurvey) ...[
          SectorSurveyCard(
            title: 'Survei Pretest Sektor',
            description:
                'Sebelum mulai belajar, isi dulu survei singkat ini untuk '
                'mengukur pemahamanmu saat ini.',
            link: surveys.pretest.link!,
            onComplete: () async {
              await ref
                  .read(learningRepositoryProvider)
                  .completePretestSurvey(sector.slug);
              await refresh();
            },
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        for (final journey in detail.journeys) ...[
          JourneyCard(
            journey: journey,
            label: 'Journey ${journey.order}',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => JourneyDetailScreen(journeyId: journey.id),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (showPosttestSurvey)
          SectorSurveyCard(
            title: 'Survei Posttest Sektor',
            description:
                'Kamu sudah menyelesaikan semua journey di sektor ini — isi '
                'survei penutup untuk mengukur perkembangan pemahamanmu.',
            link: surveys.posttest.link!,
            onComplete: () async {
              await ref
                  .read(learningRepositoryProvider)
                  .completePosttestSurvey(sector.slug);
              await refresh();
            },
          ),
      ],
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
            'Gagal memuat daftar journey. Tarik ke bawah untuk coba lagi.',
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
        'Belum ada journey tersedia.',
        style: AppTypography.bodySmall,
        textAlign: TextAlign.center,
      ),
    );
  }
}
