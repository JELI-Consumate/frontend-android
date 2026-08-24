import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'models/journey_detail.dart';
import 'models/sector.dart';
import 'models/sector_detail.dart';

class LearningRepository {
  LearningRepository(this._dio);

  final Dio _dio;

  /// Backend baru punya satu sektor aktif, tapi endpoint ini tetap dipanggil
  /// (bukan slug yang di-hardcode) supaya kalau nanti nambah sektor lagi,
  /// Flutter tidak perlu diubah.
  Future<List<Sector>> sectors() {
    return guardApi(() async {
      final response = await _dio.get<Map<String, dynamic>>('/sectors');
      final data = response.data?['data'];
      if (data is! List) {
        throw const ApiException(message: 'Respons server tidak dikenali.');
      }
      return data.cast<Map<String, dynamic>>().map(Sector.fromJson).toList();
    });
  }

  Future<SectorDetail> sectorDetail(String slug) {
    return guardApi(() async {
      final response = await _dio.get<Map<String, dynamic>>('/sectors/$slug');
      return SectorDetail.fromJson(_requireData(response.data));
    });
  }

  Future<JourneyDetail> journeyDetail(int journeyId) {
    return guardApi(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/journeys/$journeyId',
      );
      return JourneyDetail.fromJson(_requireData(response.data));
    });
  }

  Map<String, dynamic> _requireData(Map<String, dynamic>? body) {
    final data = body?['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException(message: 'Respons server tidak dikenali.');
    }
    return data;
  }
}

final learningRepositoryProvider = Provider<LearningRepository>((ref) {
  return LearningRepository(ref.watch(dioProvider));
});
