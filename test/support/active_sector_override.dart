
import 'package:perlindungan_konsumen/features/onboarding/application/active_sector_controller.dart';

class _SeededActiveSector extends ActiveSectorNotifier {
  _SeededActiveSector(this._seed);

  final String? _seed;

  @override
  String? build() => _seed;
}

activeSectorOverride([String? slug = 'e-commerce']) =>
    activeSectorSlugProvider.overrideWith(() => _SeededActiveSector(slug));
