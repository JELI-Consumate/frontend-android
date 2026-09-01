import 'package:flutter/foundation.dart';

/// Cermin dari `QuizSegmentType` enum di backend.
enum QuizSegmentType {
  multipleChoice,
  likert,
  unknown;

  static QuizSegmentType fromJson(Object? value) {
    return switch (value) {
      'multiple_choice' => QuizSegmentType.multipleChoice,
      'likert' => QuizSegmentType.likert,
      _ => QuizSegmentType.unknown,
    };
  }
}

@immutable
class QuizChoiceOption {
  const QuizChoiceOption({
    required this.id,
    required this.optionText,
    required this.order,
  });

  final String id;
  final String optionText;
  final int order;

  factory QuizChoiceOption.fromJson(Map<String, dynamic> json) {
    return QuizChoiceOption(
      id: json['id'] as String,
      optionText: json['option_text'] as String,
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }
}

@immutable
class LikertScaleOption {
  const LikertScaleOption({
    required this.id,
    required this.value,
    required this.label,
    required this.order,
  });

  final String id;
  final int value;
  final String label;
  final int order;

  factory LikertScaleOption.fromJson(Map<String, dynamic> json) {
    return LikertScaleOption(
      id: json['id'] as String,
      value: (json['value'] as num).toInt(),
      label: json['label'] as String,
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }
}

@immutable
class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.question,
    required this.order,
    required this.choiceOptions,
  });

  final String id;
  final String question;
  final int order;

  /// Kosong untuk pertanyaan segmen `likert` -- segmen itu pakai
  /// [QuizSegment.likertScaleOptions] bersama (bukan per pertanyaan).
  final List<QuizChoiceOption> choiceOptions;

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['choice_options'];
    return QuizQuestion(
      id: json['id'] as String,
      question: json['question'] as String,
      order: (json['order'] as num?)?.toInt() ?? 0,
      choiceOptions: rawOptions is List
          ? rawOptions
                .cast<Map<String, dynamic>>()
                .map(QuizChoiceOption.fromJson)
                .toList()
          : const [],
    );
  }
}

@immutable
class QuizSegment {
  const QuizSegment({
    required this.id,
    required this.segmentType,
    required this.title,
    required this.instruction,
    required this.order,
    required this.questions,
    required this.likertScaleOptions,
  });

  final String id;
  final QuizSegmentType segmentType;
  final String title;
  final String? instruction;
  final int order;
  final List<QuizQuestion> questions;

  /// Skala jawaban bersama untuk SEMUA pertanyaan di segmen `likert` ini
  /// (mis. "Sangat Tidak Setuju" .. "Sangat Setuju").
  final List<LikertScaleOption> likertScaleOptions;

  factory QuizSegment.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'];
    final rawLikertOptions = json['likert_scale_options'];
    return QuizSegment(
      id: json['id'] as String,
      segmentType: QuizSegmentType.fromJson(json['segment_type']),
      title: json['title'] as String,
      instruction: json['instruction'] as String?,
      order: (json['order'] as num?)?.toInt() ?? 0,
      questions: rawQuestions is List
          ? rawQuestions
                .cast<Map<String, dynamic>>()
                .map(QuizQuestion.fromJson)
                .toList()
          : const [],
      likertScaleOptions: rawLikertOptions is List
          ? rawLikertOptions
                .cast<Map<String, dynamic>>()
                .map(LikertScaleOption.fromJson)
                .toList()
          : const [],
    );
  }
}

/// Konten tipe `quiz` (`ContentableType::Quiz`) -- mode "soal": tidak pernah
/// berisi jawaban benar/salah, itu baru muncul di [QuizAttempt] setelah
/// attempt-nya disubmit (lihat `QuizContentResource` di backend).
@immutable
class QuizContent {
  const QuizContent({
    required this.id,
    required this.passingScore,
    required this.shuffleQuestions,
    required this.segments,
  });

  final String id;
  final int passingScore;
  final bool shuffleQuestions;
  final List<QuizSegment> segments;

  factory QuizContent.fromJson(Map<String, dynamic> json) {
    final rawSegments = json['segments'];
    return QuizContent(
      id: json['id'] as String,
      passingScore: (json['passing_score'] as num?)?.toInt() ?? 70,
      shuffleQuestions: json['shuffle_questions'] as bool? ?? false,
      segments: rawSegments is List
          ? rawSegments
                .cast<Map<String, dynamic>>()
                .map(QuizSegment.fromJson)
                .toList()
          : const [],
    );
  }
}
