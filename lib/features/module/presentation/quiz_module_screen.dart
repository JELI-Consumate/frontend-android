import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/models/content/quiz_content.dart';
import '../data/models/module_detail.dart';
import '../data/models/module_page.dart';
import '../data/models/quiz_attempt.dart';
import '../data/module_repository.dart';
import 'widgets/module_async_scaffold.dart';
import 'widgets/module_header.dart';

/// Modul tipe `kuis` -- mulai attempt begitu layar dibuka, jawab seluruh
/// segmen (pilihan ganda dan/atau likert), lalu submit sekali untuk lihat
/// skor & pembahasan. Tidak ada batas jumlah percobaan (BR-06 backend) --
/// tiap kali layar ini dibuka, itu attempt baru.
class QuizModuleScreen extends ConsumerStatefulWidget {
  const QuizModuleScreen({super.key, required this.module, required this.page});

  final ModuleDetail module;
  final ModulePage page;

  @override
  ConsumerState<QuizModuleScreen> createState() => _QuizModuleScreenState();
}

class _QuizModuleScreenState extends ConsumerState<QuizModuleScreen> {
  int? _attemptId;
  ApiException? _startError;

  final Map<int, int> _choiceAnswers = {};
  final Map<int, int> _likertAnswers = {};

  bool _submitting = false;
  QuizAttempt? _result;

  QuizContent get _quiz => (widget.page.content as QuizPageContent).content;

  List<QuizQuestion> get _allQuestions =>
      _quiz.segments.expand((segment) => segment.questions).toList();

  bool get _allAnswered => _allQuestions.every(
    (question) =>
        _choiceAnswers.containsKey(question.id) ||
        _likertAnswers.containsKey(question.id),
  );

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      final attemptId = await ref
          .read(moduleRepositoryProvider)
          .startQuizAttempt(_quiz.id);
      if (mounted) setState(() => _attemptId = attemptId);
    } on ApiException catch (error) {
      if (mounted) setState(() => _startError = error);
    }
  }

  Future<void> _submit() async {
    final attemptId = _attemptId;
    if (attemptId == null || !_allAnswered) return;

    setState(() => _submitting = true);
    try {
      final result = await ref
          .read(moduleRepositoryProvider)
          .submitQuizAttempt(
            attemptId: attemptId,
            choiceAnswers: _choiceAnswers,
            likertAnswers: _likertAnswers,
          );
      if (mounted) setState(() => _result = result);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
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
    if (_attemptId == null) return const ModuleLoadingScaffold();

    final result = _result;

    return Scaffold(
      appBar: AppBar(title: Text(widget.module.title)),
      body: SafeArea(
        child: result != null
            ? _QuizResultView(quiz: _quiz, result: result)
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                children: [
                  ModuleHeader(module: widget.module),
                  const SizedBox(height: AppSpacing.lg),
                  for (final segment in [
                    ..._quiz.segments,
                  ]..sort((a, b) => a.order.compareTo(b.order))) ...[
                    _SegmentView(
                      segment: segment,
                      selectedChoice: _choiceAnswers,
                      selectedLikert: _likertAnswers,
                      onChoiceSelected: (questionId, optionId) =>
                          setState(() => _choiceAnswers[questionId] = optionId),
                      onLikertSelected: (questionId, optionId) =>
                          setState(() => _likertAnswers[questionId] = optionId),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  PrimaryButton(
                    label: 'Kumpulkan Jawaban',
                    trailingIcon: Icons.send_outlined,
                    isLoading: _submitting,
                    onPressed: _allAnswered ? _submit : null,
                  ),
                  if (!_allAnswered) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Jawab semua pertanyaan dulu sebelum mengumpulkan.',
                      style: AppTypography.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _SegmentView extends StatelessWidget {
  const _SegmentView({
    required this.segment,
    required this.selectedChoice,
    required this.selectedLikert,
    required this.onChoiceSelected,
    required this.onLikertSelected,
  });

  final QuizSegment segment;
  final Map<int, int> selectedChoice;
  final Map<int, int> selectedLikert;
  final void Function(int questionId, int optionId) onChoiceSelected;
  final void Function(int questionId, int optionId) onLikertSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(segment.title, style: AppTypography.titleLarge),
        if (segment.instruction case final instruction?) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(instruction, style: AppTypography.bodySmall),
        ],
        const SizedBox(height: AppSpacing.sm),
        for (final question in [
          ...segment.questions,
        ]..sort((a, b) => a.order.compareTo(b.order))) ...[
          _QuestionCard(
            question: question,
            segment: segment,
            selectedOptionId: segment.segmentType == QuizSegmentType.likert
                ? selectedLikert[question.id]
                : selectedChoice[question.id],
            onSelected: (optionId) =>
                segment.segmentType == QuizSegmentType.likert
                ? onLikertSelected(question.id, optionId)
                : onChoiceSelected(question.id, optionId),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.segment,
    required this.selectedOptionId,
    required this.onSelected,
  });

  final QuizQuestion question;
  final QuizSegment segment;
  final int? selectedOptionId;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            question.question,
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (segment.segmentType == QuizSegmentType.likert)
            _LikertRow(
              options: segment.likertScaleOptions,
              selectedOptionId: selectedOptionId,
              onSelected: onSelected,
            )
          else
            for (final option in [
              ...question.choiceOptions,
            ]..sort((a, b) => a.order.compareTo(b.order)))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: _ChoiceOptionTile(
                  option: option,
                  selected: selectedOptionId == option.id,
                  onTap: () => onSelected(option.id),
                ),
              ),
        ],
      ),
    );
  }
}

class _ChoiceOptionTile extends StatelessWidget {
  const _ChoiceOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final QuizChoiceOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primarySoft : AppColors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 1.4 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 20,
                color: selected ? AppColors.primary : AppColors.muted,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(option.optionText, style: AppTypography.bodyMedium),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LikertRow extends StatelessWidget {
  const _LikertRow({
    required this.options,
    required this.selectedOptionId,
    required this.onSelected,
  });

  final List<LikertScaleOption> options;
  final int? selectedOptionId;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final sorted = [...options]..sort((a, b) => a.order.compareTo(b.order));

    return Row(
      children: [
        for (final option in sorted)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _LikertOption(
                option: option,
                selected: selectedOptionId == option.id,
                onTap: () => onSelected(option.id),
              ),
            ),
          ),
      ],
    );
  }
}

class _LikertOption extends StatelessWidget {
  const _LikertOption({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final LikertScaleOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.background,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${option.value}',
                style: AppTypography.titleMedium.copyWith(
                  color: selected ? AppColors.white : AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                option.label,
                style: AppTypography.labelSmall.copyWith(
                  color: selected
                      ? AppColors.white.withValues(alpha: 0.85)
                      : AppColors.inkMuted,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuizResultView extends StatelessWidget {
  const _QuizResultView({required this.quiz, required this.result});

  final QuizContent quiz;
  final QuizAttempt result;

  @override
  Widget build(BuildContext context) {
    final passed = result.passed ?? false;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: passed ? AppColors.success : AppColors.danger,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            children: [
              Icon(
                passed ? Icons.emoji_events : Icons.refresh,
                color: AppColors.white,
                size: 40,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                passed ? 'Selamat, kamu lulus!' : 'Belum lulus, coba lagi ya',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              if (result.percentage case final percentage?)
                Text(
                  '$percentage% benar (${result.choiceScore}/${result.choiceMaxScore})',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.white.withValues(alpha: 0.9),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (result.review.isNotEmpty) ...[
          Text('Pembahasan', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final item in result.review) ...[
            _ReviewCard(item: item),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
        const SizedBox(height: AppSpacing.sm),
        PrimaryButton(
          label: 'Selesai',
          trailingIcon: Icons.check,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.item});

  final QuizReviewItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.isCorrect ? AppColors.success : AppColors.danger;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                item.isCorrect ? Icons.check_circle : Icons.cancel,
                color: color,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  item.question,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (item.explanation case final explanation?) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(explanation, style: AppTypography.bodySmall),
          ],
        ],
      ),
    );
  }
}
