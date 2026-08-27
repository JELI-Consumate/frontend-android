import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/models/content/simulation_content.dart';
import '../data/models/module_detail.dart';
import '../data/models/module_page.dart';
import '../data/models/simulation_attempt.dart';
import '../data/module_repository.dart';
import 'widgets/module_async_scaffold.dart';
import 'widgets/module_header.dart';

/// Modul tipe `simulasi` -- salah satu dari dua game (lihat
/// [SimulationGameType]). Gaya Duolingo: tiap percobaan dicek satu-satu ke
/// server, jawaban salah tidak disimpan jadi boleh dicoba lagi tanpa
/// menggagalkan attempt-nya (lihat `SimulationScoringService::checkAnswer`
/// di backend). Selesai otomatis begitu seluruh item pernah dijawab benar.
class SimulationModuleScreen extends ConsumerStatefulWidget {
  const SimulationModuleScreen({
    super.key,
    required this.module,
    required this.page,
  });

  final ModuleDetail module;
  final ModulePage page;

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

    return Scaffold(
      appBar: AppBar(title: Text(widget.module.title)),
      body: SafeArea(
        child: completedAttempt != null && completedAttempt.isCompleted
            ? _CompletionView(attempt: completedAttempt)
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                children: [
                  ModuleHeader(module: widget.module),
                  const SizedBox(height: AppSpacing.sm),
                  _ScenarioCard(scenario: _content.scenario),
                  const SizedBox(height: AppSpacing.lg),
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
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({required this.scenario});

  final String scenario;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.theater_comedy_outlined, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(scenario, style: AppTypography.bodyMedium)),
        ],
      ),
    );
  }
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
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: 'Selesai',
          trailingIcon: Icons.check,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

/// Game "pasangkan kartu" -- tap satu kartu kiri lalu satu kartu kanan untuk
/// mencoba mencocokkan. Kolom kanan diacak sendiri di sisi Flutter supaya
/// urutannya tidak otomatis sejajar dengan kolom kiri (backend mengirim
/// keduanya dalam urutan `order` yang sama).
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Belum pas, coba pasangan lain.')),
        );
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  for (final pair in widget.pairs) ...[
                    _MatchTile(
                      label: pair.leftLabel,
                      solved: _solved.contains(pair.id),
                      selected: _selectedLeftId == pair.id,
                      onTap: _solved.contains(pair.id) || _checking
                          ? null
                          : () => setState(
                              () => _selectedLeftId = _selectedLeftId == pair.id
                                  ? null
                                  : pair.id,
                            ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                children: [
                  for (final pair in _rightItems) ...[
                    _MatchTile(
                      label: pair.rightLabel,
                      solved: _solved.contains(pair.id),
                      selected: false,
                      onTap: _solved.contains(pair.id) || _checking
                          ? null
                          : () => _tryMatch(pair.id),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({
    required this.label,
    required this.solved,
    required this.selected,
    required this.onTap,
  });

  final String label;
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
      opacity: solved ? 0.5 : 1,
      child: Material(
        color: selected ? AppColors.primarySoft : AppColors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          side: BorderSide(color: color, width: selected ? 1.4 : 1),
        ),
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                if (solved) ...[
                  const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
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

/// Game "susun urutan" -- posisi kosong SELALU diisi dari yang paling
/// pertama (posisi 1) ke bawah: tap satu kartu dari kolom acak untuk
/// menempatkannya di posisi kosong berikutnya.
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

  Future<void> _tryPlace(SimulationOrderingStep step) async {
    if (_checking) return;
    final nextIndex = _placed.indexWhere((s) => s == null);
    if (nextIndex == -1) return;

    setState(() => _checking = true);
    try {
      final result = await ref
          .read(moduleRepositoryProvider)
          .checkOrderingAnswer(
            attemptId: widget.attemptId,
            stepId: step.id,
            submittedPosition: nextIndex + 1,
          );

      widget.onChecked(result.attempt);

      if (result.correct) {
        setState(() {
          _placed[nextIndex] = step;
          _pool.remove(step);
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Belum di posisi yang tepat, coba langkah lain.'),
          ),
        );
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final placedCount = _placed.where((s) => s != null).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$placedCount/${widget.steps.length} langkah tersusun',
          style: AppTypography.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        for (var i = 0; i < _placed.length; i++) ...[
          _OrderingSlot(position: i + 1, step: _placed[i]),
          const SizedBox(height: AppSpacing.xs),
        ],
        if (_pool.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text('Pilih langkah berikutnya:', style: AppTypography.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final step in _pool)
                _PoolChip(
                  label: step.label,
                  onTap: _checking ? null : () => _tryPlace(step),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _OrderingSlot extends StatelessWidget {
  const _OrderingSlot({required this.position, required this.step});

  final int position;
  final SimulationOrderingStep? step;

  @override
  Widget build(BuildContext context) {
    final filled = step != null;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: filled ? AppColors.successSoft : AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: filled ? AppColors.success : AppColors.border,
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
            child: Text(
              step?.label ?? 'Posisi $position',
              style: AppTypography.bodyMedium.copyWith(
                color: filled ? AppColors.ink : AppColors.inkMuted,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PoolChip extends StatelessWidget {
  const _PoolChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        side: const BorderSide(color: AppColors.primary),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}
