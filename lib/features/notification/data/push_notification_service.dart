import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pembungkus tipis di atas `FirebaseMessaging` -- isolasi SDK pihak
/// ketiga di layer data, sama seperti `GoogleAuthService` membungkus
/// `google_sign_in`.
class PushNotificationService {
  PushNotificationService(this._messaging);

  final FirebaseMessaging _messaging;

  /// Wajib diminta eksplisit di Android 13+ (API 33), beda dari Android
  /// lama yang otomatis mengizinkan.
  Future<NotificationSettings> requestPermission() {
    return _messaging.requestPermission(alert: true, badge: true, sound: true);
  }

  /// ID unik per-install-app-per-device. `null` kalau Google Play Services
  /// tidak tersedia (mis. emulator tanpa image Play Store).
  Future<String?> getToken() => _messaging.getToken();

  /// Terbit setiap kali token lama tidak berlaku lagi (uninstall-reinstall,
  /// app data cleared, rotasi internal FCM) dan token baru diterbitkan.
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((
  ref,
) {
  return PushNotificationService(FirebaseMessaging.instance);
});
