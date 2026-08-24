import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/sector_storage.dart';

/// Slug sektor yang sudah dipilih pengguna, dibaca dari [SectorStorage].
/// `null` berarti belum pernah memilih -- [AppRoot] memakai ini untuk
/// memutuskan apakah harus menampilkan [SectorSelectionScreen] dulu sebelum
/// masuk ke [MainShell].
final selectedSectorSlugProvider = FutureProvider<String?>((ref) async {
  return ref.watch(sectorStorageProvider).read();
});

/// Menyimpan pilihan sektor lalu memberi tahu [selectedSectorSlugProvider]
/// supaya AppRoot rebuild ke MainShell -- dipanggil dari
/// [SectorSelectionScreen] saat pengguna mengetuk salah satu sektor.
Future<void> selectSector(WidgetRef ref, String slug) async {
  await ref.read(sectorStorageProvider).save(slug);
  ref.invalidate(selectedSectorSlugProvider);
}
