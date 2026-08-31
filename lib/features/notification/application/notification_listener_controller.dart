import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_notification_service.dart';

/// Pasang listener untuk pesan FCM yang datang selagi app hidup --
/// notification payload FCM cuma auto-tampil di tray kalau app
/// background/ketutup, jadi kasus foreground & tap notif harus ditangani
/// manual di sini. Di-attach sekali dari root widget (lihat `AppRoot`).
class NotificationListenerController {
  NotificationListenerController(this._ref);

  final Ref _ref;

  bool _attached = false;

  void attach() {
    if (_attached) return;
    _attached = true;

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTapped);
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _ref.read(localNotificationServiceProvider).show(
      title: notification.title,
      body: notification.body,
    );
  }

  void _onNotificationTapped(RemoteMessage message) {
    // Belum ada rute tujuan spesifik per jenis notifikasi -- baru satu
    // jenis notif yang ada (pengingat inactivity), jadi tap cuma membuka
    // app ke layar defaultnya. Kalau nanti ada jenis notif lain dengan
    // tujuan berbeda, baca `message.data` di sini untuk menentukan rute.
    if (kDebugMode) {
      debugPrint('Notifikasi ditap: ${message.data}');
    }
  }
}

final notificationListenerControllerProvider =
    Provider<NotificationListenerController>((ref) {
      return NotificationListenerController(ref);
    });
