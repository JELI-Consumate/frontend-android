import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/application/auth_controller.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/onboarding/application/sector_selection_provider.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/onboarding/presentation/sector_selection_screen.dart';
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

    // Satu langkah lagi sebelum MainShell: pengguna yang belum pernah
    // memilih sektor (akun baru, atau device baru) harus memilih dulu di
    // SectorSelectionScreen. Errornya sengaja diperlakukan sama seperti
    // "belum memilih" -- ini cuma baca local storage, hampir tidak pernah
    // gagal, dan lebih baik pengguna diminta memilih ulang daripada
    // terjebak di layar error.
    final selectedSector = ref.watch(selectedSectorSlugProvider);
    final hasSelectedSector = selectedSector.maybeWhen(
      data: (slug) => slug != null,
      orElse: () => false,
    );
    if (!hasSelectedSector) {
      if (selectedSector.isLoading) return const SplashScreen();
      return const SectorSelectionScreen();
    }

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
