import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/module_repository.dart';
import '../data/models/module_detail.dart';

final moduleDetailProvider = FutureProvider.autoDispose
    .family<ModuleDetail, String>((ref, moduleId) {
      return ref.watch(moduleRepositoryProvider).module(moduleId);
    });
