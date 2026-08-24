import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../onboarding/application/sector_selection_provider.dart';
import '../data/learning_repository.dart';
import '../data/models/sector.dart';
import '../data/models/sector_detail.dart';

/// Daftar seluruh sektor aktif (`GET /sectors`) -- dipakai layar onboarding
/// "Pilih Sektor" untuk pengguna baru. Dashboard/Perjalanan sendiri tidak
/// memakai ini, mereka langsung ke [primarySectorDetailProvider].
final sectorsProvider = FutureProvider<List<Sector>>((ref) {
  return ref.watch(learningRepositoryProvider).sectors();
});

/// Sektor yang dipilih pengguna di layar onboarding "Pilih Sektor" (lihat
/// `SectorSelectionScreen`) — dashboard & tab Perjalanan sama-sama menunjuk
/// ke sini, bukan slug yang di-hardcode.
///
/// Digabung jadi satu provider (bukan dua provider terpisah untuk index dan
/// show) supaya kedua layar yang memakainya berbagi hasil fetch yang sama.
final primarySectorDetailProvider = FutureProvider<SectorDetail?>((ref) async {
  final repository = ref.watch(learningRepositoryProvider);
  final selectedSlug = await ref.watch(selectedSectorSlugProvider.future);

  if (selectedSlug != null) {
    return repository.sectorDetail(selectedSlug);
  }

  // Fallback kalau belum ada sektor tersimpan (mis. sesi lama dari sebelum
  // layar pemilihan sektor ada) -- normalnya AppRoot sudah memaksa memilih
  // dulu sebelum sampai ke sini, jadi ini cuma jaring pengaman.
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
