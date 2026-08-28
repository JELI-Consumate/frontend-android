import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.fieldErrors = const {},
  });

  final String message;
  final int? statusCode;
  final String? code;
  final Map<String, List<String>> fieldErrors;

  bool get isUnauthorized => statusCode == 401;
  bool get isValidation => statusCode == 422;
  bool get isThrottled => statusCode == 429;
  bool get isGoogleOnlyAccount => code == 'GOOGLE_ONLY_ACCOUNT';
  bool get isInvalidCredentials => code == 'INVALID_CREDENTIALS';
  bool get isEmailNotVerified => code == 'EMAIL_NOT_VERIFIED';
  bool get isInvalidResetOtp => code == 'INVALID_RESET_OTP';
  bool get isInvalidOtp => code == 'INVALID_OTP';

  String? firstErrorFor(String field) => fieldErrors[field]?.firstOrNull;

  factory ApiException.fromDio(DioException error) {
    final response = error.response;

    if (response == null) {
      return ApiException(message: _networkMessage(error.type));
    }

    final body = response.data;
    if (body is! Map) {
      return ApiException(
        message: _statusMessage(response.statusCode),
        statusCode: response.statusCode,
      );
    }

    final rawErrors = body['errors'];
    final fieldErrors = <String, List<String>>{};
    if (rawErrors is Map) {
      rawErrors.forEach((key, value) {
        if (value is List) {
          fieldErrors['$key'] = value.map((e) => '$e').toList();
        } else if (value != null) {
          fieldErrors['$key'] = ['$value'];
        }
      });
    }

    final message = body['message'];

    return ApiException(
      message: message is String && message.isNotEmpty
          ? message
          : _statusMessage(response.statusCode),
      statusCode: response.statusCode,
      code: body['code'] as String?,
      fieldErrors: fieldErrors,
    );
  }

  static String _networkMessage(DioExceptionType type) {
    return switch (type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'Koneksi timeout. Periksa jaringanmu lalu coba lagi.',
      DioExceptionType.connectionError =>
        'Tidak bisa terhubung ke server. Periksa koneksi internetmu.',
      DioExceptionType.cancel => 'Permintaan dibatalkan.',
      _ => 'Terjadi kesalahan tak terduga. Coba lagi sebentar.',
    };
  }

  static String _statusMessage(int? status) {
    return switch (status) {
      401 => 'Sesi kamu sudah berakhir. Silakan masuk lagi.',
      403 => 'Kamu tidak punya akses ke sumber daya ini.',
      404 => 'Data yang diminta tidak ditemukan.',
      429 => 'Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi.',
      final int code when code >= 500 =>
        'Server sedang bermasalah. Coba lagi nanti.',
      _ => 'Terjadi kesalahan. Coba lagi sebentar.',
    };
  }

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}

Future<T> guardApi<T>(Future<T> Function() request) async {
  try {
    return await request();
  } on DioException catch (error) {
    throw ApiException.fromDio(error);
  }
}
