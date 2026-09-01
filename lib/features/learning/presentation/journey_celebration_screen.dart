import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/main_tab_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/primary_button.dart';
import '../../badges/data/models/badge.dart';
import '../../badges/presentation/widgets/badge_avatar.dart';
import 'journey_detail_screen.dart';

/// Layar perayaan begitu satu journey selesai -- dibuka dari
/// [JourneyDetailScreen] tepat sesudah module terakhirnya ditandai selesai
/// DAN status journey ini baru saja (bukan sebelumnya) berubah jadi
/// completed (lihat `_JourneyDetailBody._openModule`), supaya tidak muncul
/// berulang tiap kali user sekadar membuka ulang journey yang sudah lama
/// selesai.
///
/// [badge] SELALU non-null di sini -- kalau admin belum sempat mengisi
/// badge journey ini di Filament, pemanggil sudah menyiapkan badge
/// pengganti generik (lihat `_JourneyDetailBody._fallbackBadge`) supaya
/// layar ini tidak perlu tahu soal kemungkinan "badge belum ada" sama
/// sekali.
class JourneyCelebrationScreen extends ConsumerWidget {
  const JourneyCelebrationScreen({
    super.key,
    required this.journeyOrder,
    required this.badge,
    required this.modulesCompleted,
    required this.modulesTotal,
    required this.quizScore,
    required this.nextJourneyId,
  });

  final int journeyOrder;
  final Badge badge;
  final int modulesCompleted;
  final int modulesTotal;

  /// Persen 0-100, `null` kalau journey ini tidak punya kuis evaluasi atau
  /// belum pernah dikerjakan.
  final int? quizScore;

  /// Id journey berikutnya di sektor yang sama, `null` kalau ini journey
  /// terakhir -- tombol "Lanjut ke Journey Berikutnya" disembunyikan waktu
  /// null, bukan ditampilkan nonaktif.
  final String? nextJourneyId;

  void _goToNextJourney(BuildContext context) {
    final id = nextJourneyId;
    if (id == null) return;

    // pushReplacement -- kartu perayaan ini sudah tidak relevan lagi begitu
    // user memilih lanjut, jadi tidak perlu ikut tertumpuk di back stack.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => JourneyDetailScreen(journeyId: id),
      ),
    );
  }

  void _goToHome(BuildContext context, WidgetRef ref) {
    ref.read(mainTabIndexProvider.notifier).select(0);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        automaticallyImplyLeading: false,
        title: Text(
          'Badge',
          style: AppTypography.labelMedium.copyWith(color: AppColors.muted),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.md,
            AppSpacing.screenPadding,
            AppSpacing.xl,
          ),
          child: Column(
            children: [
              Text(
                'PENCAPAIAN BARU!',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Journey $journeyOrder Selesai',
                style: AppTypography.displaySmall.copyWith(
                  color: AppColors.ink,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              _CelebrationBadgeRing(badge: badge),
              const SizedBox(height: AppSpacing.lg),
              Text(
                badge.name,
                style: AppTypography.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                badge.congratulationMessage ?? badge.description,
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              _JourneySummaryCard(
                journeyOrder: journeyOrder,
                modulesCompleted: modulesCompleted,
                modulesTotal: modulesTotal,
                quizScore: quizScore,
              ),
              const SizedBox(height: AppSpacing.xl),
              if (_hasText(badge.motivationalMessage)) ...[
                Text(
                  badge.motivationalMessage!,
                  style: AppTypography.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (nextJourneyId != null)
                PrimaryButton(
                  label: 'Lanjut ke Journey Berikutnya',
                  onPressed: () => _goToNextJourney(context),
                ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => _goToHome(context, ref),
                child: const Text('Kembali ke Beranda'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
}

/// Cincin emas melingkar di sekeliling gambar badge -- glow lembut di
/// lapisan paling luar, garis cincin solid di tengah, lalu badge sendiri
/// (lewat [BadgeAvatar] yang sama dipakai tab "Pencapaian") di lapisan
/// paling dalam. Dua bintang kecil di tepi cincin murni dekorasi.
class _CelebrationBadgeRing extends StatelessWidget {
  const _CelebrationBadgeRing({required this.badge});

  final Badge badge;

  static const _size = 200.0;
  static const _ringSize = 168.0;
  static const _avatarSize = 148.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.warning.withValues(alpha: 0.35),
                  AppColors.warning.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          Container(
            width: _ringSize,
            height: _ringSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.warning, width: 4),
            ),
          ),
          BadgeAvatar(badge: badge, size: _avatarSize),
          const Positioned(top: 6, right: 14, child: _StarDot()),
          const Positioned(bottom: 10, left: 10, child: _StarDot()),
        ],
      ),
    );
  }
}

class _StarDot extends StatelessWidget {
  const _StarDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.warning,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.star_rounded, size: 15, color: AppColors.white),
    );
  }
}

/// Kartu "Ringkasan Journey N" -- gaya sama seperti kartu progres di
/// `JourneyDetailScreen` (putih, border tipis, radius medium), isinya dua
/// `_StatTile` berdampingan alih-alih progress bar.
class _JourneySummaryCard extends StatelessWidget {
  const _JourneySummaryCard({
    required this.journeyOrder,
    required this.modulesCompleted,
    required this.modulesTotal,
    required this.quizScore,
  });

  final int journeyOrder;
  final int modulesCompleted;
  final int modulesTotal;
  final int? quizScore;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Journey $journeyOrder',
            style: AppTypography.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.check_circle,
                  iconColor: AppColors.primary,
                  label: 'Modul Diselesaikan',
                  value: '$modulesCompleted/$modulesTotal',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatTile(
                  icon: Icons.military_tech,
                  iconColor: AppColors.warning,
                  label: 'Skor Kuis',
                  value: quizScore == null ? '–' : '$quizScore%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(value, style: AppTypography.titleMedium),
            ],
          ),
        ),
      ],
    );
  }
}
