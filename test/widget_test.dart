

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perlindungan_konsumen/features/auth/data/auth_repository.dart';
import 'package:perlindungan_konsumen/features/auth/presentation/otp_verification_screen.dart';
import 'package:perlindungan_konsumen/features/badges/data/badge_repository.dart';
import 'package:perlindungan_konsumen/features/learning/data/learning_repository.dart';
import 'package:perlindungan_konsumen/main.dart';

import 'support/active_sector_override.dart';
import 'support/fake_auth_repository.dart';
import 'support/fake_badge_repository.dart';
import 'support/fake_learning_repository.dart';

void main() {

  Future<void> pumpApp(
    WidgetTester tester,
    FakeAuthRepository repository, {
    bool startAtSectorPicker = false,
  }) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),

          learningRepositoryProvider.overrideWithValue(
            FakeLearningRepository(),
          ),
          badgeRepositoryProvider.overrideWithValue(FakeBadgeRepository()),
          activeSectorOverride(startAtSectorPicker ? null : 'e-commerce'),
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

    expect(find.text('Daftar'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
  });

  testWidgets('Token tersimpan langsung masuk ke MainShell', (tester) async {
    final repository = FakeAuthRepository(storedToken: 'token-123');

    await pumpApp(tester, repository);
    await tester.pumpAndSettle();

    expect(repository.calls, contains('me'));

    expect(find.text('Lanjutkan Belajar'), findsOneWidget);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    expect(find.text('Budi Santoso'), findsOneWidget);
  });

  testWidgets(
    'Belum pernah pilih sektor, tampil layar pilih sektor dulu sebelum MainShell',
    (tester) async {
      final repository = FakeAuthRepository(storedToken: 'token-123');

      await pumpApp(tester, repository, startAtSectorPicker: true);
      await tester.pumpAndSettle();

      expect(
        find.text('Pilih sektor yang akan kamu pelajari'),
        findsOneWidget,
      );

      expect(find.text('E-Commerce'), findsWidgets);
      expect(find.text('Lanjutkan Belajar'), findsNothing);

      await tester.tap(find.text('Mulai Belajar'));
      await tester.pumpAndSettle();

      expect(
        find.text('Pilih sektor yang akan kamu pelajari'),
        findsNothing,
      );
      expect(find.text('Lanjutkan Belajar'), findsOneWidget);
    },
  );

  testWidgets(
    'OTP benar setelah didorong dari alur nyata tidak terjebak di layar OTP',
    (tester) async {

      final repository = FakeAuthRepository();
      await pumpApp(tester, repository);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mulai'));
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

      expect(
        find.text('Pilih sektor yang akan kamu pelajari'),
        findsOneWidget,
      );

      await tester.tap(find.text('Mulai Belajar'));
      await tester.pumpAndSettle();
      expect(find.text('Lanjutkan Belajar'), findsOneWidget);
    },
  );
}
