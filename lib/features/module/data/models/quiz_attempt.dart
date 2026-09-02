import 'package:flutter/foundation.dart';

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
