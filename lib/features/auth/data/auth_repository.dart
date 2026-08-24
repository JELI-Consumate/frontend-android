import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import 'models/app_user.dart';

class AuthRepository {
  AuthRepository(this._dio, this._tokenStorage);

  final Dio _dio;
  final TokenStorage _tokenStorage;

  /// Tidak ada token/sesi di sini dengan sengaja — akun baru cuma bisa
  /// dipakai setelah OTP yang baru saja dikirim ke email dikonfirmasi lewat
  /// [verifyOtp]. Pemanggil menavigasi ke layar OTP, bukan menunggu
  /// [authControllerProvider] berubah.
  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    DateTime? dateOfBirth,
  }) {
    return guardApi(() async {
      await _dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          if (dateOfBirth != null) 'date_of_birth': _formatDate(dateOfBirth),
        },
      );
    });
  }

  Future<AppUser> login({required String email, required String password}) {
    return guardApi(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return _consumeAuthResult(response.data);
    });
  }

  Future<AppUser> loginWithGoogle(String accessToken) {
    return guardApi(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/google',
        data: {'access_token': accessToken},
      );
      return _consumeAuthResult(response.data);
    });
  }

  Future<AppUser> me() {
    return guardApi(() async {
      final response = await _dio.get<Map<String, dynamic>>('/auth/me');
      return AppUser.fromJson(_requireData(response.data));
    });
  }

  Future<AppUser> updateProfile({
    String? name,
    String? avatarUrl,
    DateTime? dateOfBirth,
    bool clearAvatar = false,
    bool clearDateOfBirth = false,
  }) {
    return guardApi(() async {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/auth/profile',
        data: {
          'name': ?name,
          'avatar_url': ?avatarUrl,
          if (clearAvatar) 'avatar_url': null,
          if (dateOfBirth != null) 'date_of_birth': _formatDate(dateOfBirth),
          if (clearDateOfBirth) 'date_of_birth': null,
        },
      );
      return AppUser.fromJson(_requireData(response.data));
    });
  }

  Future<void> logout() async {
    try {
      await guardApi(() => _dio.post<Map<String, dynamic>>('/auth/logout'));
    } on ApiException catch (error) {
      if (!error.isUnauthorized) rethrow;
    } finally {
      await _tokenStorage.clear();
    }
  }

  /// Selalu sukses dengan pesan generik ("kalau email terdaftar...") supaya
  /// tidak membocorkan apakah suatu email punya akun.
  Future<String> forgotPassword(String email) {
    return guardApi(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/forgot-password',
        data: {'email': email},
      );
      return _messageOf(response.data) ??
          'Jika email terdaftar, tautan reset kata sandi telah dikirim.';
    });
  }

  /// [token] adalah kode yang dikirim lewat email — pengguna menyalinnya
  /// manual ke aplikasi karena belum ada deep link yang membuka layar ini
  /// langsung dari email.
  Future<String> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) {
    return guardApi(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/reset-password',
        data: {
          'email': email,
          'token': token,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );
      return _messageOf(response.data) ?? 'Kata sandi berhasil direset.';
    });
  }

  /// Endpoint publik — dipakai dari layar OTP (baik saat baru daftar maupun
  /// setelah login gagal karena `EMAIL_NOT_VERIFIED`), jadi tidak butuh
  /// sesi/token sama sekali.
  Future<String> resendOtp(String email) {
    return guardApi(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/verify-email/resend',
        data: {'email': email},
      );
      return _messageOf(response.data) ??
          'Jika email terdaftar dan belum diverifikasi, kode OTP baru telah dikirim.';
    });
  }

  /// Endpoint publik yang mengembalikan token — inilah yang benar-benar
  /// membuat sesi baru untuk akun yang baru saja daftar (atau yang login-nya
  /// ditolak karena `EMAIL_NOT_VERIFIED`).
  Future<AppUser> verifyOtp({required String email, required String otp}) {
    return guardApi(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/verify-email',
        data: {'email': email, 'otp': otp},
      );
      return _consumeAuthResult(response.data);
    });
  }

  Future<String?> readToken() => _tokenStorage.read();

  Future<AppUser> _consumeAuthResult(Map<String, dynamic>? body) async {
    final data = _requireData(body);

    final token = data['token'];
    if (token is! String || token.isEmpty) {
      throw const ApiException(
        message: 'Server tidak mengirim token. Hubungi pengembang.',
      );
    }
    await _tokenStorage.save(token);

    final user = data['user'];
    if (user is! Map<String, dynamic>) {
      throw const ApiException(message: 'Format data pengguna tidak dikenali.');
    }
    return AppUser.fromJson(user);
  }

  Map<String, dynamic> _requireData(Map<String, dynamic>? body) {
    final data = body?['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException(message: 'Respons server tidak dikenali.');
    }
    return data;
  }

  /// Endpoint aksi (forgot/reset password, resend verifikasi) mengirim
  /// `data: null` dan menaruh pesan yang sudah dilokalkan di `meta.message`.
  String? _messageOf(Map<String, dynamic>? body) {
    final meta = body?['meta'];
    if (meta is Map && meta['message'] is String) {
      return meta['message'] as String;
    }
    return null;
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(dioProvider),
    ref.watch(tokenStorageProvider),
  );
});
