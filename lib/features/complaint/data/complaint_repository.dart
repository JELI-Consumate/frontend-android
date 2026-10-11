import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'models/complaint_agency.dart';

class ComplaintRepository {
  ComplaintRepository(this._dio);

  final Dio _dio;

  Future<List<ComplaintAgency>> agencies() {
    return guardApi(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/complaint-agencies',
      );
      return _list(response.data).map(ComplaintAgency.fromJson).toList();
    });
  }

  Future<ComplaintAgencyDetail> agencyDetail(String slug) {
    return guardApi(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/complaint-agencies/${Uri.encodeComponent(slug)}',
      );
      return ComplaintAgencyDetail.fromJson(requireData(response.data));
    });
  }

  Future<List<ComplaintCategory>> categories() {
    return guardApi(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/complaint-categories',
      );
      return _list(response.data).map(ComplaintCategory.fromJson).toList();
    });
  }

  List<Map<String, dynamic>> _list(Map<String, dynamic>? body) {
    final data = body?['data'];
    if (data is! List) {
      throw const ApiException(message: 'Respons server tidak dikenali.');
    }
    return data.cast<Map<String, dynamic>>();
  }
}

final complaintRepositoryProvider = Provider<ComplaintRepository>((ref) {
  return ComplaintRepository(ref.watch(dioProvider));
});
