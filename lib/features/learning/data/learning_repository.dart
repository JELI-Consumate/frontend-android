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

  Future<void> completePretestSurvey(String slug) {
    return guardApi(() async {
      await _dio.post<Map<String, dynamic>>(
        '/sectors/$slug/pretest-survey/complete',
      );
    });
  }

  Future<void> completePosttestSurvey(String slug) {
    return guardApi(() async {
      await _dio.post<Map<String, dynamic>>(
        '/sectors/$slug/posttest-survey/complete',
      );
    });
  }

  Future<JourneyDetail> journeyDetail(String journeyId) {
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
