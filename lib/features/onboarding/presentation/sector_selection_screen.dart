import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../learning/application/learning_providers.dart';
import '../../learning/data/models/sector.dart';
import '../application/sector_selection_provider.dart';

/// Langkah terakhir sebelum masuk ke [MainShell]: pengguna yang baru login
/// dan belum pernah memilih sektor (lihat [selectedSectorSlugProvider])
/// memilih topik perlindungan konsumen yang mau dipelajari lebih dulu.
///
/// Tidak menavigasi kemana-mana secara manual saat sukses -- [AppRoot]
/// nge-watch [selectedSectorSlugProvider] dan rebuild sendiri ke MainShell
/// begitu tersimpan (layar ini dikembalikan langsung oleh AppRoot, bukan
/// di-push lewat Navigator, jadi tidak ada stack yang perlu di-pop).
class SectorSelectionScreen extends ConsumerStatefulWidget {
  const SectorSelectionScreen({super.key});

  @override
  ConsumerState<SectorSelectionScreen> createState() =>
      _SectorSelectionScreenState();
}

class _SectorSelectionScreenState extends ConsumerState<SectorSelectionScreen> {
  String? _savingSlug;

  Future<void> _select(Sector sector) async {
    if (_savingSlug != null) return;
    setState(() => _savingSlug = sector.slug);
    try {
      await selectSector(ref, sector.slug);
      // Sukses: AppRoot rebuild ke MainShell dan layar ini dibuang, tidak
      // perlu setState lagi -- widget ini mungkin sudah tidak ada.
    } catch (_) {
      if (!mounted) return;
      setState(() => _savingSlug = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak bisa menyimpan pilihan sektor. Coba lagi.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sectorsAsync = ref.watch(sectorsProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pilih Sektor Belajarmu', style: AppTypography.displaySmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Pilih topik perlindungan konsumen yang mau kamu pelajari '
                'lebih dulu. Kamu bisa mempelajari sektor lain kapan saja '
                'nanti.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: switch (sectorsAsync) {
                  AsyncData(value: final sectors) when sectors.isNotEmpty =>
                    ListView.separated(
                      itemCount: sectors.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) => _SectorCard(
                        sector: sectors[index],
                        isSaving: _savingSlug == sectors[index].slug,
                        enabled: _savingSlug == null,
                        onTap: () => _select(sectors[index]),
                      ),
                    ),
                  AsyncData() => const _EmptyState(),
                  AsyncError() => _ErrorState(
                    onRetry: () => ref.invalidate(sectorsProvider),
                  ),
                  _ => const Center(child: CircularProgressIndicator()),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectorCard extends StatelessWidget {
  const _SectorCard({
    required this.sector,
    required this.isSaving,
    required this.enabled,
    required this.onTap,
  });

  final Sector sector;
  final bool isSaving;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectorIcon(sector: sector),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sector.name, style: AppTypography.titleMedium),
                    if (sector.description case final description?) ...[
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: AppTypography.bodySmall,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              SizedBox(
                width: 24,
                height: 24,
                child: isSaving
                    ? const CircularProgressIndicator(strokeWidth: 2.4)
                    : const Icon(Icons.chevron_right, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lingkaran ikon sektor. Backend belum mengisi `icon_url`/`color` untuk
/// sektor manapun saat ini, jadi selalu ada fallback yang layak tampil --
/// bukan kotak kosong kalau field-nya null.
class _SectorIcon extends StatelessWidget {
  const _SectorIcon({required this.sector});

  final Sector sector;

  @override
  Widget build(BuildContext context) {
    final tint = _parseColor(sector.color) ?? AppColors.primary;
    final iconUrl = sector.iconUrl;

    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: iconUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Image.network(
                iconUrl,
                width: 32,
                height: 32,
                errorBuilder: (_, _, _) =>
                    Icon(Icons.storefront_rounded, color: tint, size: 28),
              ),
            )
          : Icon(Icons.storefront_rounded, color: tint, size: 28),
    );
  }

  static Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final normalized = hex.replaceFirst('#', '');
    final value = int.tryParse(normalized, radix: 16);
    if (value == null) return null;
    return Color(normalized.length == 6 ? value | 0xFF000000 : value);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          'Belum ada sektor pembelajaran tersedia. Coba lagi nanti.',
          style: AppTypography.bodySmall,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.muted, size: 40),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Gagal memuat daftar sektor.',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
          ],
        ),
      ),
    );
  }
}
