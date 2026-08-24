import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/application/auth_controller.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import 'main_shell.dart';
import 'splash_screen.dart';

class AppRoot extends ConsumerWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);

    if (auth.isLoading && !auth.hasValue) return const SplashScreen();

    final user = auth.value;
    if (user == null) return const _UnauthenticatedFlow();

    // Tidak ada cabang "belum verifikasi" di sini -- backend tidak pernah
    // menerbitkan token untuk akun yang emailnya belum terverifikasi
    // (register() tidak lagi membuat sesi; login()/verifyOtp() sama-sama
    // mensyaratkan email_verified_at terisi). Kalau `user` bukan null,
    // emailnya sudah pasti terverifikasi.
    return const MainShell();
  }
}

class _UnauthenticatedFlow extends StatefulWidget {
  const _UnauthenticatedFlow();

  @override
  State<_UnauthenticatedFlow> createState() => _UnauthenticatedFlowState();
}

class _UnauthenticatedFlowState extends State<_UnauthenticatedFlow> {
  bool _onboardingDone = false;

  @override
  Widget build(BuildContext context) {
    if (_onboardingDone) return const AuthScreen();

    return OnboardingScreen(
      onFinished: () => setState(() => _onboardingDone = true),
    );
  }
}
