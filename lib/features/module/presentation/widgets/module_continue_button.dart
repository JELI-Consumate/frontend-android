import 'package:flutter/material.dart';

import '../../../../core/widgets/primary_button.dart';

/// Tombol gabungan "Tandai Selesai" + "Lanjut" -- SATU tombol untuk kelima
/// tipe konten, dipasang di [ModuleBottomBar]. Cara "selesai"-nya beda-beda
/// per tipe konten (lihat masing-masing layar: `completeModulePage` manual
/// buat video/artikel, submit attempt buat kuis/simulasi/refleksi), tapi
/// begitu beres, tombol inilah yang SELALU membawa ke halaman/module
/// berikutnya lewat `ModulePageNav.onAdvance` -- dulu ini 2 tombol terpisah.
class ModuleContinueButton extends StatelessWidget {
  const ModuleContinueButton({
    super.key,
    required this.hasNext,
    required this.busy,
    required this.onPressed,
  });

  /// true kalau masih ada halaman/module berikutnya -- label & ikonnya jadi
  /// "Selanjutnya" (panah), kalau tidak jadi "Selesai" (centang) karena ini
  /// akhir journey-nya.
  final bool hasNext;

  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      label: hasNext ? 'Selanjutnya' : 'Selesai',
      trailingIcon: hasNext ? Icons.arrow_forward : Icons.check,
      isLoading: busy,
      onPressed: onPressed,
    );
  }
}
