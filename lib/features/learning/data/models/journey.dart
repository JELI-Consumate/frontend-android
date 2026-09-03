import 'package:flutter/foundation.dart';

import '../../../../core/models/learning_status.dart';

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
    this.imageUrl,
  });

  final String id;
  final String slug;
  final String title;
  final String? description;
  final String? imageUrl;
  final int order;
  final int estimatedMinutes;
  final bool isUnlocked;
  final int modulesCount;
  final LearningProgress progress;

  Journey copyWith({
    String? id,
    String? slug,
    String? title,
    String? description,
    String? imageUrl,
    int? order,
    int? estimatedMinutes,
    bool? isUnlocked,
    int? modulesCount,
    LearningProgress? progress,
  }) {
    return Journey(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      order: order ?? this.order,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      modulesCount: modulesCount ?? this.modulesCount,
      progress: progress ?? this.progress,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Journey &&
      other.id == id &&
      other.slug == slug &&
      other.title == title &&
      other.description == description &&
      other.imageUrl == imageUrl &&
      other.order == order &&
      other.estimatedMinutes == estimatedMinutes &&
      other.isUnlocked == isUnlocked &&
      other.modulesCount == modulesCount &&
      other.progress == progress;

  @override
  int get hashCode => Object.hash(
    id,
    slug,
    title,
    description,
    imageUrl,
    order,
    estimatedMinutes,
    isUnlocked,
    modulesCount,
    progress,
  );

  factory Journey.fromJson(Map<String, dynamic> json) {
    return Journey(
      id: json['id'] as String,
      slug: json['slug'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
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
