import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sektor yang sedang dipelajari user pada sesi ini. SENGAJA tidak dipersist:
/// satu user bisa belajar banyak sektor, jadi pilihan sektor bukan setelan
/// permanen device -- tiap kali app dibuka (cold start) atau user login,
/// nilainya kembali `null` dan `AppRoot` menampilkan `SectorSelectionScreen`
/// dulu sebelum `MainShell`. Token auth tetap dipersist terpisah (sesi 30
/// hari), jadi "buka app -> pilih sektor -> Home" tanpa perlu login ulang.
class ActiveSectorNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String slug) => state = slug;

  void clear() => state = null;
}

final activeSectorSlugProvider =
    NotifierProvider<ActiveSectorNotifier, String?>(ActiveSectorNotifier.new);

Future<void> selectSector(WidgetRef ref, String slug) async {
  ref.read(activeSectorSlugProvider.notifier).select(slug);
}
