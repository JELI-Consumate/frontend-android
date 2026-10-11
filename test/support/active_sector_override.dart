import 'package:flutter_riverpod/misc.dart' show Override;

import 'package:consumate/features/onboarding/application/active_sector_controller.dart';

class _SeededActiveSector extends ActiveSectorNotifier {
  _SeededActiveSector(this._seed);

  final String? _seed;

  @override
  String? build() => _seed;
}

Override activeSectorOverride([String? slug = 'e-commerce']) =>
    activeSectorSlugProvider.overrideWith(() => _SeededActiveSector(slug));
