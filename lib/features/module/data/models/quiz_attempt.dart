import 'package:flutter/foundation.dart';

/// Satu baris pembahasan setelah kuis disubmit -- cuma ada di dalam
/// [QuizAttempt.review], tidak pernah muncul sebelum attempt selesai
/// (lihat `QuizAttemptResource` di backend).
@immutable
class QuizReviewItem {
  const QuizReviewItem({
    required this.quizQuestionId,
    required this.question,
    required this.selectedOptionId,
    required this.correctOptionId,
    required this.isCorrect,
    required this.explanation,
  });

  final String quizQuestionId;
  final String question;
  final String selectedOptionId;
  final String? correctOptionId;
  final bool isCorrect;
  final String? explanation;

  factory QuizReviewItem.fromJson(Map<String, dynamic> json) {
    return QuizReviewItem(
      quizQuestionId: json['quiz_question_id'] as String,
      question: json['question'] as String,
      selectedOptionId: json['selected_option_id'] as String,
      correctOptionId: json['correct_option_id'] as String?,
      isCorrect: json['is_correct'] as bool? ?? false,
      explanation: json['explanation'] as String?,
    );
  }
}

/// Hasil `POST /quiz-attempts/{id}/submit` (atau `GET /quiz-attempts/{id}`)
/// -- attempt kuis yang SUDAH disubmit, lengkap dengan skor & pembahasan.
/// `passed` menandai lulus/tidaknya, tapi TIDAK menghalangi module selesai --
/// backend menandai halaman selesai begitu attempt disubmit, apapun hasilnya
/// (lihat `QuizScoringService::submit`).
@immutable
class QuizAttempt {
  const QuizAttempt({
    required this.attemptId,
    required this.quizContentId,
    required this.attemptNumber,
    required this.choiceScore,
    required this.choiceMaxScore,
    required this.percentage,
    required this.passed,
    required this.likertAverage,
    required this.review,
  });

  final String attemptId;
  final String quizContentId;
  final int attemptNumber;
  final int? choiceScore;
  final int? choiceMaxScore;
  final int? percentage;
  final bool? passed;
  final double? likertAverage;
  final List<QuizReviewItem> review;

  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    final rawReview = json['review'];
    return QuizAttempt(
      attemptId: json['attempt_id'] as String,
      quizContentId: json['quiz_content_id'] as String,
      attemptNumber: (json['attempt_number'] as num?)?.toInt() ?? 1,
      choiceScore: (json['choice_score'] as num?)?.toInt(),
      choiceMaxScore: (json['choice_max_score'] as num?)?.toInt(),
      percentage: (json['percentage'] as num?)?.toInt(),
      passed: json['passed'] as bool?,
      likertAverage: (json['likert_average'] as num?)?.toDouble(),
      review: rawReview is List
          ? rawReview
                .cast<Map<String, dynamic>>()
                .map(QuizReviewItem.fromJson)
                .toList()
          : const [],
    );
  }
}

/// Hasil satu panggilan `POST /quiz-attempts/{id}/check` -- gaya ujian, BEDA
/// dari `SimulationCheckResult`: jawaban salah TETAP disimpan (soal langsung
/// terkunci untuk attempt ini), bukan ditolak-boleh-coba-lagi.
///
/// [correct]/[correctOptionId]/[explanation] semuanya `null` untuk
/// pertanyaan segmen likert -- tidak ada benar/salah di situ. [attempt]
/// selalu snapshot TERBARU seluruh attempt -- begitu SEMUA pertanyaan sudah
/// dicek, `attempt.review` sudah lengkap tanpa perlu panggilan submit
/// terpisah lagi (lihat `QuizAttempt.review`).
@immutable
class QuizAnswerCheckResult {
  const QuizAnswerCheckResult({
    required this.correct,
    required this.correctOptionId,
    required this.explanation,
    required this.attempt,
  });

  final bool? correct;
  final String? correctOptionId;
  final String? explanation;
  final QuizAttempt attempt;

  factory QuizAnswerCheckResult.fromJson(Map<String, dynamic> json) {
    return QuizAnswerCheckResult(
      correct: json['correct'] as bool?,
      correctOptionId: json['correct_option_id'] as String?,
      explanation: json['explanation'] as String?,
      attempt: QuizAttempt.fromJson(json['attempt'] as Map<String, dynamic>),
    );
  }
}
