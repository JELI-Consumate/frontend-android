import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

/// Contoh repository yang memanggil REST API lewat [dioProvider].
///
/// Ganti method di bawah ini dengan endpoint sungguhan sesuai backend,
/// dan sesuaikan return type-nya dengan model data masing-masing fitur.
class HomeRepository {
  HomeRepository(this._dio);

  final Dio _dio;

  /// TODO: ganti '/example-endpoint' dengan endpoint yang sebenarnya,
  /// dan parse response.data ke model yang sesuai.
  Future<List<dynamic>> fetchItems() async {
    final response = await _dio.get<List<dynamic>>('/example-endpoint');
    return response.data ?? [];
  }
}

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(ref.watch(dioProvider));
});
