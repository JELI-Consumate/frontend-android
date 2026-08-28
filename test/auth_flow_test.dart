// Perilaku form auth: validasi lokal, sukses, dan error dari server.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:perlindungan_konsumen/core/network/api_exception.dart';
import 'package:perlindungan_konsumen/core/theme/app_theme.dart';
import 'package:perlindungan_konsumen/features/auth/data/auth_repository.dart';
import 'package:perlindungan_konsumen/features/auth/presentation/auth_screen.dart';

import 'support/fake_auth_repository.dart';

void main() {
  // `main()` produksi menginisialisasi ini sebelum runApp; test membangun
  // MaterialApp sendiri jadi harus diinisialisasi manual juga, kalau tidak
  // date picker di form registrasi melempar LocaleDataException.
  setUpAll(() => initializeDateFormatting('id_ID'));

  Future<void> pumpAuth(
    WidgetTester tester,
    FakeAuthRepository repository, {
    AuthTab tab = AuthTab.login,
  }) async {
    // Viewport default flutter_test (800x600) lebih pendek dari HP asli dan
    // memotong form registrasi yang sekarang enam field; perbesar supaya
    // tombol & tautan di bawahnya tetap bisa disentuh tanpa scroll manual.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: AuthScreen(initialTab: tab),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // Konten layar auth ada di dalam SingleChildScrollView, jadi elemen di
  // bagian bawah (tombol submit, tautan footer) bisa berada di luar
  // viewport sampai discroll — persis seperti pengguna asli. `tester.tap`
  // biasa gagal untuk elemen begitu, maka semua tap di sini didahului
  // `ensureVisible`.
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> pickDateOfBirth(WidgetTester tester) async {
    await tapVisible(tester, find.widgetWithText(TextField, 'Tanggal Lahir'));
    await tester.tap(find.text('Pilih'));
    await tester.pumpAndSettle();
  }

  group('Login', () {
    testWidgets('field kosong memunculkan pesan validasi', (tester) async {
      final repository = FakeAuthRepository();
      await pumpAuth(tester, repository);

      await tapVisible(tester, find.widgetWithText(FilledButton, 'Masuk'));

      expect(find.text('Email wajib diisi.'), findsOneWidget);
      expect(find.text('Kata sandi wajib diisi.'), findsOneWidget);
      expect(repository.calls, isEmpty);
    });

    testWidgets('email tidak valid memunculkan pesan validasi', (tester) async {
      final repository = FakeAuthRepository();
      await pumpAuth(tester, repository);

      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'bukan-email',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Kata sandi'),
        'rahasia123',
      );
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Masuk'));

      expect(find.text('Format email belum benar.'), findsOneWidget);
      expect(repository.calls, isEmpty);
    });

    testWidgets('kredensial valid memanggil repository', (tester) async {
      final repository = FakeAuthRepository();
      await pumpAuth(tester, repository);

      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'budi@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Kata sandi'),
        'rahasia123',
      );
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Masuk'));

      expect(repository.calls, contains('login(budi@example.com)'));
    });

    testWidgets('kredensial salah menampilkan pesan server', (tester) async {
      final repository = FakeAuthRepository()
        ..failWith = const ApiException(
          message: 'Email atau kata sandi salah.',
          statusCode: 401,
          code: 'INVALID_CREDENTIALS',
        );
      await pumpAuth(tester, repository);

      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'budi@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Kata sandi'),
        'salah',
      );
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Masuk'));

      // Alert modal ala SweetAlert, bukan lagi SnackBar.
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Email atau kata sandi salah.'), findsOneWidget);
    });

    testWidgets('email belum diverifikasi membuka layar OTP', (tester) async {
      final repository = FakeAuthRepository()
        ..failWith = const ApiException(
          message: 'Email kamu belum diverifikasi.',
          statusCode: 403,
          code: 'EMAIL_NOT_VERIFIED',
        );
      await pumpAuth(tester, repository);

      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'budi@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Kata sandi'),
        'rahasia123',
      );
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Masuk'));

      // Bukan alert lagi -- login yang gagal karena EMAIL_NOT_VERIFIED
      // langsung mendorong ke layar OTP, kredensialnya sudah benar.
      expect(find.text('Masukkan Kode OTP'), findsOneWidget);
      expect(find.textContaining('budi@example.com'), findsOneWidget);
    });
  });

  group('Lupa kata sandi', () {
    testWidgets('tombol Lupa kata sandi membuka layar reset', (tester) async {
      await pumpAuth(tester, FakeAuthRepository());

      await tapVisible(tester, find.text('Lupa kata sandi?'));

      expect(find.text('Lupa Kata Sandi'), findsOneWidget);
    });

    testWidgets('kirim email valid menampilkan konfirmasi', (tester) async {
      final repository = FakeAuthRepository();
      await pumpAuth(tester, repository);
      await tapVisible(tester, find.text('Lupa kata sandi?'));

      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'budi@example.com',
      );
      await tapVisible(
        tester,
        find.widgetWithText(FilledButton, 'Kirim Kode Reset'),
      );

      expect(repository.calls, contains('forgotPassword(budi@example.com)'));
      expect(find.text('Cek email kamu'), findsOneWidget);
    });

    testWidgets('lanjut ke reset dengan email ter-prefill', (tester) async {
      final repository = FakeAuthRepository();
      await pumpAuth(tester, repository);
      await tapVisible(tester, find.text('Lupa kata sandi?'));

      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'budi@example.com',
      );
      await tapVisible(
        tester,
        find.widgetWithText(FilledButton, 'Kirim Kode Reset'),
      );
      await tapVisible(
        tester,
        find.widgetWithText(FilledButton, 'Sudah Punya Kode?'),
      );

      expect(find.widgetWithText(AppBar, 'Reset Kata Sandi'), findsOneWidget);
      final emailField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Email'),
      );
      expect(emailField.controller?.text, 'budi@example.com');

      await tester.enterText(
        find.widgetWithText(TextField, 'Kode Reset'),
        '482913',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Kata Sandi Baru'),
        'sandiBaru123',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Konfirmasi Kata Sandi Baru'),
        'sandiBaru123',
      );
      await tapVisible(
        tester,
        find.widgetWithText(FilledButton, 'Reset Kata Sandi'),
      );

      expect(repository.calls, contains('resetPassword(budi@example.com)'));
      // Berhasil reset -> kembali ke AuthScreen (root stack ini); AppBar
      // "Reset Kata Sandi" dan "Lupa Kata Sandi" sudah tidak ada lagi.
      expect(find.text('Reset Kata Sandi'), findsNothing);
      expect(find.text('Lupa Kata Sandi'), findsNothing);
    });
  });

  group('Register', () {
    testWidgets('catatan syarat kata sandi tampil di bawah field', (
      tester,
    ) async {
      await pumpAuth(tester, FakeAuthRepository(), tab: AuthTab.register);

      expect(find.text('Kata sandi minimal 8 karakter.'), findsOneWidget);
    });

    testWidgets('konfirmasi kata sandi berbeda langsung tampil tanpa submit', (
      tester,
    ) async {
      await pumpAuth(tester, FakeAuthRepository(), tab: AuthTab.register);

      await tester.enterText(
        find.widgetWithText(TextField, 'Kata sandi'),
        'rahasia123',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Konfirmasi Kata sandi'),
        'beda123',
      );
      await tester.pumpAndSettle();

      expect(find.text('Konfirmasi kata sandi belum cocok.'), findsOneWidget);
    });

    testWidgets('konfirmasi kata sandi harus cocok', (tester) async {
      final repository = FakeAuthRepository();
      await pumpAuth(tester, repository, tab: AuthTab.register);

      await tester.enterText(
        find.widgetWithText(TextField, 'Nama Lengkap'),
        'Budi',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'budi@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Kata sandi'),
        'rahasia123',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Konfirmasi Kata sandi'),
        'rahasia124',
      );
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Daftar'));

      expect(find.text('Konfirmasi kata sandi belum cocok.'), findsOneWidget);
      expect(repository.calls, isEmpty);
    });

    testWidgets('nomor HP dan tanggal lahir wajib diisi', (tester) async {
      final repository = FakeAuthRepository();
      await pumpAuth(tester, repository, tab: AuthTab.register);

      await tester.enterText(
        find.widgetWithText(TextField, 'Nama Lengkap'),
        'Budi',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'budi@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Kata sandi'),
        'rahasia123',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Konfirmasi Kata sandi'),
        'rahasia123',
      );
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Daftar'));

      expect(find.text('Nomor HP wajib diisi.'), findsOneWidget);
      expect(find.text('Tanggal lahir wajib diisi.'), findsOneWidget);
      expect(repository.calls, isEmpty);
    });

    testWidgets('error 422 dari server tampil di bawah field', (tester) async {
      final repository = FakeAuthRepository()
        ..failWith = const ApiException(
          message: 'The email has already been taken.',
          statusCode: 422,
          fieldErrors: {
            'email': ['Email sudah dipakai akun lain.'],
          },
        );
      await pumpAuth(tester, repository, tab: AuthTab.register);

      await tester.enterText(
        find.widgetWithText(TextField, 'Nama Lengkap'),
        'Budi',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'budi@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Nomor HP'),
        '081234567890',
      );
      await pickDateOfBirth(tester);
      await tester.enterText(
        find.widgetWithText(TextField, 'Kata sandi'),
        'rahasia123',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Konfirmasi Kata sandi'),
        'rahasia123',
      );
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Daftar'));

      expect(find.text('Email sudah dipakai akun lain.'), findsOneWidget);
    });

    testWidgets('daftar sukses membuka layar OTP, bukan langsung masuk', (
      tester,
    ) async {
      final repository = FakeAuthRepository();
      await pumpAuth(tester, repository, tab: AuthTab.register);

      await tester.enterText(
        find.widgetWithText(TextField, 'Nama Lengkap'),
        'Budi',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'budi@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Nomor HP'),
        '081234567890',
      );
      await pickDateOfBirth(tester);
      await tester.enterText(
        find.widgetWithText(TextField, 'Kata sandi'),
        'rahasia123',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Konfirmasi Kata sandi'),
        'rahasia123',
      );
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Daftar'));

      expect(repository.calls, contains('register(budi@example.com)'));
      expect(find.text('Masukkan Kode OTP'), findsOneWidget);
      expect(find.textContaining('budi@example.com'), findsOneWidget);
    });
  });

  testWidgets('tab Daftar bisa dibuka dari tautan bawah', (tester) async {
    await pumpAuth(tester, FakeAuthRepository());

    await tapVisible(tester, find.textContaining('Belum punya akun?'));

    expect(find.widgetWithText(TextField, 'Nama Lengkap'), findsOneWidget);
  });
}
