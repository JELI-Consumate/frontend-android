import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Kunci navigator top-level -- dipasang di `MaterialApp` (lihat
/// `main.dart`). Dibutuhkan untuk push halaman dari luar widget tree, mis.
/// dari `NotificationListenerController` saat notifikasi ditap, di mana
/// tidak ada `BuildContext` layar yang bisa dipakai.
final navigatorKeyProvider = Provider<GlobalKey<NavigatorState>>((ref) {
  return GlobalKey<NavigatorState>();
});
