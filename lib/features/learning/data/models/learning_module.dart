import 'package:flutter/foundation.dart';

import '../../../../core/models/learning_status.dart';

enum ModuleContentType {
  opening,
  video,
  materi,
  infografis,
  komik,
  kuis,
  simulasi,
  refleksi,
  unknown;

  static ModuleContentType fromJson(Object? value) {
    return ModuleContentType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => ModuleContentType.unknown,
    );
  }
}

@immutable
class LearningModule {
  const LearningModule({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.order,
    required this.estimatedMinutes,
    required this.isRequired,
    required this.progress,
    required this.locked,
    this.pageIds = const [],
  });

  final String id;
  final ModuleContentType type;
  final String title;
  final String? description;
  final int order;
  final int estimatedMinutes;
  final bool isRequired;
  final LearningProgress progress;

  final List<String> pageIds;

  final bool locked;

  LearningModule copyWith({
    String? id,
    ModuleContentType? type,
    String? title,
    String? description,
    int? order,
    int? estimatedMinutes,
    bool? isRequired,
    LearningProgress? progress,
    bool? locked,
    List<String>? pageIds,
  }) {
    return LearningModule(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      order: order ?? this.order,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      isRequired: isRequired ?? this.isRequired,
      progress: progress ?? this.progress,
      locked: locked ?? this.locked,
      pageIds: pageIds ?? this.pageIds,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LearningModule &&
      other.id == id &&
      other.type == type &&
      other.title == title &&
      other.description == description &&
      other.order == order &&
      other.estimatedMinutes == estimatedMinutes &&
      other.isRequired == isRequired &&
      other.progress == progress &&
      other.locked == locked &&
      listEquals(other.pageIds, pageIds);

  @override
  int get hashCode => Object.hash(
    id,
    type,
    title,
    description,
    order,
    estimatedMinutes,
    isRequired,
    progress,
    locked,
    Object.hashAll(pageIds),
  );

  factory LearningModule.fromJson(Map<String, dynamic> json) {
    final rawPages = json['pages'];
    return LearningModule(
      id: json['id'] as String,
      type: ModuleContentType.fromJson(json['type']),
      title: json['title'] as String,
      description: json['description'] as String?,
      order: (json['order'] as num?)?.toInt() ?? 0,
      estimatedMinutes: (json['estimated_minutes'] as num?)?.toInt() ?? 0,
      isRequired: json['is_required'] as bool? ?? true,
      progress: LearningProgress.fromJson(
        json['progress'] as Map<String, dynamic>?,
      ),
      locked: json['locked'] as bool? ?? false,
      pageIds: rawPages is List
          ? rawPages
                .cast<Map<String, dynamic>>()
                .map((page) => page['id'] as String)
                .toList()
          : const [],
    );
  }
}

extension ModuleContentTypeX on ModuleContentType {
  String get shortLabel => switch (this) {
    ModuleContentType.opening => 'Opening',
    ModuleContentType.video => 'Video',
    ModuleContentType.materi => 'Materi',
    ModuleContentType.infografis => 'Infografis',
    ModuleContentType.komik => 'Komik',
    ModuleContentType.kuis => 'Kuis',
    ModuleContentType.simulasi => 'Simulasi',
    ModuleContentType.refleksi => 'Refleksi',
    ModuleContentType.unknown => 'Materi',
  };
}
