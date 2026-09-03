import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../notification/application/device_token_controller.dart';
import '../../onboarding/application/active_sector_controller.dart';
import '../data/auth_repository.dart';
import '../data/models/app_user.dart';

class AuthController extends AsyncNotifier<AppUser?> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  Future<AppUser?> build() async {
    final token = await _repository.readToken();
    if (token == null) return null;

    try {
      final user = await _repository.me();
      _registerDeviceToken();
      return user;
    } on ApiException catch (error) {
      if (error.isUnauthorized) return null;
      rethrow;
    }
  }

  Future<void> login({required String email, required String password}) async {
    final user = await _repository.login(email: email, password: password);
    _startFreshSession(user);
  }

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
    _startFreshSession(user);
  }

  Future<void> loginWithGoogle(String accessToken) async {
    final user = await _repository.loginWithGoogle(accessToken);
    _startFreshSession(user);
  }

  /// Tiap autentikasi baru mulai dari layar pilih sektor lagi (satu user bisa
  /// banyak sektor) -- reset sektor aktif sesi sebelumnya kalau ada.
  void _startFreshSession(AppUser user) {
    ref.read(activeSectorSlugProvider.notifier).clear();
    state = AsyncValue.data(user);
    _registerDeviceToken();
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
    ref.read(activeSectorSlugProvider.notifier).clear();
    state = const AsyncValue.data(null);
  }

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

  void _registerDeviceToken() {
    unawaited(ref.read(deviceTokenControllerProvider).registerCurrentDevice());
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
