import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/storage/sector_storage.dart';
import '../../onboarding/application/sector_selection_provider.dart';
import '../data/auth_repository.dart';
import '../data/models/app_user.dart';

class AuthController extends AsyncNotifier<AppUser?> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  Future<AppUser?> build() async {
    final token = await _repository.readToken();
    if (token == null) return null;

    try {
      return await _repository.me();
    } on ApiException catch (error) {
      if (error.isUnauthorized) return null;
      rethrow;
    }
  }

  Future<void> login({required String email, required String password}) async {
    final user = await _repository.login(email: email, password: password);
    state = AsyncValue.data(user);
  }

  /// Sengaja tidak menyentuh `state` — akun baru belum punya sesi sampai
  /// [verifyOtp] berhasil. Pemanggil (RegisterForm) yang menavigasi ke layar
  /// OTP setelah ini selesai tanpa error.
  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    DateTime? dateOfBirth,
  }) {
    return _repository.register(
      name: name,
      email: email,
      password: password,
      phone: phone,
      dateOfBirth: dateOfBirth,
    );
  }

  Future<void> verifyOtp({required String email, required String otp}) async {
    final user = await _repository.verifyOtp(email: email, otp: otp);
    state = AsyncValue.data(user);
  }

  Future<void> loginWithGoogle(String accessToken) async {
    final user = await _repository.loginWithGoogle(accessToken);
    state = AsyncValue.data(user);
  }

  Future<void> refreshUser() async {
    final user = await _repository.me();
    state = AsyncValue.data(user);
  }

  Future<void> updateProfile({
    String? name,
    String? avatarUrl,
    DateTime? dateOfBirth,
  }) async {
    final user = await _repository.updateProfile(
      name: name,
      avatarUrl: avatarUrl,
      dateOfBirth: dateOfBirth,
    );
    state = AsyncValue.data(user);
  }

  Future<void> signOut() async {
    await _repository.logout();
    // Sektor yang dipilih itu pilihan akun ini, bukan pilihan device --
    // kalau tidak ikut dibersihkan, akun lain yang login di device yang
    // sama akan langsung "mewarisi" sektor akun sebelumnya tanpa pernah
    // ditanya.
    await ref.read(sectorStorageProvider).clear();
    ref.invalidate(selectedSectorSlugProvider);
    state = const AsyncValue.data(null);
  }

  // Method-method di bawah ini sengaja tidak menyentuh `state` — tidak satu
  // pun menghasilkan user yang login (reset & resend hanya mengirim email;
  // reset password sendiri tidak ikut membuatkan sesi baru di backend;
  // verifikasi sesi barunya lewat OTP, ada di [verifyOtp] di atas).
  Future<String> forgotPassword(String email) {
    return _repository.forgotPassword(email);
  }

  Future<String> resetPassword({
    required String email,
    required String otp,
    required String password,
    required String passwordConfirmation,
  }) {
    return _repository.resetPassword(
      email: email,
      otp: otp,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
  }

  Future<String> resendOtp(String email) {
    return _repository.resendOtp(email);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AppUser?>(
  AuthController.new,
);

final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authControllerProvider).value;
});

final isSignedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});
