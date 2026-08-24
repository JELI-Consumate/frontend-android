import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../application/learning_providers.dart';
import 'journey_detail_screen.dart';
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
              ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                itemCount: value.journeys.length + 1,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Text(
                        'Selesaikan setiap journey untuk menjadi konsumen '
                        'yang cerdas dan berdaya.',
                        style: AppTypography.bodySmall,
                      ),
                    );
                  }

                  final journey = value.journeys[index - 1];
                  return JourneyCard(
                    journey: journey,
                    label: 'Journey ${journey.order}',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            JourneyDetailScreen(journeyId: journey.id),
                      ),
                    ),
                  );
                },
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
