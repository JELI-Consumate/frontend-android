import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../learning/application/learning_providers.dart';
import '../data/badge_repository.dart';
import '../data/models/badge.dart';

final badgesProvider = FutureProvider<List<Badge>>((ref) {
  return ref.watch(badgeRepositoryProvider).badges();
});

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
