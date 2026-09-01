import 'package:flutter/foundation.dart';

import 'learning_status.dart';
import 'sector_survey.dart';

/// Satu sektor pembelajaran (mis. "E-Commerce"). Saat ini backend baru
/// punya satu sektor aktif, tapi model ini tetap dibuat generik.
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
