import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../learning/application/learning_providers.dart';
import '../data/badge_repository.dart';
import '../data/models/badge.dart';

/// Semua badge milik user yang sedang login, mentah dari `GET /badges` --
/// lintas sektor, badge yang belum diraih tetap ikut.
final badgesProvider = FutureProvider<List<Badge>>((ref) {
  return ref.watch(badgeRepositoryProvider).badges();
});

/// Badge yang journey-nya ada di sektor yang sedang dipilih user (lihat
/// [primarySectorDetailProvider]), diurutkan sesuai urutan journey-nya --
/// ini yang ditampilkan di tab "Pencapaian".
///
/// `BadgeResource` di backend cuma expose `journey_id`, bukan sector_id
/// langsung, jadi pencocokan sektornya dilakukan di sini: cocokkan
/// `journeyId` tiap badge ke daftar journey sektor aktif.
final sectorBadgesProvider = FutureProvider<List<Badge>>((ref) async {
  final badges = await ref.watch(badgesProvider.future);
  final sectorDetail = await ref.watch(primarySectorDetailProvider.future);
  final journeys = sectorDetail?.journeys ?? const [];

  final orderByJourneyId = {
    for (final journey in journeys) journey.id: journey.order,
  };

  final sectorBadges =
      badges
          .where((badge) => orderByJourneyId.containsKey(badge.journeyId))
          .toList()
        ..sort(
          (a, b) => orderByJourneyId[a.journeyId]!.compareTo(
            orderByJourneyId[b.journeyId]!,
          ),
        );

  return sectorBadges;
});
