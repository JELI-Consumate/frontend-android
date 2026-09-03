import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/app_alert_dialog.dart';
import '../../data/module_repository.dart';
import 'module_page_nav.dart';

/// Perilaku "tandai halaman selesai lalu lanjut" yang identik di layar module
/// artikel & video. Layar cukup `with ModulePageAdvance`, pakai [isAdvancing]
/// untuk state tombol, dan panggil [completeAndAdvance] saat tombol ditekan.
mixin ModulePageAdvance<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool _advancing = false;

  bool get isAdvancing => _advancing;

  /// Kalau [alreadyComplete] `false`, tandai halaman [pageId] selesai di server
  /// dulu; kalau gagal, tampilkan alert dan JANGAN lanjut. Setelah sukses (atau
  /// kalau memang sudah selesai) panggil [onCompleted] lalu `nav.onAdvance()`.
  Future<void> completeAndAdvance({
    required String pageId,
    required bool alreadyComplete,
    required ModulePageNav nav,
    VoidCallback? onCompleted,
  }) async {
    if (!alreadyComplete) {
      setState(() => _advancing = true);
      final ok = await _completePage(pageId);
      if (mounted) setState(() => _advancing = false);
      if (!ok || !mounted) return;
      onCompleted?.call();
    }
    nav.onAdvance();
  }

  Future<bool> _completePage(String pageId) async {
    try {
      await ref.read(moduleRepositoryProvider).completeModulePage(pageId);
      return true;
    } on ApiException catch (error) {
      if (mounted) {
        showAppAlert(
          context,
          type: AppAlertType.error,
          title: 'Gagal Menandai Selesai',
          message: error.message,
        );
      }
      return false;
    }
  }
}
