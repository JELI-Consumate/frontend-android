import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/segmented_tabs.dart';
import '../application/complaint_providers.dart';
import 'complaint_agency_detail_screen.dart';
import 'widgets/agency_card.dart';
import 'widgets/category_guide.dart';

class ComplaintAgenciesScreen extends ConsumerStatefulWidget {
  const ComplaintAgenciesScreen({super.key});

  @override
  ConsumerState<ComplaintAgenciesScreen> createState() =>
      _ComplaintAgenciesScreenState();
}

class _ComplaintAgenciesScreenState
    extends ConsumerState<ComplaintAgenciesScreen> {
  static const _tabLabels = ['Daftar Lembaga', 'Pilih Sesuai Masalah'];

  int _tab = 0;

  void _openAgency(String slug) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ComplaintAgencyDetailScreen(slug: slug),
      ),
    );
  }

  Future<void> _refresh() async {
    ref.invalidate(complaintAgenciesProvider);
    ref.invalidate(complaintCategoriesProvider);
    Future<void> settle<T>(Future<T> future) async {
      try {
        await future;
      } catch (_) {
        // Error sudah ditampilkan oleh state provider masing-masing.
      }
    }

    await Future.wait([
      settle(ref.read(complaintAgenciesProvider.future)),
      settle(ref.read(complaintCategoriesProvider.future)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Layanan Pengaduan')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              const _IntroCard(),
              const SizedBox(height: AppSpacing.lg),
              SegmentedTabs(
                labels: _tabLabels,
                activeIndex: _tab,
                onChanged: (index) => setState(() => _tab = index),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_tab == 0)
                _AgencyList(onOpen: _openAgency)
              else
                _CategoryList(onOpenAgency: _openAgency),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          const Icon(Icons.support_agent, color: AppColors.white, size: 36),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Butuh bantuan mengadu?',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Hubungi lembaga resmi mitra Consumate yang sesuai dengan permasalahanmu.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.white.withValues(alpha: 0.8),
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

class _AgencyList extends ConsumerWidget {
  const _AgencyList({required this.onOpen});

  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(complaintAgenciesProvider);

    return switch (async) {
      AsyncData(:final value) when value.isEmpty => const _StateMessage(
        message: 'Belum ada lembaga pengaduan tersedia.',
      ),
      AsyncData(:final value) => Column(
        children: [
          for (final agency in value) ...[
            AgencyCard(agency: agency, onTap: () => onOpen(agency.slug)),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
      AsyncError() => _StateMessage(
        message: 'Gagal memuat daftar lembaga.',
        onRetry: () => ref.invalidate(complaintAgenciesProvider),
      ),
      _ => const _Loading(),
    };
  }
}

class _CategoryList extends ConsumerWidget {
  const _CategoryList({required this.onOpenAgency});

  final ValueChanged<String> onOpenAgency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(complaintCategoriesProvider);

    return switch (async) {
      AsyncData(:final value) when value.isEmpty => const _StateMessage(
        message: 'Belum ada panduan permasalahan tersedia.',
      ),
      AsyncData(:final value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bingung harus mengadu ke mana? Pilih jenis permasalahanmu untuk melihat lembaga yang relevan.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          CategoryGuide(categories: value, onOpenAgency: onOpenAgency),
        ],
      ),
      AsyncError() => _StateMessage(
        message: 'Gagal memuat panduan.',
        onRetry: () => ref.invalidate(complaintCategoriesProvider),
      ),
      _ => const _Loading(),
    };
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: AppSpacing.xl),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        children: [
          if (onRetry != null) ...[
            const Icon(Icons.error_outline, color: AppColors.muted, size: 40),
            const SizedBox(height: AppSpacing.sm),
          ],
          Text(
            message,
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}
