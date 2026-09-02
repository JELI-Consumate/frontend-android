import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/sector_storage.dart';

final selectedSectorSlugProvider = FutureProvider<String?>((ref) async {
  return ref.watch(sectorStorageProvider).read();
});

Future<void> selectSector(WidgetRef ref, String slug) async {
  await ref.read(sectorStorageProvider).save(slug);
  ref.invalidate(selectedSectorSlugProvider);
}
