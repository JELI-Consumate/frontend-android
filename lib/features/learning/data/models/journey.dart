import 'package:flutter/foundation.dart';

import 'learning_status.dart';

/// Representasi ringan journey, dipakai di dalam daftar sektor
/// (`GET /sectors/{slug}`). Tanpa daftar module — lihat [JourneyDetail].
@immutable
class Journey {
  const Journey({
    required this.id,
    required this.slug,
    required this.title,
    required this.description,
    required this.order,
    required this.estimatedMinutes,
    required this.isUnlocked,
    required this.modulesCount,
    required this.progress,
  });

  final int id;
  final String slug;
  final String title;
  final String? description;
  final int order;
  final int estimatedMinutes;
  final bool isUnlocked;
  final int modulesCount;
  final LearningProgress progress;

  factory Journey.fromJson(Map<String, dynamic> json) {
    return Journey(
      id: (json['id'] as num).toInt(),
      slug: json['slug'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      order: (json['order'] as num?)?.toInt() ?? 0,
      estimatedMinutes: (json['estimated_minutes'] as num?)?.toInt() ?? 0,
      isUnlocked: json['is_unlocked'] as bool? ?? false,
      modulesCount: (json['modules_count'] as num?)?.toInt() ?? 0,
      progress: LearningProgress.fromJson(
        json['progress'] as Map<String, dynamic>?,
      ),
    );
  }
}
