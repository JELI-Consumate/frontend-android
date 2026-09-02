import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

class DeviceTokenRepository {
  DeviceTokenRepository(this._dio);

  final Dio _dio;

  Future<void> register(String fcmToken) {
    return guardApi(() async {
      await _dio.post<Map<String, dynamic>>(
        '/device-tokens',
        data: {'fcm_token': fcmToken, 'platform': 'android'},
      );
    });
  }
}

final deviceTokenRepositoryProvider = Provider<DeviceTokenRepository>((ref) {
  return DeviceTokenRepository(ref.watch(dioProvider));
});
