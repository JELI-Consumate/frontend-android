import 'package:flutter/foundation.dart';

import 'journey.dart';
import 'sector.dart';

@immutable
class SectorDetail {
  const SectorDetail({required this.sector, required this.journeys});

  final Sector sector;
  final List<Journey> journeys;

  Journey? get inProgressJourney {
    for (final journey in journeys) {
      if (journey.progress.status.isInProgress) return journey;
    }
    return null;
  }

  bool get pretestGateActive {
    final pretest = sector.surveys.pretest;
    if (!pretest.isConfigured || pretest.isCompleted) return false;
    return journeys.every((journey) => journey.progress.status.isNotStarted);
  }

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
