import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_alert_dialog.dart';
import '../application/complaint_providers.dart';
import '../data/models/complaint_agency.dart';
import 'widgets/agency_logo.dart';
import 'widgets/channel_card.dart';

class ComplaintAgencyDetailScreen extends ConsumerWidget {
  const ComplaintAgencyDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(complaintAgencyDetailProvider(slug));

    return Scaffold(
      appBar: AppBar(title: Text(async.value?.shortName ?? 'Detail Lembaga')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(complaintAgencyDetailProvider(slug));
            try {
              await ref.read(complaintAgencyDetailProvider(slug).future);
            } catch (_) {
              // Error sudah ditampilkan oleh state provider.
            }
          },
          child: switch (async) {
            AsyncData(:final value) => _DetailBody(agency: value),
            AsyncError(:final error) => _ErrorBody(
              notFound: error is ApiException && error.statusCode == 404,
              onRetry: () =>
                  ref.invalidate(complaintAgencyDetailProvider(slug)),
            ),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.notFound, required this.onRetry});

  final bool notFound;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        const SizedBox(height: AppSpacing.xl),
        Text(
          notFound
              ? 'Lembaga ini tidak ditemukan atau sudah tidak tersedia.'
              : 'Gagal memuat detail lembaga. Coba lagi nanti.',
          style: AppTypography.bodySmall,
          textAlign: TextAlign.center,
        ),
        if (!notFound)
          Center(
            child: TextButton(
              onPressed: onRetry,
              child: const Text('Coba lagi'),
            ),
          ),
      ],
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.agency});

  final ComplaintAgencyDetail agency;

  Future<void> _open(BuildContext context, WidgetRef ref, String url) async {
    final uri = Uri.tryParse(url);
    final launcher = ref.read(externalUrlLauncherProvider);
    var opened = false;
    if (uri != null) {
      try {
        opened = await launcher(uri);
      } catch (_) {
        opened = false;
      }
    }

    if (opened || !context.mounted) return;

    showAppAlert(
      context,
      type: AppAlertType.error,
      title: 'Gagal Membuka Tautan',
      message: 'Tidak ada aplikasi yang bisa membuka kanal ini. Coba lagi.',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        0,
        AppSpacing.screenPadding,
        AppSpacing.xl,
      ),
      children: [
        Row(
          children: [
            AgencyLogo(logoUrl: agency.logoUrl, size: 72),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      agency.shortName,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    agency.fullName,
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.primary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (agency.summary.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(agency.summary, style: AppTypography.bodySmall),
        ],
        if (agency.description.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          const _SectionTitle('Tentang Lembaga'),
          const SizedBox(height: AppSpacing.xs),
          Text(
            agency.description,
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.justify,
          ),
        ],
        if (agency.whenToContact.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          const _SectionTitle('Kapan Perlu Menghubungi?'),
          const SizedBox(height: AppSpacing.xs),
          for (final item in agency.whenToContact)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Icon(
                      Icons.check_circle,
                      size: 18,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(child: Text(item, style: AppTypography.bodyMedium)),
                ],
              ),
            ),
        ],
        if (agency.howToAccess != null) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.checklist, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Cara Mengakses',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  agency.howToAccess!,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.ink),
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        const _SectionTitle('Kanal Pengaduan'),
        const SizedBox(height: AppSpacing.sm),
        if (agency.channels.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'Kontak resmi lembaga ini belum tersedia di aplikasi. Silakan cari kanal resmi lembaga melalui situs atau kantor perwakilan terdekat.',
              style: AppTypography.bodySmall,
            ),
          )
        else
          for (final channel in agency.channels) ...[
            ChannelCard(
              channel: channel,
              onOpen: (url) => _open(context, ref, url),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        if (agency.notes != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.warningSoft,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    agency.notes!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTypography.titleMedium);
  }
}
