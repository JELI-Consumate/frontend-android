import 'package:flutter/foundation.dart';

import 'journey.dart';
import 'learning_module.dart';

@immutable
class JourneyDetail {
  const JourneyDetail({
    required this.journey,
    required this.modules,
    this.quizScore,
  });

  final Journey journey;
  final List<LearningModule> modules;

  final int? quizScore;

  int get completedModuleCount =>
      modules.where((module) => module.progress.status.isCompleted).length;

  LearningModule? get currentModule {
    for (final module in modules) {
      if (!module.progress.status.isCompleted) return module;
    }
    return null;
  }

  factory JourneyDetail.fromJson(Map<String, dynamic> json) {
    final rawModules = json['modules'];
    return JourneyDetail(
      journey: Journey.fromJson(json),
      modules: rawModules is List
          ? rawModules
                .cast<Map<String, dynamic>>()
                .map(LearningModule.fromJson)
                .toList()
          : const [],
      quizScore: (json['quiz_score'] as num?)?.toInt(),
    );
  }
}
