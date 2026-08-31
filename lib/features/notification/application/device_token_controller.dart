import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/device_token_repository.dart';
import '../data/push_notification_service.dart';

/// Sinkronisasi token FCM device ini ke backend. Dipanggil dari
/// `AuthController` tiap kali sesi baru terbentuk (login, login Google,
/// verifikasi OTP) -- lihat auth_controller.dart.
class DeviceTokenController {
  DeviceTokenController(this._ref);

  final Ref _ref;

  bool _refreshListenerAttached = false;

  /// Minta izin notifikasi, ambil token FCM device, lalu daftarkan ke
  /// backend. Gagal secara diam-diam (di luar debug log) -- device yang
  /// belum terdaftar cuma berarti user itu tidak kebagian notif
  /// inactivity, bukan alasan untuk menggagalkan login.
  Future<void> registerCurrentDevice() async {
    final service = _ref.read(pushNotificationServiceProvider);
    _attachRefreshListener(service);

    try {
      await service.requestPermission();
      final token = await service.getToken();
      if (token == null) return;
      await _ref.read(deviceTokenRepositoryProvider).register(token);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('DeviceTokenController.registerCurrentDevice gagal: $error');
      }
    }
  }

  void _attachRefreshListener(PushNotificationService service) {
    if (_refreshListenerAttached) return;
    _refreshListenerAttached = true;

    service.onTokenRefresh.listen((newToken) async {
      try {
        await _ref.read(deviceTokenRepositoryProvider).register(newToken);
      } catch (error) {
        if (kDebugMode) {
          debugPrint('DeviceTokenController.onTokenRefresh gagal: $error');
        }
      }
    });
  }
}

final deviceTokenControllerProvider = Provider<DeviceTokenController>((ref) {
  return DeviceTokenController(ref);
});
