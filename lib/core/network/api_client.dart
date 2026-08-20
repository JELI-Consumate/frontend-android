import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// TODO: ganti dengan base URL API sebenarnya (mis. https://api.example.com).
const String kApiBaseUrl = 'https://api.example.com';

/// Dio client tunggal yang dipakai di seluruh aplikasi.
/// Akses lewat `ref.watch(dioProvider)` dari mana saja yang butuh
/// memanggil REST API.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: kApiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // TODO: tambahkan interceptor di sini kalau perlu, misal:
  // - auth token (Authorization header)
  // - logging request/response saat debug
  // dio.interceptors.add(LogInterceptor());

  return dio;
});
