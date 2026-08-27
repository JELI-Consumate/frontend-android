import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'models/badge.dart';

class BadgeRepository {
  BadgeRepository(this._dio);

  final Dio _dio;

  /// `GET /badges` -- semua badge lintas sektor, masing-masing dengan status
  /// raihan user yang sedang login. Tidak ada parameter sektor di endpoint
  /// ini (lihat `BadgeController::index`); pencocokan ke sektor dilakukan
  /// di Flutter, lihat `sectorBadgesProvider`.
  Future<List<Badge>> badges() {
    return guardApi(() async {
      final response = await _dio.get<Map<String, dynamic>>('/badges');
      final data = response.data?['data'];
      if (data is! List) {
        throw const ApiException(message: 'Respons server tidak dikenali.');
      }
      return data.cast<Map<String, dynamic>>().map(Badge.fromJson).toList();
    });
  }
}

final badgeRepositoryProvider = Provider<BadgeRepository>((ref) {
  return BadgeRepository(ref.watch(dioProvider));
});
