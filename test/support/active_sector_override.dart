// ignore_for_file: strict_top_level_inference
import 'package:perlindungan_konsumen/features/onboarding/application/active_sector_controller.dart';

/// Sektor aktif sekarang state in-memory (bukan storage) -- lihat
/// `ActiveSectorNotifier`. Helper ini men-seed nilainya di test: `null`
/// (default app: user mendarat di `SectorSelectionScreen` dulu) atau slug
/// tertentu (langsung tembus ke `MainShell`, seperti kebanyakan test yang
/// menguji hal lain).
class _SeededActiveSector extends ActiveSectorNotifier {
  _SeededActiveSector(this._seed);

  final String? _seed;

  @override
  String? build() => _seed;
}

activeSectorOverride([String? slug = 'e-commerce']) =>
    activeSectorSlugProvider.overrideWith(() => _SeededActiveSector(slug));
