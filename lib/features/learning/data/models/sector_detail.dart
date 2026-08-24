import 'package:flutter/foundation.dart';

import 'journey.dart';
import 'sector.dart';

/// [Sector] lengkap dengan daftar journey-nya — hasil `GET /sectors/{slug}`.
@immutable
class SectorDetail {
  const SectorDetail({required this.sector, required this.journeys});

  final Sector sector;
  final List<Journey> journeys;

  /// Journey pertama yang sedang dikerjakan (belum selesai, sudah dimulai).
  /// Sumber utama kartu "Lanjutkan Belajar" di dashboard. `null` kalau
  /// belum ada journey yang dimulai sama sekali.
  Journey? get inProgressJourney {
    for (final journey in journeys) {
      if (journey.progress.status.isInProgress) return journey;
    }
    return null;
  }

  /// Journey pertama yang terbuka dan belum selesai — fallback saat belum
  /// ada progress sama sekali, dipakai untuk kartu ringkasan "Perjalanan"
  /// di dashboard.
  Journey? get nextJourney {
    for (final journey in journeys) {
      if (journey.isUnlocked && !journey.progress.status.isCompleted) {
        return journey;
      }
    }
    return journeys.isEmpty ? null : journeys.first;
  }

  factory SectorDetail.fromJson(Map<String, dynamic> json) {
    final rawJourneys = json['journeys'];
    return SectorDetail(
      sector: Sector.fromJson(json),
      journeys: rawJourneys is List
          ? rawJourneys
                .cast<Map<String, dynamic>>()
                .map(Journey.fromJson)
                .toList()
          : const [],
    );
  }
}
