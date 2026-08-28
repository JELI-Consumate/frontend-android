import 'package:flutter/foundation.dart';

/// Info navigasi seragam yang dibutuhkan kelima layar konsumsi konten --
/// dibuat sekali per halaman oleh `_ModuleContentRouter` (lihat
/// `module_screen.dart`) dan diteruskan sebagai satu parameter `nav`, supaya
/// konstruktor tiap layar tidak dibanjiri banyak parameter individual.
@immutable
class ModulePageNav {
  const ModulePageNav({
    this.modulePosition,
    this.moduleTotal,
    required this.pageCount,
    required this.pageIndex,
    this.onDotTap,
    required this.hasNext,
    required this.onAdvance,
  });

  /// Nav default buat kasus paling umum: module 1 halaman, dibuka tanpa
  /// konteks journey (mis. dites langsung tanpa lewat `ModuleScreen`).
  /// `onAdvance` default tidak melakukan apa pun.
  factory ModulePageNav.single({VoidCallback? onAdvance}) {
    return ModulePageNav(
      pageCount: 1,
      pageIndex: 0,
      hasNext: false,
      onAdvance: onAdvance ?? _noop,
    );
  }

  static void _noop() {}

  /// Posisi module ini di antara seluruh module journey-nya (1-based) --
  /// dipakai badge "Modul X/Y" di [ModuleTopBar]. `null` kalau module ini
  /// dibuka tanpa konteks journey.
  final int? modulePosition;
  final int? moduleTotal;

  /// Jumlah & indeks (0-based) halaman dalam MODULE ini (beda dari
  /// `modulePosition` yang soal posisi antar-MODULE) -- dipakai indikator
  /// titik di [ModuleBottomBar]. `pageCount == 1` artinya tidak ada indikator
  /// sama sekali.
  final int pageCount;
  final int pageIndex;
  final ValueChanged<int>? onDotTap;

  /// true kalau masih ada halaman berikutnya dalam module ini ATAU module
  /// berikutnya di journey -- menentukan label tombol gabungan ("Selanjutnya"
  /// vs "Selesai", lihat [ModuleContinueButton]).
  final bool hasNext;

  /// Dipanggil begitu halaman ini beres (ditandai selesai / attempt selesai /
  /// refleksi lengkap tersimpan) DAN tombol gabungan ditekan -- pindah ke
  /// halaman berikutnya dalam module ini, atau ke module berikutnya di
  /// journey, atau kembali ke layar sebelumnya kalau ini akhir journey.
  /// Dulu ini 2 tombol terpisah ("Tandai Selesai" di dalam tiap layar +
  /// "Modul Selanjutnya" di footer luar) -- sekarang cuma 1 aksi.
  final VoidCallback onAdvance;
}
