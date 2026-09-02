import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/primary_button.dart';
import '../../learning/application/learning_providers.dart';
import '../../learning/data/models/sector.dart';
import '../application/sector_selection_provider.dart';

class SectorSelectionScreen extends ConsumerStatefulWidget {
  const SectorSelectionScreen({super.key});

  @override
  ConsumerState<SectorSelectionScreen> createState() =>
      _SectorSelectionScreenState();
}

class _SectorSelectionScreenState extends ConsumerState<SectorSelectionScreen> {
  String? _selectedSlug;
  bool _saving = false;

  Future<void> _confirm(String slug) async {
    if (_saving) return;
    setState(() => _saving = true);
    // Menyetel sektor aktif sesi ini -> `AppRoot` rebuild ke `MainShell`
    // dan layar ini dibuang, jadi tidak perlu reset `_saving`.
    await selectSector(ref, slug);
  }

  @override
  Widget build(BuildContext context) {
    final sectorsAsync = ref.watch(sectorsProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.md,
                AppSpacing.screenPadding,
                AppSpacing.lg,
              ),
              child: _Header(),
            ),
            Expanded(
              child: switch (sectorsAsync) {
                AsyncData(value: final sectors) when sectors.isNotEmpty =>
                  _Content(
                    sectors: sectors,
                    selectedSlug: _selectedSlug ?? sectors.first.slug,
                    saving: _saving,
                    onSelect: (slug) => setState(() => _selectedSlug = slug),
                    onConfirm: _confirm,
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
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilih sektor yang akan kamu pelajari',
                style: AppTypography.displayMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Pilih satu sektor pembelajaran. Seluruh materi, simulasi, '
                'dan evaluasi akan disesuaikan dengan sektor yang kamu pilih.',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.emoji_events_rounded,
            color: AppColors.primary,
            size: 24,
          ),
        ),
      ],
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.sectors,
    required this.selectedSlug,
    required this.saving,
    required this.onSelect,
    required this.onConfirm,
  });

  final List<Sector> sectors;
  final String selectedSlug;
  final bool saving;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onConfirm;

  @override
  Widget build(BuildContext context) {
    final selected = sectors.firstWhere(
      (s) => s.slug == selectedSlug,
      orElse: () => sectors.first,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  0,
                  AppSpacing.screenPadding,
                  AppSpacing.lg,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                  mainAxisExtent: 208,
                ),
                itemCount: sectors.length,
                itemBuilder: (context, index) {
                  final sector = sectors[index];
                  return _SectorCard(
                    sector: sector,
                    selected: sector.slug == selectedSlug,
                    onTap: saving ? null : () => onSelect(sector.slug),
                  );
                },
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: constraints.maxHeight * 0.62,
              ),
              child: _SelectionPanel(
                sector: selected,
                saving: saving,
                onConfirm: () => onConfirm(selected.slug),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectorCard extends StatelessWidget {
  const _SectorCard({
    required this.sector,
    required this.selected,
    required this.onTap,
  });

  final Sector sector;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tint = sectorColor(sector.color);

    return Material(
      color: AppColors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 1.6 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            boxShadow: selected ? AppShadows.card : null,
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _SectorIcon(sector: sector, tint: tint, checked: selected),
              const SizedBox(height: AppSpacing.sm),
              Text(
                sector.name,
                style: AppTypography.titleSmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (sector.description case final description?) ...[
                const SizedBox(height: AppSpacing.xs),
                Flexible(
                  child: Text(
                    description,
                    style: AppTypography.labelSmall,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectorIcon extends StatelessWidget {
  const _SectorIcon({
    required this.sector,
    required this.tint,
    required this.checked,
    this.size = 56,
  });

  final Sector sector;
  final Color tint;
  final bool checked;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              sectorIcon(sector.name),
              color: tint,
              size: size * 0.46,
            ),
          ),
          if (checked)
            Positioned(
              top: -2,
              left: -2,
              child: Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.white,
                  size: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SelectionPanel extends StatelessWidget {
  const _SelectionPanel({
    required this.sector,
    required this.saving,
    required this.onConfirm,
  });

  final Sector sector;
  final bool saving;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final tint = sectorColor(sector.color);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
        boxShadow: AppShadows.navBar,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.sm,
            AppSpacing.screenPadding,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.muted,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _SectorIcon(
                            sector: sector,
                            tint: tint,
                            checked: true,
                            size: 48,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kamu memilih',
                                  style: AppTypography.bodySmall,
                                ),
                                Text(
                                  sector.name,
                                  style: AppTypography.displayMedium.copyWith(
                                    color: tint,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (sector.description case final description?) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Di sektor ini kamu akan belajar tentang:',
                          style: AppTypography.titleSmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          description,
                          style: AppTypography.bodySmall,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.verified_user_outlined,
                              color: AppColors.primary,
                              size: 18,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                'Pilihan sektor ini akan menjadi jalur '
                                'pembelajaranmu selama proses belajar.',
                                style: AppTypography.labelSmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: 'Mulai Belajar',
                isLoading: saving,
                onPressed: saving ? null : onConfirm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color sectorColor(String? hex) {
  if (hex == null || hex.isEmpty) return AppColors.primary;
  final normalized = hex.replaceFirst('#', '').trim();
  final value = int.tryParse(normalized, radix: 16);
  if (value == null) return AppColors.primary;
  return Color(normalized.length == 6 ? value | 0xFF000000 : value);
}

IconData sectorIcon(String name) {
  final n = name.toLowerCase();
  bool has(List<String> keys) => keys.any(n.contains);

  if (has(['commerce', 'belanja', 'transaksi jual'])) {
    return Icons.shopping_cart_rounded;
  }
  if (has(['kesehatan', 'medis', 'rumah sakit'])) {
    return Icons.monitor_heart_rounded;
  }
  if (has(['transport'])) return Icons.directions_bus_rounded;
  if (has(['perumahan', 'sanitasi', 'air'])) return Icons.home_rounded;
  if (has(['keuangan', 'asuransi', 'bank'])) {
    return Icons.account_balance_rounded;
  }
  if (has(['obat', 'kosmetik', 'makanan', 'farmasi'])) {
    return Icons.medication_rounded;
  }
  if (has(['elektronik', 'telematika', 'kendaraan', 'otomotif'])) {
    return Icons.devices_rounded;
  }
  if (has(['listrik', 'bbm', 'gas', 'energi'])) return Icons.bolt_rounded;
  return Icons.category_rounded;
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
