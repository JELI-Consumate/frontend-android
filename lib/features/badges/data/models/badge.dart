import 'package:flutter/foundation.dart';

/// Satu lencana, hasil `GET /badges` (lihat `BadgeController::index` +
/// `BadgeResource` di backend). Endpoint itu mengembalikan SEMUA badge yang
/// ada lintas sektor sekaligus, masing-masing dengan status raihan user yang
/// sedang login (`earned`, `earnedAt`) — badge yang belum diraih tetap ikut
/// terkirim (`user_badge` null), bukan cuma yang sudah diraih.
///
/// Nama class-nya `Badge`, bentrok dengan widget `Badge` bawaan
/// `material.dart` — file yang butuh keduanya import material dengan
/// `hide Badge`.
@immutable
class Badge {
  const Badge({
    required this.id,
    required this.journeyId,
    required this.name,
    required this.description,
    required this.congratulationMessage,
    required this.motivationalMessage,
    required this.iconUrl,
    required this.earned,
    required this.earnedAt,
  });

  final int id;

  /// Satu badge terikat ke satu journey (relasi 1-1 di backend). Dipakai
  /// buat mencocokkan badge ke sektor -- lihat `sectorBadgesProvider`.
  final int journeyId;
  final String name;
  final String description;

  /// Pesan ucapan selamat & motivasi yang tampil begitu badge ini diraih
  /// (diisi lewat tab "Badge" di Filament, lihat BadgeRelationManager) --
  /// bisa null untuk badge lama yang belum diisi admin. Cuma masuk akal
  /// ditampilkan kalau [earned], lihat `BadgeDetailSheet`.
  final String? congratulationMessage;
  final String? motivationalMessage;
  final String? iconUrl;
  final bool earned;

  /// Kapan badge ini diraih. Selalu null kalau [earned] false.
  final DateTime? earnedAt;

  factory Badge.fromJson(Map<String, dynamic> json) {
    final rawEarnedAt = json['earned_at'];
    return Badge(
      id: (json['id'] as num).toInt(),
      journeyId: (json['journey_id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      congratulationMessage: json['congratulation_message'] as String?,
      motivationalMessage: json['motivational_message'] as String?,
      iconUrl: json['icon_url'] as String?,
      earned: json['earned'] as bool? ?? false,
      earnedAt: rawEarnedAt is String ? DateTime.tryParse(rawEarnedAt) : null,
    );
  }
}
