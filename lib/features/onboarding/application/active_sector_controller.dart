import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActiveSectorNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String slug) => state = slug;

  void clear() => state = null;
}

final activeSectorSlugProvider =
    NotifierProvider<ActiveSectorNotifier, String?>(ActiveSectorNotifier.new);
