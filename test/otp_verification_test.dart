// Layar OTP: input kode, kirim ulang, dan tombol kembali.
//
// Verifikasi sukses/gagal cuma diuji lewat panggilan ke repository di sini
// (bukan navigasi ke MainShell) -- alur penuh "daftar -> OTP -> MainShell"
// ada di auth_flow_test.dart & lewat AppRoot yang tidak dipasang di layar
// berdiri sendiri seperti ini.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perlindungan_konsumen/core/network/api_exception.dart';
import 'package:perlindungan_konsumen/core/theme/app_theme.dart';
import 'package:perlindungan_konsumen/features/auth/data/auth_repository.dart';
import 'package:perlindungan_konsumen/features/auth/presentation/otp_verification_screen.dart';

import 'support/fake_auth_repository.dart';

void main() {
  const email = 'budi@example.com';

  Future<void> pumpOtpScreen(
    WidgetTester tester,
    FakeAuthRepository repository,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const OtpVerificationScreen(email: email),
                    ),
                  ),
                  child: const Text('Buka OTP'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buka OTP'));
    await tester.pumpAndSettle();
  }

  testWidgets('menampilkan email tujuan kode OTP', (tester) async {
    await pumpOtpScreen(tester, FakeAuthRepository());

    expect(find.text('Masukkan Kode OTP'), findsOneWidget);
    expect(find.textContaining(email), findsOneWidget);
  });

  // Kode 6 digit sekarang diisi lewat 6 kotak terpisah (bukan 1 field
  // panjang) -- lihat _OtpBoxInput. Mengetik/menempel di kotak pertama
  // menyebar sisa digitnya ke kotak-kotak berikutnya, jadi test tetap bisa
  // mengisi semuanya lewat satu `enterText` di kotak indeks 0.
  Finder otpBox(int index) => find.byKey(ValueKey('otp-box-$index'));

  testWidgets('kode kurang dari 6 digit menampilkan validasi lokal', (
    tester,
  ) async {
    final repository = FakeAuthRepository();
    await pumpOtpScreen(tester, repository);

    await tester.enterText(otpBox(0), '123');
    await tester.tap(find.widgetWithText(FilledButton, 'Verifikasi'));
    await tester.pumpAndSettle();

    expect(find.text('Kode OTP harus 6 digit.'), findsOneWidget);
    expect(repository.calls, isEmpty);
  });

  testWidgets('kode 6 digit valid memanggil verifyOtp', (tester) async {
    final repository = FakeAuthRepository();
    await pumpOtpScreen(tester, repository);

    await tester.enterText(otpBox(0), '123456');
    await tester.pumpAndSettle();

    // Terisi penuh -> verifikasi terpicu otomatis, tanpa perlu menekan
    // tombol "Verifikasi" secara manual.
    expect(repository.calls, contains('verifyOtp($email, 123456)'));
  });

  testWidgets('menekan tombol Verifikasi manual juga berfungsi', (
    tester,
  ) async {
    final repository = FakeAuthRepository();
    await pumpOtpScreen(tester, repository);

    // Isi tiap kotak satu-satu (bukan tempel sekaligus) untuk menguji jalur
    // ketik-per-digit + auto-pindah fokus, lalu tetap tekan tombolnya.
    for (var i = 0; i < 6; i++) {
      await tester.enterText(otpBox(i), '${i + 1}');
    }
    await tester.tap(find.widgetWithText(FilledButton, 'Verifikasi'));
    await tester.pumpAndSettle();

    expect(repository.calls, contains('verifyOtp($email, 123456)'));
  });

  testWidgets('kode salah dari server menampilkan pesan inline', (
    tester,
  ) async {
    final repository = FakeAuthRepository()
      ..failWith = const ApiException(
        message: 'Kode OTP tidak valid atau sudah kedaluwarsa.',
        statusCode: 422,
        code: 'INVALID_OTP',
      );
    await pumpOtpScreen(tester, repository);

    await tester.enterText(otpBox(0), '000000');
    await tester.pumpAndSettle();

    expect(find.text('Kode OTP salah atau sudah kedaluwarsa.'), findsOneWidget);
    // Masih di layar OTP, bukan alert modal terpisah.
    expect(find.text('Masukkan Kode OTP'), findsOneWidget);
    // Kotak-kotaknya juga dikosongkan lagi supaya gampang mengetik ulang.
    expect(tester.widget<TextField>(otpBox(0)).controller?.text, isEmpty);
  });

  testWidgets('kirim ulang memanggil resendOtp dan memulai cooldown', (
    tester,
  ) async {
    final repository = FakeAuthRepository();
    await pumpOtpScreen(tester, repository);

    await tester.tap(find.text('Kirim Ulang Kode'));
    await tester.pumpAndSettle();

    expect(repository.calls, contains('resendOtp($email)'));
    expect(find.text('Kode Terkirim'), findsOneWidget);

    // Tutup alert, lalu tombol kirim ulang mestinya nonaktif dengan hitung
    // mundur selama cooldown berjalan.
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Kirim Ulang Kode ('), findsOneWidget);
  });

  testWidgets('kirim ulang yang gagal menampilkan alert error', (tester) async {
    final repository = FakeAuthRepository()
      ..failWith = const ApiException(
        message: 'Terlalu banyak percobaan.',
        statusCode: 429,
      );
    await pumpOtpScreen(tester, repository);

    await tester.tap(find.text('Kirim Ulang Kode'));
    await tester.pumpAndSettle();

    expect(find.text('Gagal Mengirim Ulang'), findsOneWidget);
  });

  testWidgets('tombol kembali mem-pop layar OTP', (tester) async {
    await pumpOtpScreen(tester, FakeAuthRepository());
    expect(find.text('Masukkan Kode OTP'), findsOneWidget);

    await tester.tap(find.text('Kembali'));
    await tester.pumpAndSettle();

    expect(find.text('Buka OTP'), findsOneWidget);
    expect(find.text('Masukkan Kode OTP'), findsNothing);
  });
}
