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
import 'widgets/module_continue_button.dart';
import 'widgets/module_header.dart';
import 'widgets/module_page_nav.dart';
import 'widgets/module_page_scaffold.dart';

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
  String? _attemptId;
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

    return ModulePageScaffold(
      nav: widget.nav,
      body: isCompleted
          ? _CompletionView(attempt: completedAttempt)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
      footer: isCompleted
          ? ModuleContinueButton(
              hasNext: widget.nav.hasNext,
              busy: false,
              onPressed: widget.nav.onAdvance,
            )
          : null,
    );
  }
}

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

class _MatchingGame extends ConsumerStatefulWidget {
  const _MatchingGame({
    required this.attemptId,
    required this.pairs,
    required this.onChecked,
  });

  final String attemptId;
  final List<SimulationMatchingPair> pairs;
  final ValueChanged<SimulationAttempt> onChecked;

  @override
  ConsumerState<_MatchingGame> createState() => _MatchingGameState();
}

class _MatchingGameState extends ConsumerState<_MatchingGame> {
  late final List<SimulationMatchingPair> _rightItems = [...widget.pairs]
    ..shuffle();

  final Set<String> _solved = {};
  String? _selectedLeftId;
  bool _checking = false;

  Future<void> _tryMatch(String rightPairId) async {
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
        for (var i = 0; i < widget.pairs.length; i++) ...[
          _buildPairRow(i, widget.pairs[i], _rightItems[i]),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  Widget _buildPairRow(
    int index,
    SimulationMatchingPair left,
    SimulationMatchingPair right,
  ) {
    final backgroundColor = _matchPairColor(index);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _MatchCard(
              label: left.leftLabel,
              description: left.leftDescription,
              imageUrl: left.leftImageUrl,
              backgroundColor: backgroundColor,
              side: _MatchCardSide.situation,
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
              backgroundColor: backgroundColor,
              side: _MatchCardSide.solution,
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

/// Sisi kartu di satu baris pasangan -- menentukan warna/ikon badge dan arah
/// (foto di kiri untuk situasi, foto di kanan untuk solusi) meniru mockup.
enum _MatchCardSide { situation, solution }

/// Warna latar kartu per pasangan, diulang jika pasangan lebih banyak dari
/// jumlah warna. Kedua kartu (situasi & solusi) dalam satu baris berbagi
/// warna yang sama supaya terasa sepasang, seperti pada mockup desain.
Color _matchPairColor(int index) {
  final colors = [
    AppColors.primarySoft,
    AppColors.warningSoft,
    AppColors.dangerSoft,
    AppColors.successSoft,
  ];
  return colors[index % colors.length];
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({
    required this.label,
    required this.description,
    required this.imageUrl,
    required this.backgroundColor,
    required this.side,
    required this.solved,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String? description;
  final String? imageUrl;
  final Color backgroundColor;
  final _MatchCardSide side;
  final bool solved;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = solved
        ? AppColors.success
        : selected
        ? AppColors.primary
        : AppColors.border;
    final isSituation = side == _MatchCardSide.situation;

    final url = imageUrl;
    final thumbnail = url != null && url.isNotEmpty
        ? _StepThumbnail(imageUrl: url, size: 48)
        : _MatchThumbnailPlaceholder(isSituation: isSituation);

    final content = Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MatchBadge(label: label, isSituation: isSituation),
          if (description case final desc? when desc.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              desc,
              style: AppTypography.bodySmall,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );

    return Opacity(
      opacity: solved ? 0.6 : 1,
      child: Material(
        color: backgroundColor,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(
            color: borderColor,
            width: selected || solved ? 1.6 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: isSituation
                      ? [
                          thumbnail,
                          const SizedBox(width: AppSpacing.sm),
                          content,
                        ]
                      : [
                          content,
                          const SizedBox(width: AppSpacing.sm),
                          thumbnail,
                        ],
                ),
                if (solved)
                  const Positioned(
                    top: -2,
                    right: -2,
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
      ),
    );
  }
}

/// Badge kecil untuk label singkat ("Situasi 1", "Solusi A") -- merah untuk
/// situasi (meniru chip "Skenario N" di mockup), biru untuk solusi.
class _MatchBadge extends StatelessWidget {
  const _MatchBadge({required this.label, required this.isSituation});

  final String label;
  final bool isSituation;

  @override
  Widget build(BuildContext context) {
    final accent = isSituation ? AppColors.danger : AppColors.primary;
    final soft = isSituation ? AppColors.dangerSoft : AppColors.primarySoft;
    final icon = isSituation ? Icons.error_outline : Icons.lightbulb_outline;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: accent),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder saat pasangan belum punya foto -- tetap menjaga lebar kartu
/// konsisten dengan yang sudah ada fotonya.
class _MatchThumbnailPlaceholder extends StatelessWidget {
  const _MatchThumbnailPlaceholder({required this.isSituation});

  final bool isSituation;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      alignment: Alignment.center,
      child: Icon(
        isSituation ? Icons.error_outline : Icons.lightbulb_outline,
        size: 22,
        color: AppColors.inkMuted,
      ),
    );
  }
}

class _OrderingGame extends ConsumerStatefulWidget {
  const _OrderingGame({
    required this.attemptId,
    required this.steps,
    required this.onChecked,
  });

  final String attemptId;
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

  void _placeInNextSlot(SimulationOrderingStep step) {
    if (_checking) return;
    final nextIndex = _placed.indexWhere((s) => s == null);
    if (nextIndex == -1) return;
    _placeInSlot(step, nextIndex);
  }

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

        // Jawaban benar ke-N (N = jumlah langkah) membuat attempt langsung
        // completed di server. Hentikan loop di sini -- sisa langkah di
        // batch ini tidak perlu dicek lagi, dan parent langsung menampilkan
        // layar "Simulasi selesai!" lewat onChecked.
        if (result.attempt.isCompleted) {
          widget.onChecked(result.attempt);
          if (mounted) setState(() => _checking = false);
          return;
        }
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
              Center(
                widthFactor: 1,
                heightFactor: 1,
                child: CircleAvatar(
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
              ),
              const SizedBox(width: AppSpacing.sm),
              if (step?.imageUrl case final url? when url.isNotEmpty) ...[
                _StepThumbnail(imageUrl: url, size: 36),
                const SizedBox(width: AppSpacing.sm),
              ],
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

/// Foto langkah dari backend, dipakai di kartu pool dan slot yang sudah
/// terisi. Fallback ke placeholder kalau gambar gagal dimuat.
class _StepThumbnail extends StatelessWidget {
  const _StepThumbnail({required this.imageUrl, required this.size});

  final String imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Image.network(
        imageUrl,
        width: size,
        height: size,
        cacheWidth: (size * 2).round(),
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _thumbnailPlaceholder(
            size,
            child: const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _thumbnailPlaceholder(
          size,
          child: Icon(
            Icons.image_not_supported_outlined,
            size: size * 0.4,
            color: AppColors.inkMuted,
          ),
        ),
      ),
    );
  }

  Widget _thumbnailPlaceholder(double size, {required Widget child}) {
    return Container(
      width: size,
      height: size,
      color: AppColors.background,
      alignment: Alignment.center,
      child: child,
    );
  }
}
