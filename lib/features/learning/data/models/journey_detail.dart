import 'package:flutter/foundation.dart';

import 'journey.dart';
import 'learning_module.dart';

/// [Journey] lengkap dengan daftar module-nya — hasil `GET /journeys/{id}`.
@immutable
class JourneyDetail {
  const JourneyDetail({required this.journey, required this.modules});

  final Journey journey;
  final List<LearningModule> modules;

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
    );
  }
}
