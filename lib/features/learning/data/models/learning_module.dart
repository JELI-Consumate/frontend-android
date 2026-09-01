import 'package:flutter/foundation.dart';

import 'learning_status.dart';

/// Cermin dari `ModuleType` enum di backend. Nilai mentahnya (`opening`,
/// `video`, dst.) sudah dalam Bahasa Indonesia, jadi cukup dikapitalkan
/// untuk ditampilkan — lihat [ModuleTypeX.shortLabel].
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

/// Satu langkah di dalam journey (mis. "2. Pentingnya Perlindungan Konsumen
/// dalam E-Commerce" bertipe video). Progress-nya dihitung backend dari
/// seluruh halaman di dalam module ini — lihat catatan di
/// `JourneyController::attachModuleProgress`.
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

  /// Id seluruh halaman (`module_page`) di module ini, urut sesuai
  /// backend -- dipakai untuk mencocokkan `module_page_id` dari
  /// `GET /progress/next` ke module induknya (lihat
  /// `NotificationListenerController`), bukan buat ditampilkan di UI mana
  /// pun sekarang.
  final List<String> pageIds;

  /// true kalau module SEBELUMNYA (order - 1) di journey yang sama belum
  /// completed -- module pertama di journey selalu `false` (lihat
  /// `JourneyController::attachModuleProgress` di backend). Menentukan
  /// apakah baris ini masih bisa disentuh di `ModuleRow`.
  final bool locked;

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
  /// Label pendek Bahasa Indonesia yang ditampilkan di UI, mis. "Video".
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
