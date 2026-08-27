import 'package:perlindungan_konsumen/core/network/api_exception.dart';
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
  FakeModuleRepository({Map<int, ModuleDetail>? modules})
    : modules = modules ?? {};

  final Map<int, ModuleDetail> modules;
  ApiException? failWith;

  final List<String> calls = [];

  // --- Kuis: journey_id 1 -> kuis id 100, 2 soal pilihan ganda (option
  // pertama tiap soal "benar") + 1 soal likert (semua opsi "benar" secara
  // definisi -- likert tidak ada benar/salah). ---
  static const correctChoiceOptionByQuestion = {201: 301, 202: 304};
  static const likertOptionValue = {401: 1, 402: 2, 403: 3, 404: 4, 405: 5};
  int quizAttemptCounter = 0;

  // --- Simulasi ordering: langkah id 601..603 -> posisi benar 1,2,3. ---
  static const correctOrderingPosition = {601: 1, 602: 2, 603: 3};
  int simulationAttemptCounter = 0;
  final Set<int> _matchingSolved = {};
  final Set<int> _orderingSolved = {};

  ReflectionContent? reflectionFixture;

  @override
  Future<ModuleDetail> module(int moduleId) async {
    calls.add('module($moduleId)');
    if (failWith != null) throw failWith!;
    final module = modules[moduleId];
    if (module == null) {
      throw const ApiException(message: 'Modul tidak ditemukan.');
    }
    return module;
  }

  @override
  Future<void> completeModulePage(int modulePageId) async {
    calls.add('completeModulePage($modulePageId)');
    if (failWith != null) throw failWith!;
  }

  @override
  Future<int> startQuizAttempt(int quizContentId) async {
    calls.add('startQuizAttempt($quizContentId)');
    if (failWith != null) throw failWith!;
    quizAttemptCounter++;
    return quizAttemptCounter;
  }

  @override
  Future<QuizAttempt> submitQuizAttempt({
    required int attemptId,
    required Map<int, int> choiceAnswers,
    required Map<int, int> likertAnswers,
  }) async {
    calls.add('submitQuizAttempt($attemptId)');
    if (failWith != null) throw failWith!;

    var score = 0;
    final review = <QuizReviewItem>[];
    for (final entry in choiceAnswers.entries) {
      final correctOptionId = correctChoiceOptionByQuestion[entry.key];
      final isCorrect = correctOptionId == entry.value;
      if (isCorrect) score++;
      review.add(
        QuizReviewItem(
          quizQuestionId: entry.key,
          question: 'Soal ${entry.key}',
          selectedOptionId: entry.value,
          correctOptionId: correctOptionId,
          isCorrect: isCorrect,
          explanation: isCorrect ? null : 'Penjelasan soal ${entry.key}.',
        ),
      );
    }

    final maxScore = choiceAnswers.length;
    final percentage = maxScore > 0 ? (score * 100) ~/ maxScore : 0;

    final likertValues = likertAnswers.values
        .map((optionId) => likertOptionValue[optionId] ?? 0)
        .toList();
    final likertAverage = likertValues.isEmpty
        ? null
        : likertValues.reduce((a, b) => a + b) / likertValues.length;

    return QuizAttempt(
      attemptId: attemptId,
      quizContentId: 100,
      attemptNumber: attemptId,
      choiceScore: score,
      choiceMaxScore: maxScore,
      percentage: percentage,
      passed: percentage >= 70,
      likertAverage: likertAverage,
      review: review,
    );
  }

  @override
  Future<int> startSimulationAttempt(int simulationContentId) async {
    calls.add('startSimulationAttempt($simulationContentId)');
    if (failWith != null) throw failWith!;
    simulationAttemptCounter++;
    _matchingSolved.clear();
    _orderingSolved.clear();
    return simulationAttemptCounter;
  }

  @override
  Future<SimulationCheckResult> checkMatchingAnswer({
    required int attemptId,
    required int pairId,
    required int submittedRightPairId,
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
    required int attemptId,
    required int stepId,
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
    int attemptId, {
    required int totalMatching,
    required int totalOrdering,
  }) {
    final totalItems = totalMatching + totalOrdering;
    final answeredItems = _matchingSolved.length + _orderingSolved.length;
    final isCompleted = totalItems > 0 && answeredItems >= totalItems;

    return SimulationAttempt(
      attemptId: attemptId,
      simulationContentId: 500,
      score: isCompleted ? totalItems : null,
      maxScore: isCompleted ? totalItems : null,
      isPassed: isCompleted ? true : null,
      isCompleted: isCompleted,
      matchingReview: const [],
      orderingReview: const [],
    );
  }

  @override
  Future<ReflectionContent> reflection(int reflectionContentId) async {
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
    required int reflectionContentId,
    required Map<int, String> answers,
    required Map<int, bool> checklistAnswers,
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
