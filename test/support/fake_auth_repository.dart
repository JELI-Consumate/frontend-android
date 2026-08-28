import 'package:perlindungan_konsumen/core/network/api_exception.dart';
import 'package:perlindungan_konsumen/features/auth/data/auth_repository.dart';
import 'package:perlindungan_konsumen/features/auth/data/models/app_user.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.storedToken});

  String? storedToken;

  ApiException? failWith;

  // Terverifikasi secara default -- itu jalur normal/umum yang dipakai
  // kebanyakan test di sini. Test yang khusus menguji gerbang verifikasi
  // email meng-override `user` ini dengan `emailVerifiedAt: null`.
  AppUser user = AppUser(
    id: 1,
    name: 'Budi Santoso',
    email: 'budi@example.com',
    phone: '081234567890',
    emailVerifiedAt: DateTime(2024),
  );

  final List<String> calls = [];

  @override
  Future<String?> readToken() async => storedToken;

  @override
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    calls.add('login($email)');
    return _resolve();
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    DateTime? dateOfBirth,
  }) async {
    calls.add('register($email)');
    if (failWith != null) throw failWith!;
  }

  @override
  Future<AppUser> verifyOtp({
    required String email,
    required String otp,
  }) async {
    calls.add('verifyOtp($email, $otp)');
    return _resolve();
  }

  @override
  Future<AppUser> loginWithGoogle(String accessToken) async {
    calls.add('google');
    return _resolve();
  }

  @override
  Future<AppUser> me() async {
    calls.add('me');
    return _resolve();
  }

  @override
  Future<AppUser> updateProfile({
    String? name,
    String? avatarUrl,
    DateTime? dateOfBirth,
    bool clearAvatar = false,
    bool clearDateOfBirth = false,
  }) async {
    calls.add('updateProfile($name)');
    if (failWith != null) throw failWith!;
    if (name != null) {
      // Pertahankan field lain (termasuk emailVerifiedAt) -- cuma nama yang
      // diganti di sini, biar test yang memeriksa status verifikasi tidak
      // ikut ketiban efek samping update profil yang tidak terkait.
      user = AppUser(
        id: user.id,
        name: name,
        email: user.email,
        phone: user.phone,
        dateOfBirth: user.dateOfBirth,
        avatarUrl: user.avatarUrl,
        emailVerifiedAt: user.emailVerifiedAt,
      );
    }
    return user;
  }

  @override
  Future<void> logout() async {
    calls.add('logout');
    storedToken = null;
  }

  String forgotPasswordMessage =
      'Jika email terdaftar, kode reset kata sandi telah dikirim.';
  String resetPasswordMessage = 'Kata sandi berhasil direset.';
  String resendOtpMessage =
      'Jika email terdaftar dan belum diverifikasi, kode OTP baru telah dikirim.';

  @override
  Future<String> forgotPassword(String email) async {
    calls.add('forgotPassword($email)');
    if (failWith != null) throw failWith!;
    return forgotPasswordMessage;
  }

  @override
  Future<String> resetPassword({
    required String email,
    required String otp,
    required String password,
    required String passwordConfirmation,
  }) async {
    calls.add('resetPassword($email)');
    if (failWith != null) throw failWith!;
    return resetPasswordMessage;
  }

  @override
  Future<String> resendOtp(String email) async {
    calls.add('resendOtp($email)');
    if (failWith != null) throw failWith!;
    return resendOtpMessage;
  }

  AppUser _resolve() {
    if (failWith != null) throw failWith!;
    return user;
  }
}
