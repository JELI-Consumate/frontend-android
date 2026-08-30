import 'package:flutter/foundation.dart';

import 'journey.dart';
import 'learning_module.dart';

/// [Journey] lengkap dengan daftar module-nya — hasil `GET /journeys/{id}`.
@immutable
class JourneyDetail {
  const JourneyDetail({
    required this.journey,
    required this.modules,
    this.quizScore,
  });

  final Journey journey;
  final List<LearningModule> modules;

  /// Skor kuis evaluasi journey ini dalam persen (0-100), dari attempt
  /// TERAKHIR user -- `null` kalau journey ini tidak punya module kuis, atau
  /// belum pernah diselesaikan sama sekali. Dipakai kartu "Ringkasan
  /// Journey" di [JourneyCelebrationScreen] begitu journey selesai.
  final int? quizScore;

  int get completedModuleCount =>
      modules.where((module) => module.progress.status.isCompleted).length;

  /// Module pertama yang belum selesai — ini yang ditandai "sedang
  /// dikerjakan" di checklist, dan sumber "lanjutkan belajar" di dashboard.
  /// `null` kalau seluruh module sudah selesai.
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
