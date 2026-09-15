import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/application/auth_controller.dart';
import '../../learning/application/learning_providers.dart';
import '../../learning/data/learning_repository.dart';
import '../../learning/data/models/journey.dart';
import '../../learning/data/models/sector_detail.dart';
import '../../learning/presentation/journey_detail_screen.dart';
import '../../learning/presentation/widgets/sector_survey_card.dart';
import 'widgets/continue_learning_card.dart';
import 'widgets/journey_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) => setState(() => _query = value);

  void _clearSearch() {
    _searchController.clear();
    FocusScope.of(context).unfocus();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final sectorAsync = ref.watch(primarySectorDetailProvider);
    final searchQuery = _query.trim();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: ClipRRect(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(primarySectorDetailProvider.future),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.sm),
                children: [
                  Text.rich(
                    TextSpan(
                      style: AppTypography.titleLarge,
                      children: [
                        const TextSpan(
                          text: 'Halo, Selamat datang kembali ',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 30,
                            color: Color(0xFF000000),
                          ),
                        ),
                        TextSpan(
                          text: '${user?.name ?? ''}!',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 30,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Siap belajar perlindungan konsumen hari ini?',
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _JourneySearchField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    onClear: _clearSearch,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (searchQuery.isNotEmpty)
                    _JourneySearchResults(
                      query: searchQuery,
                      sectorAsync: sectorAsync,
                    )
                  else
                    switch (sectorAsync) {
                      AsyncData(:final value) => _DashboardBody(
                        sectorDetail: value,
                      ),
                      AsyncError() => const _ErrorState(),
                      _ => const _LoadingState(),
                    },
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.sectorDetail});

  final SectorDetail? sectorDetail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = sectorDetail;
    if (detail == null || detail.journeys.isEmpty) {
      return const _EmptyState();
    }

    final inProgress = detail.inProgressJourney;
    final nextJourney = detail.nextJourney;

    final pretest = detail.sector.surveys.pretest;
    final showPretestSurvey = detail.pretestGateActive;

    final posttest = detail.sector.surveys.posttest;
    final allJourneysCompleted = detail.journeys.every(
      (journey) => journey.progress.status.isCompleted,
    );
    final showPosttestSurvey =
        allJourneysCompleted && posttest.isConfigured && !posttest.isCompleted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showPretestSurvey) ...[
          SectorSurveyCard(
            title: 'Survei Pre-Test Sektor',
            description:
                'Isi survei singkat ini lewat Google Form dulu untuk membuka '
                'journey pertama dan memetakan wawasanmu seputar hak konsumen.',
            link: pretest.link!,
            onComplete: () async {
              await ref
                  .read(learningRepositoryProvider)
                  .completePretestSurvey(detail.sector.slug);
              ref.invalidate(primarySectorDetailProvider);
              await ref.read(primarySectorDetailProvider.future);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (showPosttestSurvey) ...[
          SectorSurveyCard(
            title: 'Survei Post-Test Sektor',
            description:
                'Kamu sudah menyelesaikan semua journey di sektor ini — isi '
                'survei penutup lewat Google Form untuk mengukur perkembangan '
                'pemahamanmu.',
            link: posttest.link!,
            onComplete: () async {
              await ref
                  .read(learningRepositoryProvider)
                  .completePosttestSurvey(detail.sector.slug);
              ref.invalidate(primarySectorDetailProvider);
              await ref.read(primarySectorDetailProvider.future);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (inProgress != null) ...[
          Text('Lanjutkan Belajar', style: AppTypography.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          _ContinueLearningSection(journeyId: inProgress.id),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (nextJourney != null && !showPretestSurvey) ...[
          Text('Perjalanan', style: AppTypography.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          JourneyCard(
            journey: nextJourney,
            label: 'Journey ${nextJourney.order}',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => JourneyDetailScreen(journeyId: nextJourney.id),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ContinueLearningSection extends ConsumerWidget {
  const _ContinueLearningSection({required this.journeyId});

  final String journeyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(journeyDetailProvider(journeyId));

    return switch (detailAsync) {
      AsyncData(:final value) => ContinueLearningCard(
        journeyDetail: value,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => JourneyDetailScreen(journeyId: journeyId),
          ),
        ),
      ),
      AsyncError() => const SizedBox.shrink(),
      _ => const SizedBox(
        height: 170,
        child: Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

/// Kolom pencarian di Beranda -- khusus mencari journey berdasarkan judul.
class _JourneySearchField extends StatelessWidget {
  const _JourneySearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: BorderSide(color: AppColors.border),
    );

    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: AppTypography.bodyMedium,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppColors.white,
        hintText: 'Cari journey...',
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.muted),
        prefixIcon: const Icon(Icons.search, color: AppColors.muted, size: 20),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close, size: 18),
                color: AppColors.muted,
                tooltip: 'Hapus pencarian',
              ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}

/// Hasil pencarian journey: filter `sectorDetail.journeys` berdasarkan judul.
class _JourneySearchResults extends StatelessWidget {
  const _JourneySearchResults({
    required this.query,
    required this.sectorAsync,
  });

  final String query;
  final AsyncValue<SectorDetail?> sectorAsync;

  @override
  Widget build(BuildContext context) {
    return switch (sectorAsync) {
      AsyncData(:final value) => _buildResults(context, value),
      AsyncError() => const _ErrorState(),
      _ => const _LoadingState(),
    };
  }

  Widget _buildResults(BuildContext context, SectorDetail? detail) {
    final needle = query.toLowerCase();
    final matches = (detail?.journeys ?? const <Journey>[])
        .where((journey) => journey.title.toLowerCase().contains(needle))
        .toList();

    if (matches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xl),
        child: Text(
          'Tidak ada journey yang cocok dengan "$query".',
          style: AppTypography.bodySmall,
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${matches.length} journey ditemukan',
          style: AppTypography.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final journey in matches) ...[
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
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: AppSpacing.xxxl),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxl),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.muted, size: 40),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Gagal memuat data pembelajaran. Tarik ke bawah untuk coba lagi.',
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxl),
      child: Text(
        'Belum ada materi pembelajaran tersedia.',
        style: AppTypography.bodySmall,
        textAlign: TextAlign.center,
      ),
    );
  }
}
