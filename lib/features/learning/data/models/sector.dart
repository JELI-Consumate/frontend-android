import 'package:flutter/foundation.dart';

import '../../../../core/models/learning_status.dart';
import 'sector_survey.dart';

@immutable
class Sector {
  const Sector({
    required this.id,
    required this.slug,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.color,
    required this.order,
    required this.progress,
    this.surveys = SectorSurveys.empty,
  });

  final String id;
  final String slug;
  final String name;
  final String? description;
  final String? iconUrl;
  final String? color;
  final int order;
  final LearningProgress progress;
  final SectorSurveys surveys;

  Sector copyWith({
    String? id,
    String? slug,
    String? name,
    String? description,
    String? iconUrl,
    String? color,
    int? order,
    LearningProgress? progress,
    SectorSurveys? surveys,
  }) {
    return Sector(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      name: name ?? this.name,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      color: color ?? this.color,
      order: order ?? this.order,
      progress: progress ?? this.progress,
      surveys: surveys ?? this.surveys,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Sector &&
      other.id == id &&
      other.slug == slug &&
      other.name == name &&
      other.description == description &&
      other.iconUrl == iconUrl &&
      other.color == color &&
      other.order == order &&
      other.progress == progress &&
      other.surveys == surveys;

  @override
  int get hashCode => Object.hash(
    id,
    slug,
    name,
    description,
    iconUrl,
    color,
    order,
    progress,
    surveys,
  );

  factory Sector.fromJson(Map<String, dynamic> json) {
    return Sector(
      id: json['id'] as String,
      slug: json['slug'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      iconUrl: json['icon_url'] as String?,
      color: json['color'] as String?,
      order: (json['order'] as num?)?.toInt() ?? 0,
      progress: LearningProgress.fromJson(
        json['progress'] as Map<String, dynamic>?,
      ),
      surveys: SectorSurveys.fromJson(json['surveys'] as Map<String, dynamic>?),
    );
  }
}
