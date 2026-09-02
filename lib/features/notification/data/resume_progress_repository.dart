import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'models/next_progress.dart';

class ResumeProgressRepository {
  ResumeProgressRepository(this._dio);

  final Dio _dio;

  Future<NextProgress> next() {
    return guardApi(() async {
      final response = await _dio.get<Map<String, dynamic>>('/progress/next');
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw const ApiException(message: 'Respons server tidak dikenali.');
      }
      return NextProgress.fromJson(data);
    });
  }
}

final resumeProgressRepositoryProvider = Provider<ResumeProgressRepository>((
  ref,
) {
  return ResumeProgressRepository(ref.watch(dioProvider));
});
