import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_alert_dialog.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/models/content/quiz_content.dart';
import '../data/models/module_detail.dart';
import '../data/models/module_page.dart';
import '../data/models/quiz_attempt.dart';
import '../data/module_repository.dart';
import 'widgets/module_async_scaffold.dart';
import 'widgets/module_bottom_bar.dart';
import 'widgets/module_continue_button.dart';
import 'widgets/module_page_nav.dart';
import 'widgets/module_top_bar.dart';

/// Modul tipe `kuis` -- mulai attempt begitu layar dibuka, jawab SATU
/// pertanyaan per halaman (lintas segmen pilihan ganda maupun likert,
/// diflatten & diurutkan lewat `_flatQuestions`). BEDA dari sebelumnya:
/// setiap pertanyaan pilihan ganda dicek SATU PER SATU begitu tombol
/// ditekan (lihat `_onPrimaryPressed`) -- jawaban benar/salah langsung
/// diberi umpan balik + pembahasan sebelum lanjut ke pertanyaan berikutnya,
/// bukan menunggu submit di akhir. Attempt otomatis selesai (dan halaman
/// module ditandai selesai) begitu SELURUH pertanyaan sudah pernah dicek --
/// lihat `QuizScoringService::checkAnswer` di backend. Tidak ada batas
/// jumlah percobaan (BR-06 backend) -- tiap kali layar ini dibuka, itu
/// attempt baru.
class QuizModuleScreen extends ConsumerStatefulWidget {
  const QuizModuleScreen({
    super.key,
    required this.module,
    required this.page,
    required this.nav,
  });

  final ModuleDetail module;
  final ModulePage page;
  final ModulePageNav nav;

  @override
  ConsumerState<QuizModuleScreen> createState() => _QuizModuleScreenState();
}

class _QuizModuleScreenState extends ConsumerState<QuizModuleScreen> {
  String? _attemptId;
  ApiException? _startError;

  final Map<String, String> _choiceAnswers = {};
  final Map<String, String> _likertAnswers = {};

  /// Hasil cek per pertanyaan (keyed by quiz_question_id) -- SEKALI
  /// pertanyaan tercatat di sini, tampilannya terkunci ke umpan balik
  /// (benar/salah + pembahasan), tidak bisa jawab ulang. Pertanyaan likert
  /// juga masuk sini (cuma buat menandai "sudah dicek", `correct`-nya
  /// selalu null -- lihat `QuizAnswerCheckResult`).
  final Map<String, QuizAnswerCheckResult> _checkedResults = {};

  bool _checking = false;
  QuizAttempt? _result;

  /// Indeks pertanyaan yang lagi tampil (flat, lintas segmen).
  int _questionIndex = 0;

  QuizContent get _quiz => (widget.page.content as QuizPageContent).content;

  /// Pasangan (segment, question) terurut sesuai `order` masing-masing --
  /// dasar navigasi 1-pertanyaan-1-halaman di `build`.
  List<(QuizSegment, QuizQuestion)> get _flatQuestions => [
    for (final segment in [
      ..._quiz.segments,
    ]..sort((a, b) => a.order.compareTo(b.order)))
      for (final question in [
        ...segment.questions,
      ]..sort((a, b) => a.order.compareTo(b.order)))
        (segment, question),
  ];

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

  Future<void> _checkCurrent(QuizSegment segment, QuizQuestion question) async {
    final attemptId = _attemptId;
    if (attemptId == null) return;

    setState(() => _checking = true);
    try {
      final result = await ref
          .read(moduleRepositoryProvider)
          .checkQuizAnswer(
            attemptId: attemptId,
            questionId: question.id,
            type: segment.segmentType,
            choiceOptionId: _choiceAnswers[question.id],
            likertOptionId: _likertAnswers[question.id],
          );
      if (mounted) {
        setState(() => _checkedResults[question.id] = result);
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

  void _advance(int totalQuestions, QuizAttempt latestAttempt) {
    if (_questionIndex < totalQuestions - 1) {
      setState(() => _questionIndex++);
      return;
    }
    // Sudah pertanyaan terakhir -- attempt-nya sendiri otomatis sudah
    // completed di respons check barusan (lihat backend), jadi tinggal
    // tampilkan hasilnya, tidak perlu panggilan submit terpisah lagi.
    setState(() => _result = latestAttempt);
  }

  /// Tombol utama berperan ganda: kalau pertanyaan saat ini BELUM dicek,
  /// menekannya memicu pengecekan (dan untuk pilihan ganda, BERHENTI di situ
  /// dulu supaya umpan balik benar/salah + pembahasan sempat terlihat).
  /// Kalau SUDAH dicek (atau segmennya likert, yang tidak ada umpan balik
  /// buat ditampilkan), langsung lanjut ke pertanyaan berikutnya.
  Future<void> _onPrimaryPressed(
    QuizSegment segment,
    QuizQuestion question,
    int totalQuestions,
  ) async {
    final existing = _checkedResults[question.id];
    if (existing == null) {
      await _checkCurrent(segment, question);
      if (!mounted) return;
      final justChecked = _checkedResults[question.id];
      if (justChecked != null &&
          segment.segmentType == QuizSegmentType.likert) {
        _advance(totalQuestions, justChecked.attempt);
      }
      return;
    }
    _advance(totalQuestions, existing.attempt);
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
    final flatQuestions = _flatQuestions;
    final questionIndex = _questionIndex.clamp(0, flatQuestions.length - 1);
    final isLastQuestion = questionIndex == flatQuestions.length - 1;
    final (currentSegment, currentQuestion) = flatQuestions[questionIndex];
    final checked = _checkedResults[currentQuestion.id];
    final selected = currentSegment.segmentType == QuizSegmentType.likert
        ? _likertAnswers[currentQuestion.id]
        : _choiceAnswers[currentQuestion.id];

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: ModuleTopBar(
        position: widget.nav.modulePosition,
        total: widget.nav.moduleTotal,
      ),
      body: SafeArea(
        bottom: false,
        child: result != null
            ? _QuizResultView(quiz: _quiz, result: result)
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  key: ValueKey(currentQuestion.id),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _QuestionProgress(
                      current: questionIndex + 1,
                      total: flatQuestions.length,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      currentQuestion.question,
                      style: AppTypography.bodyLarge,
                      textAlign: TextAlign.justify,
                    ),
                    if (currentSegment.instruction case final instruction?) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(instruction, style: AppTypography.bodySmall),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    if (checked != null &&
                        currentSegment.segmentType != QuizSegmentType.likert)
                      _AnswerFeedback(
                        result: checked,
                        question: currentQuestion,
                      )
                    else if (currentSegment.segmentType ==
                        QuizSegmentType.likert)
                      _LikertRow(
                        options: currentSegment.likertScaleOptions,
                        selectedOptionId: selected,
                        onSelected: (optionId) => setState(
                          () => _likertAnswers[currentQuestion.id] = optionId,
                        ),
                      )
                    else
                      for (final option in [
                        ...currentQuestion.choiceOptions,
                      ]..sort((a, b) => a.order.compareTo(b.order)))
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _ChoiceOptionTile(
                            letter: String.fromCharCode(
                              65 +
                                  currentQuestion.choiceOptions.indexOf(option),
                            ),
                            option: option,
                            selected: selected == option.id,
                            onTap: () => setState(
                              () => _choiceAnswers[currentQuestion.id] =
                                  option.id,
                            ),
                          ),
                        ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: ModuleBottomBar(
        pageCount: widget.nav.pageCount,
        pageIndex: widget.nav.pageIndex,
        onDotTap: widget.nav.onDotTap,
        child: result != null
            ? ModuleContinueButton(
                hasNext: widget.nav.hasNext,
                busy: false,
                onPressed: widget.nav.onAdvance,
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PrimaryButton(
                    label: checked != null && isLastQuestion
                        ? 'Lihat Hasil'
                        : 'Lanjut ke Pertanyaan Berikutnya',
                    trailingIcon: Icons.arrow_forward,
                    isLoading: _checking,
                    onPressed: selected == null
                        ? null
                        : () => _onPrimaryPressed(
                            currentSegment,
                            currentQuestion,
                            flatQuestions.length,
                          ),
                  ),
                  if (selected == null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Pilih salah satu jawaban dulu sebelum lanjut.',
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

/// "PERTANYAAN X DARI Y" + persentase, lalu bar tipis di bawahnya.
class _QuestionProgress extends StatelessWidget {
  const _QuestionProgress({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0 : ((current / total) * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'PERTANYAAN $current DARI $total',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.inkMuted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            Text(
              '$percent%',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : current / total,
            minHeight: 6,
            backgroundColor: AppColors.primarySoft,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class _ChoiceOptionTile extends StatelessWidget {
  const _ChoiceOptionTile({
    required this.letter,
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final String letter;
  final QuizChoiceOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textStyle = AppTypography.bodyMedium.copyWith(
      color: selected ? AppColors.primary : AppColors.ink,
      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
    );

    // Tinggi kotak dipatok dari kasus TERPANJANG (teks opsi 2 baris) supaya
    // seluruh opsi (A/B/C/D) sama tinggi -- teksnya sendiri dibiarkan
    // setinggi aslinya lalu di-tengahkan lewat `Row` yang center secara
    // vertikal (default), sama seperti pola di `ModuleRow`.
    final rowHeight = (textStyle.fontSize ?? 14) * (textStyle.height ?? 1) * 2;

    return Material(
      // Kebalikan dari sebelumnya: opsi yang BELUM dipilih justru diberi
      // warna latar lembut (`background`), yang SEDANG dipilih putih bersih
      // dengan tepi biru menonjol -- supaya opsi terpilih yang paling
      // menarik perhatian, bukan sebaliknya.
      color: selected ? AppColors.white : AppColors.background,
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
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: SizedBox(
            height: rowHeight,
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : AppColors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Text(
                    letter,
                    style: AppTypography.labelMedium.copyWith(
                      color: selected ? AppColors.white : AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    option.optionText,
                    style: textStyle,
                    maxLines: 2,
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

/// Kartu umpan balik benar/salah + pembahasan -- muncul menggantikan daftar
/// opsi begitu satu pertanyaan pilihan ganda selesai dicek.
class _AnswerFeedback extends StatelessWidget {
  const _AnswerFeedback({required this.result, required this.question});

  final QuizAnswerCheckResult result;
  final QuizQuestion question;

  @override
  Widget build(BuildContext context) {
    final correct = result.correct ?? false;
    final color = correct ? AppColors.success : AppColors.danger;
    final softColor = correct ? AppColors.successSoft : AppColors.dangerSoft;

    final sortedOptions = [...question.choiceOptions]
      ..sort((a, b) => a.order.compareTo(b.order));
    final correctOption = sortedOptions.firstWhereOrNullId(
      result.correctOptionId,
    );
    final correctIndex = correctOption == null
        ? -1
        : sortedOptions.indexOf(correctOption);
    final correctLetter = correctIndex == -1
        ? null
        : String.fromCharCode(65 + correctIndex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: softColor,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color,
                child: Icon(
                  correct ? Icons.check : Icons.close,
                  color: AppColors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                correct ? 'Jawabanmu benar!' : 'Jawabanmu belum tepat.',
                style: AppTypography.titleLarge.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              if (!correct &&
                  correctLetter != null &&
                  correctOption != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Jawaban yang benar adalah $correctLetter. '
                  '${correctOption.optionText}',
                  style: AppTypography.bodyMedium.copyWith(color: color),
                  textAlign: TextAlign.justify,
                ),
              ],
            ],
          ),
        ),
        if (result.explanation case final explanation?
            when explanation.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            'PEMBAHASAN',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              explanation,
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.justify,
            ),
          ),
        ],
      ],
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
  final String? selectedOptionId;
  final ValueChanged<String> onSelected;

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

extension _FirstWhereOrNullId on List<QuizChoiceOption> {
  QuizChoiceOption? firstWhereOrNullId(String? id) {
    if (id == null) return null;
    for (final option in this) {
      if (option.id == id) return option;
    }
    return null;
  }
}
