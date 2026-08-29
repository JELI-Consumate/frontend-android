import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_alert_dialog.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/models/content/simulation_content.dart';
import '../data/models/module_detail.dart';
import '../data/models/module_page.dart';
import '../data/models/simulation_attempt.dart';
import '../data/module_repository.dart';
import 'widgets/module_async_scaffold.dart';
import 'widgets/module_bottom_bar.dart';
import 'widgets/module_continue_button.dart';
import 'widgets/module_header.dart';
import 'widgets/module_page_nav.dart';
import 'widgets/module_top_bar.dart';

/// Modul tipe `simulasi` -- salah satu dari dua game (lihat
/// [SimulationGameType]). Gaya Duolingo: tiap percobaan dicek satu-satu ke
/// server, jawaban salah tidak disimpan jadi boleh dicoba lagi tanpa
/// menggagalkan attempt-nya (lihat `SimulationScoringService::checkAnswer`
/// di backend). Selesai otomatis begitu seluruh item pernah dijawab benar --
/// tombol gabungan buat lanjut ke halaman/module berikutnya baru muncul di
/// [ModuleBottomBar] begitu itu terjadi (lihat `_CompletionView`).
class SimulationModuleScreen extends ConsumerStatefulWidget {
  const SimulationModuleScreen({
    super.key,
    required this.module,
    required this.page,
    required this.nav,
  });

  final ModuleDetail module;
  final ModulePage page;
  final ModulePageNav nav;

  @override
  ConsumerState<SimulationModuleScreen> createState() =>
      _SimulationModuleScreenState();
}

class _SimulationModuleScreenState
    extends ConsumerState<SimulationModuleScreen> {
  int? _attemptId;
  ApiException? _startError;
  SimulationAttempt? _latestAttempt;

  SimulationContent get _content =>
      (widget.page.content as SimulationPageContent).content;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      final attemptId = await ref
          .read(moduleRepositoryProvider)
          .startSimulationAttempt(_content.id);
      if (mounted) setState(() => _attemptId = attemptId);
    } on ApiException catch (error) {
      if (mounted) setState(() => _startError = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_startError != null) {
      return ModuleErrorScaffold(
        title: widget.module.title,
        message: _startError!.message,
      );
    }
    final attemptId = _attemptId;
    if (attemptId == null) return const ModuleLoadingScaffold();

    final completedAttempt = _latestAttempt;
    final isCompleted =
        completedAttempt != null && completedAttempt.isCompleted;

    return Scaffold(
      appBar: ModuleTopBar(
        position: widget.nav.modulePosition,
        total: widget.nav.moduleTotal,
      ),
      body: SafeArea(
        bottom: false,
        child: isCompleted
            ? _CompletionView(attempt: completedAttempt)
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Matching pakai heading polos (nama misi dari
                    // `SimulationContent.title`) TANPA `ModuleHeader` maupun
                    // badge tipe/skenario/kick-off -- sesuai referensi desain
                    // yang cuma menampilkan satu judul tebal di atas grid
                    // kartu. Ordering (dan tipe lain) tetap pakai header lama.
                    if (_content.simulationType ==
                        SimulationGameType.matching) ...[
                      Text(_content.title, style: AppTypography.titleLarge),
                      const SizedBox(height: AppSpacing.lg),
                    ] else ...[
                      ModuleHeader(module: widget.module),
                      const SizedBox(height: AppSpacing.lg),
                      _ScenarioHeader(
                        type: _content.simulationType,
                        scenario: _content.scenario,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    switch (_content.simulationType) {
                      SimulationGameType.matching => _MatchingGame(
                        attemptId: attemptId,
                        pairs: _content.matchingPairs,
                        onChecked: (attempt) =>
                            setState(() => _latestAttempt = attempt),
                      ),
                      SimulationGameType.ordering => _OrderingGame(
                        attemptId: attemptId,
                        steps: _content.orderingSteps,
                        onChecked: (attempt) =>
                            setState(() => _latestAttempt = attempt),
                      ),
                      SimulationGameType.unknown => Text(
                        'Tipe simulasi ini belum didukung.',
                        style: AppTypography.bodySmall,
                      ),
                    },
                  ],
                ),
              ),
      ),
      bottomNavigationBar: isCompleted
          ? ModuleBottomBar(
              pageCount: widget.nav.pageCount,
              pageIndex: widget.nav.pageIndex,
              onDotTap: widget.nav.onDotTap,
              child: ModuleContinueButton(
                hasNext: widget.nav.hasNext,
                busy: false,
                onPressed: widget.nav.onAdvance,
              ),
            )
          : null,
    );
  }
}

/// Header di atas game -- badge tipe game, kalimat skenario (rata tengah),
/// lalu badge "kick-off" bergaya alert. Badge tipe & kick-off teksnya TETAP
/// (generik per [SimulationGameType]), bukan data per-simulasi -- backend
/// belum punya kolom buat itu, lihat `SimulationContent`.
class _ScenarioHeader extends StatelessWidget {
  const _ScenarioHeader({required this.type, required this.scenario});

  final SimulationGameType type;
  final String scenario;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TypeBadge(type: type),
        const SizedBox(height: AppSpacing.sm),
        Text(
          scenario,
          style: AppTypography.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        _KickoffBadge(type: type),
      ],
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final SimulationGameType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconFor(type), size: 15, color: AppColors.primary),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            _labelFor(type),
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _labelFor(SimulationGameType type) => switch (type) {
    SimulationGameType.matching => 'Pilah Cepat',
    SimulationGameType.ordering => 'Susun Jalur Solusi',
    SimulationGameType.unknown => 'Simulasi',
  };

  IconData _iconFor(SimulationGameType type) => switch (type) {
    SimulationGameType.matching => Icons.compare_arrows,
    SimulationGameType.ordering => Icons.swap_vert,
    SimulationGameType.unknown => Icons.extension_outlined,
  };
}

class _KickoffBadge extends StatelessWidget {
  const _KickoffBadge({required this.type});

  final SimulationGameType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.report_gmailerrorred_outlined,
            size: 15,
            color: AppColors.danger,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            _labelFor(type),
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.danger,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _labelFor(SimulationGameType type) => switch (type) {
    SimulationGameType.matching => 'Situasi Dimulai',
    SimulationGameType.ordering => 'Masalah Terjadi',
    SimulationGameType.unknown => 'Simulasi Dimulai',
  };
}

class _CompletionView extends StatelessWidget {
  const _CompletionView({required this.attempt});

  final SimulationAttempt attempt;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.success,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            children: [
              const Icon(Icons.emoji_events, color: AppColors.white, size: 40),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Simulasi selesai!',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.white,
                ),
              ),
              if (attempt.score != null && attempt.maxScore != null) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Skor ${attempt.score}/${attempt.maxScore}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Game "pasangkan kartu" -- tap satu kartu kiri lalu satu kartu kanan untuk
/// mencoba mencocokkan, ditata 2 kolom berkartu (lihat `_MatchCard`). Kolom
/// kanan diacak sendiri di sisi Flutter supaya urutannya tidak otomatis
/// sejajar dengan kolom kiri (backend mengirim keduanya dalam urutan
/// `order` yang sama).
class _MatchingGame extends ConsumerStatefulWidget {
  const _MatchingGame({
    required this.attemptId,
    required this.pairs,
    required this.onChecked,
  });

  final int attemptId;
  final List<SimulationMatchingPair> pairs;
  final ValueChanged<SimulationAttempt> onChecked;

  @override
  ConsumerState<_MatchingGame> createState() => _MatchingGameState();
}

class _MatchingGameState extends ConsumerState<_MatchingGame> {
  late final List<SimulationMatchingPair> _rightItems = [...widget.pairs]
    ..shuffle();

  final Set<int> _solved = {};
  int? _selectedLeftId;
  bool _checking = false;

  Future<void> _tryMatch(int rightPairId) async {
    final leftId = _selectedLeftId;
    if (leftId == null || _checking) return;

    setState(() => _checking = true);
    try {
      final result = await ref
          .read(moduleRepositoryProvider)
          .checkMatchingAnswer(
            attemptId: widget.attemptId,
            pairId: leftId,
            submittedRightPairId: rightPairId,
          );

      widget.onChecked(result.attempt);

      if (result.correct) {
        setState(() {
          _solved.add(leftId);
          _selectedLeftId = null;
        });
      } else if (mounted) {
        setState(() => _selectedLeftId = null);
        showAppAlert(
          context,
          type: AppAlertType.warning,
          title: 'Coba Lagi',
          message: 'Belum pas, coba pasangan lain.',
        );
      }
    } on ApiException catch (error) {
      if (mounted) {
        showAppAlert(
          context,
          type: AppAlertType.error,
          title: 'Gagal Mengecek Jawaban',
          message: error.message,
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_solved.length}/${widget.pairs.length} pasangan benar',
          style: AppTypography.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        // Satu `Row` PER PASANGAN (bukan 2 Column independen) supaya kartu
        // kiri & kanan di baris yang sama disamakan tinggi -- `IntrinsicHeight`
        // menghitung tinggi alami yang PALING TINGGI di antara keduanya, lalu
        // `CrossAxisAlignment.stretch` menyamakan yang lebih pendek jadi
        // setinggi itu. Beda dari kotak dipatok tinggi TETAP (regresi
        // sebelumnya): di sini batasnya ikut konten TERTINGGI di baris itu,
        // jadi deskripsi tetap tidak pernah kepotong, cuma kartu satunya yang
        // ikut melar menyesuaikan (isinya di-tengahkan, lihat `_MatchCard`).
        for (var i = 0; i < widget.pairs.length; i++) ...[
          _buildPairRow(widget.pairs[i], _rightItems[i]),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  Widget _buildPairRow(
    SimulationMatchingPair left,
    SimulationMatchingPair right,
  ) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _MatchCard(
              label: left.leftLabel,
              description: left.leftDescription,
              imageUrl: left.leftImageUrl,
              solved: _solved.contains(left.id),
              selected: _selectedLeftId == left.id,
              onTap: _solved.contains(left.id) || _checking
                  ? null
                  : () => setState(
                      () => _selectedLeftId = _selectedLeftId == left.id
                          ? null
                          : left.id,
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _MatchCard(
              label: right.rightLabel,
              description: right.rightDescription,
              imageUrl: right.rightImageUrl,
              solved: _solved.contains(right.id),
              selected: false,
              onTap: _solved.contains(right.id) || _checking
                  ? null
                  : () => _tryMatch(right.id),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu kiri/kanan di game matching -- gambar (opsional, `leftImageUrl`/
/// `rightImageUrl`), judul tebal, lalu deskripsi kecil abu-abu (opsional,
/// `leftDescription`/`rightDescription`), ditumpuk & DITENGAHKAN horizontal,
/// TINGGINYA MENGIKUTI KONTEN SENDIRI (tidak dipatok sama seperti kartu
/// sebelah) -- supaya deskripsi yang panjang selalu tampil penuh, tidak
/// terpotong "..." cuma demi menyeragamkan tinggi kotak.
///
/// Tidak pakai `ZoomableImage` (beda dari `_ImageBlock` di layar artikel)
/// karena tap di seluruh kartu ini sudah dipakai untuk MEMILIH/MENCOCOKKAN
/// pasangan -- kalau gambarnya ikut bisa di-zoom, dua gestur tap itu bentrok.
class _MatchCard extends StatelessWidget {
  const _MatchCard({
    required this.label,
    required this.description,
    required this.imageUrl,
    required this.solved,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String? description;
  final String? imageUrl;
  final bool solved;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = solved
        ? AppColors.success
        : selected
        ? AppColors.primary
        : AppColors.border;

    return Opacity(
      opacity: solved ? 0.6 : 1,
      child: Material(
        color: selected ? AppColors.primarySoft : AppColors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: color, width: selected || solved ? 1.6 : 1),
        ),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            // Kartu di baris yang sama sekarang disamakan tinggi (lihat
            // `_MatchingGameState._buildPairRow`) -- kartu yang isinya lebih
            // pendek dari pasangannya jadi punya ruang kosong ekstra di
            // bawah; `alignment: center` menengahkan isinya di ruang itu,
            // bukan nempel mepet ke atas.
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (imageUrl case final url? when url.isNotEmpty) ...[
                      AspectRatio(
                        aspectRatio: 16 / 10,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: Image.network(
                            url,
                            // Diminta lebih kecil dari resolusi aslinya
                            // (gambar sumbernya bisa >1MB) -- decode server
                            // Skia jadi jauh lebih ringan & cepat daripada
                            // decode ukuran penuh lalu di-downscale di layar.
                            cacheWidth: 400,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                            // Placeholder ikon yang KELIHATAN (bukan
                            // `SizedBox.shrink()`) kalau gambar gagal
                            // dimuat -- supaya gagal-muat gampang dibedakan
                            // dari pasangan yang memang tidak diberi gambar.
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: AppColors.background,
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 20,
                                    color: AppColors.inkMuted,
                                  ),
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                    ],
                    Text(
                      label,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (description case final desc? when desc.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        desc,
                        style: AppTypography.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              if (solved)
                const Positioned(
                  top: 6,
                  right: 6,
                  child: Icon(
                    Icons.check_circle,
                    size: 18,
                    color: AppColors.success,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Game "susun urutan" -- SERET (drag) kartu dari "Langkah Tersedia" ke slot
/// yang dituju (atau tap kartunya buat langsung ditaruh di slot kosong
/// berikutnya, kalau malas nge-drag), tap tombol "x" di slot yang sudah
/// terisi untuk membatalkan (kembali ke pool). Nyeret ke slot yang SUDAH
/// terisi menukar isinya -- yang lama balik ke pool, yang baru masuk.
///
/// Taruh satu-satu TIDAK langsung dicek ke server -- baru dicek SEKALIGUS
/// begitu semua slot terisi dan tombol "Cek Jalur" ditekan (lihat
/// `_checkPath`). Backend tetap dicek satu-per-satu lewat endpoint yang sama
/// (`checkOrderingAnswer` per langkah); yang berubah cuma KAPAN pengecekan
/// itu dipicu dari sisi client.
class _OrderingGame extends ConsumerStatefulWidget {
  const _OrderingGame({
    required this.attemptId,
    required this.steps,
    required this.onChecked,
  });

  final int attemptId;
  final List<SimulationOrderingStep> steps;
  final ValueChanged<SimulationAttempt> onChecked;

  @override
  ConsumerState<_OrderingGame> createState() => _OrderingGameState();
}

class _OrderingGameState extends ConsumerState<_OrderingGame> {
  late final List<SimulationOrderingStep> _pool = [...widget.steps]..shuffle();
  late final List<SimulationOrderingStep?> _placed = List.filled(
    widget.steps.length,
    null,
  );

  bool _checking = false;

  bool get _allSlotsFilled => _placed.every((step) => step != null);

  /// Dipakai jalur tap (taruh di slot kosong PERTAMA yang ketemu).
  void _placeInNextSlot(SimulationOrderingStep step) {
    if (_checking) return;
    final nextIndex = _placed.indexWhere((s) => s == null);
    if (nextIndex == -1) return;
    _placeInSlot(step, nextIndex);
  }

  /// Dipakai jalur drag-and-drop (taruh TEPAT di slot yang dituju). Kalau
  /// slot itu sudah terisi, isinya yang lama ditukar balik ke pool.
  void _placeInSlot(SimulationOrderingStep step, int slotIndex) {
    if (_checking) return;

    setState(() {
      final displaced = _placed[slotIndex];
      _pool.remove(step);
      _placed[slotIndex] = step;
      if (displaced != null) _pool.add(displaced);
    });
  }

  void _returnToPool(int slotIndex) {
    if (_checking) return;
    final step = _placed[slotIndex];
    if (step == null) return;

    setState(() {
      _placed[slotIndex] = null;
      _pool.add(step);
    });
  }

  Future<void> _checkPath() async {
    if (!_allSlotsFilled || _checking) return;

    setState(() => _checking = true);

    final wrongSteps = <SimulationOrderingStep>[];
    SimulationAttempt? latestAttempt;

    for (var i = 0; i < _placed.length; i++) {
      final step = _placed[i]!;
      try {
        final result = await ref
            .read(moduleRepositoryProvider)
            .checkOrderingAnswer(
              attemptId: widget.attemptId,
              stepId: step.id,
              submittedPosition: i + 1,
            );
        latestAttempt = result.attempt;
        if (!result.correct) wrongSteps.add(step);
      } on ApiException catch (error) {
        if (mounted) {
          showAppAlert(
            context,
            type: AppAlertType.error,
            title: 'Gagal Mengecek Jawaban',
            message: error.message,
          );
          setState(() => _checking = false);
        }
        return;
      }
    }

    if (latestAttempt case final attempt?) widget.onChecked(attempt);
    if (!mounted) return;

    // Langkah yang ternyata salah tidak tersimpan di server (lihat docblock
    // kelas) -- dikembalikan ke pool supaya bisa disusun ulang, langkah yang
    // benar tetap di slotnya.
    setState(() {
      for (final step in wrongSteps) {
        final index = _placed.indexOf(step);
        if (index != -1) _placed[index] = null;
      }
      _pool.addAll(wrongSteps);
      _checking = false;
    });

    if (wrongSteps.isNotEmpty) {
      showAppAlert(
        context,
        type: AppAlertType.warning,
        title: 'Belum Tepat',
        message: 'Ada langkah yang belum tepat, susun ulang ya.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _placed.length; i++) ...[
          if (i > 0) const _DashedConnector(),
          _OrderingSlot(
            position: i + 1,
            step: _placed[i],
            onRemove: (_placed[i] == null || _checking)
                ? null
                : () => _returnToPool(i),
            onAccept: _checking ? null : (step) => _placeInSlot(step, i),
          ),
        ],
        if (_pool.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('Langkah Tersedia:', style: AppTypography.titleSmall),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Seret ke kotak yang dituju, atau ketuk untuk taruh otomatis.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          // 1 kartu per baris -- lebar penuh supaya labelnya tidak
          // terpotong, beda dari grid 2 kolom sebelumnya.
          for (final step in _pool) ...[
            _PoolCard(
              step: step,
              onTap: _checking ? null : () => _placeInNextSlot(step),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: 'Cek Jalur',
          trailingIcon: Icons.arrow_forward,
          isLoading: _checking,
          onPressed: _allSlotsFilled ? _checkPath : null,
        ),
      ],
    );
  }
}

/// Slot tujuan drop -- `DragTarget` supaya kartu dari pool bisa DISERET ke
/// sini (bukan cuma tap). Border/warnanya animasi (`AnimatedContainer`)
/// begitu ada kartu yang lagi diseret di atasnya (`candidateData`), dan isi
/// labelnya animasi fade (`AnimatedSwitcher`) begitu slotnya terisi/kosong.
class _OrderingSlot extends StatelessWidget {
  const _OrderingSlot({
    required this.position,
    required this.step,
    required this.onRemove,
    required this.onAccept,
  });

  final int position;
  final SimulationOrderingStep? step;
  final VoidCallback? onRemove;
  final ValueChanged<SimulationOrderingStep>? onAccept;

  @override
  Widget build(BuildContext context) {
    final filled = step != null;

    return DragTarget<SimulationOrderingStep>(
      onWillAcceptWithDetails: (_) => onAccept != null,
      onAcceptWithDetails: (details) => onAccept?.call(details.data),
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: AppDuration.fast,
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: isHovering
                ? AppColors.primarySoft
                : filled
                ? AppColors.successSoft
                : AppColors.background,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: isHovering
                  ? AppColors.primary
                  : filled
                  ? AppColors.success
                  : AppColors.border,
              width: isHovering ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: filled ? AppColors.success : AppColors.muted,
                child: Text(
                  '$position',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AnimatedSwitcher(
                  duration: AppDuration.fast,
                  child: Text(
                    step?.label ??
                        'Seret atau ketuk salah satu langkah di bawah',
                    key: ValueKey(step?.id),
                    style: AppTypography.bodyMedium.copyWith(
                      color: filled ? AppColors.ink : AppColors.inkMuted,
                      fontStyle: filled ? FontStyle.normal : FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close, size: 16),
                  color: AppColors.inkMuted,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Garis putus-putus penghubung antar slot -- kesan alur/flowchart vertikal
/// seperti desain referensi, tanpa perlu tambah dependency baru.
class _DashedConnector extends StatelessWidget {
  const _DashedConnector();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.md,
      child: Center(
        child: CustomPaint(
          size: const Size(2, AppSpacing.md),
          painter: _DashedLinePainter(),
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 2;
    const dashHeight = 3.0;
    const dashSpace = 3.0;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(0, y + dashHeight), paint);
      y += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) => false;
}

/// Kartu di pool "Langkah Tersedia" -- bisa DISERET (tahan sebentar lalu
/// geser, lewat `LongPressDraggable` supaya tidak bentrok sama gestur scroll
/// vertikal layar ini) ke slot yang dituju, ATAU cukup diketuk untuk taruh
/// otomatis di slot kosong pertama (lihat `onTap`). Selagi diseret, kartu
/// aslinya memudar (`childWhenDragging`) dan versi yang ikut jari sedikit
/// membesar & mengambang (`feedback`) -- begitu dilepas di luar slot mana
/// pun, `Draggable` otomatis meng-animasikannya kembali ke posisi semula.
class _PoolCard extends StatelessWidget {
  const _PoolCard({required this.step, required this.onTap});

  final SimulationOrderingStep step;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = _PoolCardSurface(label: step.label);

    if (onTap == null) {
      return Opacity(opacity: 0.5, child: card);
    }

    return LongPressDraggable<SimulationOrderingStep>(
      data: step,
      delay: const Duration(milliseconds: 150),
      childWhenDragging: Opacity(opacity: 0.3, child: card),
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width:
              MediaQuery.sizeOf(context).width - (AppSpacing.screenPadding * 2),
          child: Transform.scale(
            scale: 1.05,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: card,
            ),
          ),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

class _PoolCardSurface extends StatelessWidget {
  const _PoolCardSurface({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primarySoft,
              child: const Icon(
                Icons.drag_indicator,
                size: 15,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
