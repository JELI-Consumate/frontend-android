// Alur onboarding -> layar auth.

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
  // Sektor aktif default-nya sudah di-seed 'e-commerce' supaya test yang
  // cuma mau menguji hal lain tetap langsung tembus ke MainShell tanpa
  // mampir ke SectorSelectionScreen. Test yang justru menguji layar itu
  // mengoper `startAtSectorPicker: true`.
  Future<void> pumpApp(
    WidgetTester tester,
    FakeAuthRepository repository, {
    bool startAtSectorPicker = false,
  }) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          // MainShell me-render semua tab lewat IndexedStack (bukan lazy),
          // jadi begitu user login, DashboardScreen, JourneysScreen, dan
          // BadgesScreen ikut ter-build dan minta data lewat provider ini
          // juga.
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

    // Onboarding sekarang cuma satu slide sambutan -- pre-test sudah jadi
    // kartu survei di Beranda, bukan slide onboarding.
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
    // Tab awal "Beranda" (dashboard pembelajaran), bukan langsung "Profil"
    // -- navigasikan ke sana dulu untuk mengecek isinya.
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
      // Nama sektor tampil di kartu grid DAN di panel konfirmasi bawah.
      expect(find.text('E-Commerce'), findsWidgets);
      expect(find.text('Lanjutkan Belajar'), findsNothing);

      // E-Commerce sudah terpilih otomatis (sektor pertama) -- tinggal
      // konfirmasi lewat tombol "Mulai Belajar".
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
      // Regresi: OtpVerificationScreen sampai ke sini lewat Navigator.push
      // (persis seperti RegisterForm/LoginForm melakukannya) -- dulu, begitu
      // verifyOtp sukses, AppRoot di baliknya rebuild tapi layar OTP tetap
      // tertumpuk di atas Navigator dan tidak pernah di-pop, jadi pengguna
      // terjebak di layar OTP walau kodenya benar.
      final repository = FakeAuthRepository();
      await pumpApp(tester, repository);
      await tester.pumpAndSettle();

      // Lewati onboarding dulu supaya konteksnya AuthScreen, seperti alur
      // nyata sebelum RegisterForm mendorong layar OTP.
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
      // Autentikasi baru -> mendarat di "Pilih Sektor" dulu (bukan langsung
      // Home), lalu tembus ke MainShell setelah memilih.
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
