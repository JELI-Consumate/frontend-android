import 'package:perlindungan_konsumen/core/network/api_exception.dart';
import 'package:perlindungan_konsumen/features/module/data/models/content/quiz_content.dart';
import 'package:perlindungan_konsumen/features/module/data/models/content/reflection_content.dart';
import 'package:perlindungan_konsumen/features/module/data/models/module_detail.dart';
import 'package:perlindungan_konsumen/features/module/data/models/quiz_attempt.dart';
import 'package:perlindungan_konsumen/features/module/data/models/simulation_attempt.dart';
import 'package:perlindungan_konsumen/features/module/data/module_repository.dart';

/// Fixture disusun langsung dari bentuk resource backend (`ModuleResource`,
/// `ModulePageResource`, dan resource per tipe konten di
/// `App\Http\Resources\V1\Content`) -- bukan hasil `curl` sungguhan seperti
/// `FakeLearningRepository`, karena fitur ini dikerjakan tanpa server
/// backend yang jalan. Skor kuis/simulasi dihitung manual di sini meniru
/// `QuizScoringService`/`SimulationScoringService` (lihat konstanta
/// `correctChoiceOptionId`/`correctPosition...` di bawah), bukan hardcode
/// satu hasil tetap -- supaya test bisa menjawab benar/salah dan lihat
/// hasilnya beda.
class FakeModuleRepository implements ModuleRepository {
  FakeModuleRepository({Map<String, ModuleDetail>? modules, this.onComplete})
    : modules = modules ?? {};

  final Map<String, ModuleDetail> modules;
  ApiException? failWith;

  /// Dipanggil begitu [completeModulePage] sukses -- test yang perlu
  /// mensimulasikan efek sampingnya di sisi server (mis. journey jadi
  /// completed di `FakeLearningRepository`, lihat
  /// `journey_celebration_flow_test.dart`) taruh mutasinya di sini alih-alih
  /// bikin fake ini tahu soal fake lain secara langsung.
  final void Function(String modulePageId)? onComplete;

  final List<String> calls = [];

  // --- Kuis: journey_id 1 -> kuis id 100, 2 soal pilihan ganda (option
  // pertama tiap soal "benar") + 1 soal likert (semua opsi "benar" secara
  // definisi -- likert tidak ada benar/salah). ---
  static const correctChoiceOptionByQuestion = {'201': '301', '202': '304'};
  static const likertOptionValue = {
    '401': 1,
    '402': 2,
    '403': 3,
    '404': 4,
    '405': 5,
  };
  static const totalQuizQuestions = 3; // 201, 202 (choice) + 203 (likert)
  int quizAttemptCounter = 0;
  final Map<String, String> _quizChoiceAnswers = {};
  final Map<String, bool> _quizChoiceCorrectness = {};
  final Map<String, String> _quizLikertAnswers = {};

  // --- Simulasi ordering: langkah id 601..603 -> posisi benar 1,2,3. ---
  static const correctOrderingPosition = {'601': 1, '602': 2, '603': 3};
  int simulationAttemptCounter = 0;
  final Set<String> _matchingSolved = {};
  final Set<String> _orderingSolved = {};

  ReflectionContent? reflectionFixture;

  @override
  Future<ModuleDetail> module(String moduleId) async {
    calls.add('module($moduleId)');
    if (failWith != null) throw failWith!;
    final module = modules[moduleId];
    if (module == null) {
      throw const ApiException(message: 'Modul tidak ditemukan.');
    }
    return module;
  }

  @override
  Future<void> completeModulePage(String modulePageId) async {
    calls.add('completeModulePage($modulePageId)');
    if (failWith != null) throw failWith!;
    onComplete?.call(modulePageId);
  }

  @override
  Future<String> startQuizAttempt(String quizContentId) async {
    calls.add('startQuizAttempt($quizContentId)');
    if (failWith != null) throw failWith!;
    quizAttemptCounter++;
    _quizChoiceAnswers.clear();
    _quizChoiceCorrectness.clear();
    _quizLikertAnswers.clear();
    return '$quizAttemptCounter';
  }

  /// Meniru `QuizScoringService::checkAnswer` -- gaya ujian: soal pilihan
  /// ganda yang SUDAH pernah dicek terkunci ke hasil PERTAMA kali tersimpan
  /// (jawaban baru yang dikirim diabaikan), beda dari simulasi yang boleh
  /// dicoba lagi. `review` di [QuizAttempt] cuma terisi begitu SEMUA
  /// pertanyaan (choice + likert) sudah pernah dicek.
  @override
  Future<QuizAnswerCheckResult> checkQuizAnswer({
    required String attemptId,
    required String questionId,
    required QuizSegmentType type,
    String? choiceOptionId,
    String? likertOptionId,
  }) async {
    calls.add('checkQuizAnswer($attemptId, $questionId)');
    if (failWith != null) throw failWith!;

    bool? correct;
    String? correctOptionId;
    String? explanation;

    if (type == QuizSegmentType.likert) {
      _quizLikertAnswers.putIfAbsent(questionId, () => likertOptionId!);
    } else {
      correctOptionId = correctChoiceOptionByQuestion[questionId];
      explanation = 'Penjelasan soal $questionId.';

      if (_quizChoiceAnswers.containsKey(questionId)) {
        correct = _quizChoiceCorrectness[questionId];
      } else {
        correct = correctOptionId == choiceOptionId;
        _quizChoiceAnswers[questionId] = choiceOptionId!;
        _quizChoiceCorrectness[questionId] = correct;
      }
    }

    final answeredCount = _quizChoiceAnswers.length + _quizLikertAnswers.length;
    final isCompleted = answeredCount >= totalQuizQuestions;

    final choiceScore = _quizChoiceCorrectness.values.where((v) => v).length;
    final choiceMaxScore = _quizChoiceAnswers.length;
    final percentage = isCompleted && choiceMaxScore > 0
        ? (choiceScore * 100) ~/ choiceMaxScore
        : null;

    final likertValues = _quizLikertAnswers.values
        .map((optionId) => likertOptionValue[optionId] ?? 0)
        .toList();
    final likertAverage = isCompleted && likertValues.isNotEmpty
        ? likertValues.reduce((a, b) => a + b) / likertValues.length
        : null;

    final review = isCompleted
        ? [
            for (final entry in _quizChoiceAnswers.entries)
              QuizReviewItem(
                quizQuestionId: entry.key,
                question: 'Soal ${entry.key}',
                selectedOptionId: entry.value,
                correctOptionId: correctChoiceOptionByQuestion[entry.key],
                isCorrect: _quizChoiceCorrectness[entry.key] ?? false,
                explanation: 'Penjelasan soal ${entry.key}.',
              ),
          ]
        : const <QuizReviewItem>[];

    return QuizAnswerCheckResult(
      correct: correct,
      correctOptionId: correctOptionId,
      explanation: explanation,
      attempt: QuizAttempt(
        attemptId: attemptId,
        quizContentId: '100',
        attemptNumber: int.parse(attemptId),
        choiceScore: isCompleted ? choiceScore : null,
        choiceMaxScore: isCompleted ? choiceMaxScore : null,
        percentage: percentage,
        passed: isCompleted && percentage != null ? percentage >= 70 : null,
        likertAverage: likertAverage,
        review: review,
      ),
    );
  }

  @override
  Future<String> startSimulationAttempt(String simulationContentId) async {
    calls.add('startSimulationAttempt($simulationContentId)');
    if (failWith != null) throw failWith!;
    simulationAttemptCounter++;
    _matchingSolved.clear();
    _orderingSolved.clear();
    return '$simulationAttemptCounter';
  }

  @override
  Future<SimulationCheckResult> checkMatchingAnswer({
    required String attemptId,
    required String pairId,
    required String submittedRightPairId,
  }) async {
    calls.add(
      'checkMatchingAnswer($attemptId, $pairId, $submittedRightPairId)',
    );
    if (failWith != null) throw failWith!;

    final correct = pairId == submittedRightPairId;
    if (correct) _matchingSolved.add(pairId);

    return SimulationCheckResult(
      correct: correct,
      attempt: _simulationAttemptSnapshot(
        attemptId,
        totalMatching: 2,
        totalOrdering: 0,
      ),
    );
  }

  @override
  Future<SimulationCheckResult> checkOrderingAnswer({
    required String attemptId,
    required String stepId,
    required int submittedPosition,
  }) async {
    calls.add('checkOrderingAnswer($attemptId, $stepId, $submittedPosition)');
    if (failWith != null) throw failWith!;

    final correct = correctOrderingPosition[stepId] == submittedPosition;
    if (correct) _orderingSolved.add(stepId);

    return SimulationCheckResult(
      correct: correct,
      attempt: _simulationAttemptSnapshot(
        attemptId,
        totalMatching: 0,
        totalOrdering: correctOrderingPosition.length,
      ),
    );
  }

  SimulationAttempt _simulationAttemptSnapshot(
    String attemptId, {
    required int totalMatching,
    required int totalOrdering,
  }) {
    final totalItems = totalMatching + totalOrdering;
    final answeredItems = _matchingSolved.length + _orderingSolved.length;
    final isCompleted = totalItems > 0 && answeredItems >= totalItems;

    return SimulationAttempt(
      attemptId: attemptId,
      simulationContentId: '500',
      score: isCompleted ? totalItems : null,
      maxScore: isCompleted ? totalItems : null,
      isPassed: isCompleted ? true : null,
      isCompleted: isCompleted,
      matchingReview: const [],
      orderingReview: const [],
    );
  }

  @override
  Future<ReflectionContent> reflection(String reflectionContentId) async {
    calls.add('reflection($reflectionContentId)');
    if (failWith != null) throw failWith!;
    final fixture = reflectionFixture;
    if (fixture == null) {
      throw const ApiException(message: 'Refleksi tidak ditemukan.');
    }
    return fixture;
  }

  @override
  Future<ReflectionContent> saveReflectionEntries({
    required String reflectionContentId,
    required Map<String, String> answers,
    required Map<String, bool> checklistAnswers,
  }) async {
    calls.add('saveReflectionEntries($reflectionContentId)');
    if (failWith != null) throw failWith!;

    final fixture = reflectionFixture!;
    final updated = ReflectionContent(
      id: fixture.id,
      title: fixture.title,
      openingMessage: fixture.openingMessage,
      closingTitle: fixture.closingTitle,
      closingMessage: fixture.closingMessage,
      sections: [
        for (final section in fixture.sections)
          ReflectionSection(
            id: section.id,
            title: section.title,
            instruction: section.instruction,
            order: section.order,
            questions: [
              for (final question in section.questions)
                ReflectionQuestion(
                  id: question.id,
                  questionType: question.questionType,
                  questionText: question.questionText,
                  order: question.order,
                  answerText: answers[question.id] ?? question.answerText,
                  checklistItems: [
                    for (final item in question.checklistItems)
                      ReflectionChecklistItem(
                        id: item.id,
                        label: item.label,
                        order: item.order,
                        isChecked: checklistAnswers[item.id] ?? item.isChecked,
                      ),
                  ],
                ),
            ],
          ),
      ],
    );
    reflectionFixture = updated;
    return updated;
  }
}
