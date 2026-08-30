import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Index tab bawah yang sedang aktif di `MainShell` -- di-lift ke provider
/// (bukan `State` lokal di `MainShell`) supaya layar yang di-push jauh di
/// atasnya (mis. `JourneyCelebrationScreen`, lewat tombol "Kembali ke
/// Beranda") bisa memaksa pindah tab tanpa butuh referensi langsung ke
/// widget `MainShell`-nya. Riverpod 3 sudah tidak punya `StateProvider`
/// bawaan lagi, jadi ini `Notifier` sinkron biasa yang isinya cuma satu int.
class MainTabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final mainTabIndexProvider = NotifierProvider<MainTabIndexNotifier, int>(
  MainTabIndexNotifier.new,
);
