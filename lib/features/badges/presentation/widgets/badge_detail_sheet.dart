import 'package:flutter/material.dart' hide Badge;
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/badge.dart';
import 'badge_avatar.dart';

/// Bottom sheet detail satu badge, dibuka lewat tap di [BadgeTile] pada tab
/// "Pencapaian" -- menampilkan gambar & deskripsi lengkap, plus (kalau
/// sudah diraih) pesan ucapan selamat & motivasi yang diisi admin lewat tab
/// "Badge" di Filament (lihat BadgeRelationManager di backend). Badge yang
/// belum diraih tidak menampilkan kedua pesan itu -- isinya menyapa seolah
/// pengguna baru saja meraihnya, jadi tidak masuk akal ditampilkan sebelum
/// benar-benar diraih.
Future<void> showBadgeDetailSheet(BuildContext context, Badge badge) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BadgeDetailSheet(badge: badge),
  );
}

class _BadgeDetailSheet extends StatelessWidget {
  const _BadgeDetailSheet({required this.badge});

  final Badge badge;

  @override
  Widget build(BuildContext context) {
    // Deskripsi + pesan ucapan selamat + pesan motivasi sekaligus bisa lebih
    // tinggi dari layar (terutama badge yang sudah diraih, ketiganya
    // tampil) -- dibatasi ke persentase tinggi layar lalu dibungkus
    // `SingleChildScrollView` supaya sisanya discroll di dalam sheet,
    // bukan overflow ke luar layar.
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.sm,
              AppSpacing.screenPadding,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: _SheetDragHandle()),
                const SizedBox(height: AppSpacing.md),
                Center(child: BadgeAvatar(badge: badge, size: 96)),
                const SizedBox(height: AppSpacing.md),
                Text(
                  badge.name,
                  style: AppTypography.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                _StatusLine(badge: badge),
                const SizedBox(height: AppSpacing.lg),
                _Section(label: 'Deskripsi Badge', body: badge.description),
                if (badge.earned && _hasText(badge.congratulationMessage)) ...[
                  const SizedBox(height: AppSpacing.md),
                  _Section(
                    label: 'Pesan Saat Diraih',
                    body: badge.congratulationMessage!,
                  ),
                ],
                if (badge.earned && _hasText(badge.motivationalMessage)) ...[
                  const SizedBox(height: AppSpacing.md),
                  _Section(
                    label: 'Pesan Motivasi',
                    body: badge.motivationalMessage!,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Tutup'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
}

/// Baris status di-`Row` biasa (bukan di-`Center`) supaya teksnya yang
/// panjang ("Selesaikan journey terkait...") bisa bungkus ke baris
/// berikutnya lewat `Flexible` alih-alih meluber ke luar sheet -- lebar
/// penuh + `MainAxisAlignment.center` cukup buat tetap kelihatan center.
class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.badge});

  final Badge badge;

  @override
  Widget build(BuildContext context) {
    if (badge.earned) {
      final earnedAt = badge.earnedAt;
      final label = earnedAt == null
          ? 'Sudah diraih'
          : 'Diraih ${DateFormat('d MMMM y', 'id_ID').format(earnedAt)}';
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 14, color: AppColors.success),
          const SizedBox(width: AppSpacing.xxs),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline, size: 14, color: AppColors.inkMuted),
        const SizedBox(width: AppSpacing.xxs),
        Flexible(
          child: Text(
            'Selesaikan journey terkait untuk meraih ini',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(color: AppColors.inkMuted),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.body});

  final String label;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTypography.labelSmall),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          body,
          style: AppTypography.bodyMedium,
          textAlign: TextAlign.justify,
        ),
      ],
    );
  }
}

/// Garis kecil di puncak bottom sheet -- penanda visual umum bahwa ini
/// panel yang bisa ditutup swipe-down. Duplikat kecil dari `_SheetDragHandle`
/// di profile_screen.dart (privat di sana, belum ada widget bersama untuk
/// ini di app).
class _SheetDragHandle extends StatelessWidget {
  const _SheetDragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
    );
  }
}
