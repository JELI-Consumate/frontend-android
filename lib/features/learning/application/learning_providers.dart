import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../onboarding/application/sector_selection_provider.dart';
import '../data/learning_repository.dart';
import '../data/models/sector.dart';
import '../data/models/sector_detail.dart';

final sectorsProvider = FutureProvider<List<Sector>>((ref) {
  return ref.watch(learningRepositoryProvider).sectors();
});

final primarySectorDetailProvider = FutureProvider<SectorDetail?>((ref) async {
  final repository = ref.watch(learningRepositoryProvider);
  final selectedSlug = await ref.watch(selectedSectorSlugProvider.future);

  if (selectedSlug != null) {
    return repository.sectorDetail(selectedSlug);
  }

  final sectors = await repository.sectors();
  if (sectors.isEmpty) return null;
  return repository.sectorDetail(sectors.first.slug);
});

final journeyDetailProvider = FutureProvider.autoDispose.family((
  ref,
  String journeyId,
) {
  final repository = ref.watch(learningRepositoryProvider);
  return repository.journeyDetail(journeyId);
});
