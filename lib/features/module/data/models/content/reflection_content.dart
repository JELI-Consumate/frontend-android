import 'package:flutter/foundation.dart';

enum ReflectionQuestionType {
  openQuestion,
  checklist,
  unknown;

  static ReflectionQuestionType fromJson(Object? value) {
    return switch (value) {
      'open_question' => ReflectionQuestionType.openQuestion,
      'checklist' => ReflectionQuestionType.checklist,
      _ => ReflectionQuestionType.unknown,
    };
  }
}

@immutable
class ReflectionChecklistItem {
  const ReflectionChecklistItem({
    required this.id,
    required this.label,
    required this.order,
    required this.isChecked,
  });

  final String id;
  final String label;
  final int order;

  final bool isChecked;

  factory ReflectionChecklistItem.fromJson(Map<String, dynamic> json) {
    return ReflectionChecklistItem(
      id: json['id'] as String,
      label: json['label'] as String,
      order: (json['order'] as num?)?.toInt() ?? 0,
      isChecked: json['is_checked'] as bool? ?? false,
    );
  }
}

@immutable
class ReflectionQuestion {
  const ReflectionQuestion({
    required this.id,
    required this.questionType,
    required this.questionText,
    required this.order,
    required this.answerText,
    required this.checklistItems,
  });

  final String id;
  final ReflectionQuestionType questionType;
  final String questionText;
  final int order;

  final String? answerText;
  final List<ReflectionChecklistItem> checklistItems;

  factory ReflectionQuestion.fromJson(Map<String, dynamic> json) {
    final rawItems = json['checklist_items'];
    return ReflectionQuestion(
      id: json['id'] as String,
      questionType: ReflectionQuestionType.fromJson(json['question_type']),
      questionText: json['question_text'] as String,
      order: (json['order'] as num?)?.toInt() ?? 0,
      answerText: json['answer_text'] as String?,
      checklistItems: rawItems is List
          ? rawItems
                .cast<Map<String, dynamic>>()
                .map(ReflectionChecklistItem.fromJson)
                .toList()
          : const [],
    );
  }
}

@immutable
class ReflectionSection {
  const ReflectionSection({
    required this.id,
    required this.title,
    required this.instruction,
    required this.order,
    required this.questions,
  });

  final String id;
  final String title;
  final String? instruction;
  final int order;
  final List<ReflectionQuestion> questions;

  factory ReflectionSection.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'];
    return ReflectionSection(
      id: json['id'] as String,
      title: json['title'] as String,
      instruction: json['instruction'] as String?,
      order: (json['order'] as num?)?.toInt() ?? 0,
      questions: rawQuestions is List
          ? rawQuestions
                .cast<Map<String, dynamic>>()
                .map(ReflectionQuestion.fromJson)
                .toList()
          : const [],
    );
  }
}

@immutable
class ReflectionContent {
  const ReflectionContent({
    required this.id,
    required this.title,
    required this.openingMessage,
    required this.closingTitle,
    required this.closingMessage,
    required this.sections,
  });

  final String id;
  final String title;
  final String openingMessage;
  final String? closingTitle;
  final String? closingMessage;
  final List<ReflectionSection> sections;

  List<ReflectionQuestion> get openQuestions => sections
      .expand((section) => section.questions)
      .where(
        (question) =>
            question.questionType == ReflectionQuestionType.openQuestion,
      )
      .toList();

  factory ReflectionContent.fromJson(Map<String, dynamic> json) {
    final rawSections = json['sections'];
    return ReflectionContent(
      id: json['id'] as String,
      title: json['title'] as String,
      openingMessage: json['opening_message'] as String? ?? '',
      closingTitle: json['closing_title'] as String?,
      closingMessage: json['closing_message'] as String?,
      sections: rawSections is List
          ? rawSections
                .cast<Map<String, dynamic>>()
                .map(ReflectionSection.fromJson)
                .toList()
          : const [],
    );
  }
}
