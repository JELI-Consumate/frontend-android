// Alur onboarding -> layar auth.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perlindungan_konsumen/features/auth/data/auth_repository.dart';
import 'package:perlindungan_konsumen/features/auth/presentation/otp_verification_screen.dart';
import 'package:perlindungan_konsumen/features/learning/data/learning_repository.dart';
import 'package:perlindungan_konsumen/main.dart';

import 'support/fake_auth_repository.dart';
import 'support/fake_learning_repository.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester, FakeAuthRepository repository) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          // MainShell me-render semua tab lewat IndexedStack (bukan lazy),
          // jadi begitu user login, DashboardScreen & JourneysScreen ikut
          // ter-build dan minta data lewat provider ini juga.
          learningRepositoryProvider.overrideWithValue(
            FakeLearningRepository(),
          ),
        ],
        child: const MyApp(),
      ),
    );
  }

  testWidgets('Tanpa token, app mulai dari halaman sambutan', (tester) async {
    await pumpApp(tester, FakeAuthRepository());
    await tester.pumpAndSettle();

    expect(find.text('Selamat Datang!'), findsOneWidget);
  });

  testWidgets('Onboarding selesai membuka layar auth', (tester) async {
    await pumpApp(tester, FakeAuthRepository());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mulai'));
    await tester.pumpAndSettle();
    expect(find.text('Pre-Test'), findsOneWidget);

    await tester.tap(find.text('Mulai Pre-Test'));
    await tester.pumpAndSettle();

    expect(find.text('Daftar'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
  });

  testWidgets('Token tersimpan langsung masuk ke MainShell', (tester) async {
    final repository = FakeAuthRepository(storedToken: 'token-123');

    await pumpApp(tester, repository);
    await tester.pumpAndSettle();

    expect(repository.calls, contains('me'));
    // Tab awal "Beranda" (dashboard pembelajaran) — bukan lagi HomeScreen
    // langsung, itu sekarang tab "Profil". Navigasikan ke sana dulu.
    expect(find.text('Lanjutkan Belajar'), findsOneWidget);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    expect(find.text('Halo, Budi Santoso!'), findsOneWidget);
  });

  testWidgets(
    'OTP benar setelah didorong dari alur nyata langsung masuk ke MainShell',
    (tester) async {
      // Regresi: OtpVerificationScreen sampai ke sini lewat Navigator.push
      // (persis seperti RegisterForm/LoginForm melakukannya) -- dulu, begitu
      // verifyOtp sukses, AppRoot di baliknya rebuild ke MainShell tapi
      // layar OTP tetap tertumpuk di atas Navigator dan tidak pernah di-pop,
      // jadi pengguna terjebak di layar OTP walau kodenya benar.
      final repository = FakeAuthRepository();
      await pumpApp(tester, repository);
      await tester.pumpAndSettle();

      // Lewati onboarding dulu supaya konteksnya AuthScreen, seperti alur
      // nyata sebelum RegisterForm mendorong layar OTP.
      await tester.tap(find.text('Mulai'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mulai Pre-Test'));
      await tester.pumpAndSettle();

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) =>
              const OtpVerificationScreen(email: 'budi@example.com'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Masukkan Kode OTP'), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('otp-box-0')), '123456');
      await tester.pumpAndSettle();

      expect(repository.calls, contains('verifyOtp(budi@example.com, 123456)'));
      expect(find.text('Masukkan Kode OTP'), findsNothing);
      expect(find.text('Lanjutkan Belajar'), findsOneWidget);
    },
  );
}
