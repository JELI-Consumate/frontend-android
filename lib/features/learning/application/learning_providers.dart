import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/learning_repository.dart';
import '../data/models/sector_detail.dart';

/// Sektor "utama" saat ini — backend baru punya satu sektor aktif
/// (`E-Commerce`), jadi dashboard & tab Perjalanan sama-sama menunjuk ke
/// sektor pertama dari `GET /sectors`, bukan slug yang di-hardcode.
///
/// Digabung jadi satu provider (bukan dua provider terpisah untuk index dan
/// show) supaya kedua layar yang memakainya berbagi hasil fetch yang sama.
final primarySectorDetailProvider = FutureProvider<SectorDetail?>((ref) async {
  final repository = ref.watch(learningRepositoryProvider);
  final sectors = await repository.sectors();
  if (sectors.isEmpty) return null;
  return repository.sectorDetail(sectors.first.slug);
});

/// Detail satu journey (termasuk daftar module + progress per module).
/// `autoDispose` karena ini data spesifik satu layar (`JourneyDetailScreen`)
/// yang di-push/pop, bukan state yang perlu bertahan sepanjang sesi seperti
/// [primarySectorDetailProvider].
final journeyDetailProvider = FutureProvider.autoDispose.family((
  ref,
  int journeyId,
) {
  final repository = ref.watch(learningRepositoryProvider);
  return repository.journeyDetail(journeyId);
});
