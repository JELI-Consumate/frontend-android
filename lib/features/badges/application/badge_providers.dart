import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/badge_repository.dart';
import '../data/models/badge.dart';

final badgesProvider = FutureProvider<List<Badge>>((ref) {
  return ref.watch(badgeRepositoryProvider).badges();
});
