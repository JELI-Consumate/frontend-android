import 'package:flutter/foundation.dart';

import '../../../learning/data/models/learning_module.dart';
import 'module_page.dart';

/// [Module] lengkap dengan halaman + kontennya -- hasil `GET /modules/{id}`.
/// Dipakai layar konsumsi konten (`ModuleScreen`), beda dari
/// `LearningModule` di fitur learning yang cuma dipakai checklist journey
/// (ringan, tanpa isi konten).
@immutable
class ModuleDetail {
  const ModuleDetail({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.estimatedMinutes,
    required this.pages,
  });

  final String id;
  final ModuleContentType type;
  final String title;
  final String? description;
  final int estimatedMinutes;
  final List<ModulePage> pages;

  /// Modul saat ini selalu tepat satu halaman (lihat `ModuleSeeder` di
  /// backend) -- `null` cuma jaring pengaman kalau suatu saat kosong.
  ModulePage? get firstPage => pages.isEmpty ? null : pages.first;

  factory ModuleDetail.fromJson(Map<String, dynamic> json) {
    final rawPages = json['pages'];
    return ModuleDetail(
      id: json['id'] as String,
      type: ModuleContentType.fromJson(json['type']),
      title: json['title'] as String,
      description: json['description'] as String?,
      estimatedMinutes: (json['estimated_minutes'] as num?)?.toInt() ?? 0,
      pages: rawPages is List
          ? rawPages
                .cast<Map<String, dynamic>>()
                .map(ModulePage.fromJson)
                .toList()
          : const [],
    );
  }
}
