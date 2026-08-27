import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/module_repository.dart';
import '../data/models/module_detail.dart';

/// Detail satu module (halaman + konten) -- `autoDispose` karena ini data
/// spesifik satu layar (`ModuleScreen`) yang di-push/pop, sama seperti
/// `journeyDetailProvider` di fitur learning.
final moduleDetailProvider = FutureProvider.autoDispose
    .family<ModuleDetail, int>((ref, moduleId) {
      return ref.watch(moduleRepositoryProvider).module(moduleId);
    });
