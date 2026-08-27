// Perilaku layar konsumsi konten module -- satu grup tes per tipe konten
// (`ContentType`): video, article (materi/infografis/komik/opening sama-sama
// lewat sini), quiz, simulation (matching & ordering), dan reflection.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perlindungan_konsumen/core/theme/app_theme.dart';
import 'package:perlindungan_konsumen/features/learning/data/models/learning_module.dart';
import 'package:perlindungan_konsumen/features/module/data/models/module_page.dart';
import 'package:perlindungan_konsumen/features/module/data/module_repository.dart';
import 'package:perlindungan_konsumen/features/module/presentation/article_module_screen.dart';
import 'package:perlindungan_konsumen/features/module/presentation/quiz_module_screen.dart';
import 'package:perlindungan_konsumen/features/module/presentation/reflection_module_screen.dart';
import 'package:perlindungan_konsumen/features/module/presentation/simulation_module_screen.dart';
import 'package:perlindungan_konsumen/features/module/presentation/video_module_screen.dart';

import 'support/fake_module_repository.dart';
import 'support/module_fixtures.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget screen,
    FakeModuleRepository repository,
  ) async {
    // Jauh lebih tinggi dari HP asli dengan sengaja: layar-layar ini pakai
    // `ListView` (bukan `SingleChildScrollView` seperti form auth), yang
    // tidak nge-build/tidak menganggap "onstage" konten di luar viewport --
    // `find.text` default (skipOffstage: true) tidak akan menemukannya sampai
    // discroll. Viewport setinggi ini memastikan seluruh konten tiap tes
    // (soal kuis, kartu game, dst.) muat tanpa perlu scroll manual.
    tester.view.physicalSize = const Size(1080, 9600);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [moduleRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(theme: AppTheme.light, home: screen),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('VideoModuleScreen', () {
    testWidgets('menampilkan judul, pertanyaan pemantik, dan tombol selesai', (
      tester,
    ) async {
      final module = videoModuleFixture();
      final repository = FakeModuleRepository();
      await pump(
        tester,
        VideoModuleScreen(module: module, page: module.firstPage!),
        repository,
      );

      expect(
        find.text('Apa risiko belanja online yang paling sering kamu temui?'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Kenali hak-hak dasarmu sebagai konsumen sebelum belanja online.',
        ),
        findsOneWidget,
      );
      expect(find.text('Tandai Selesai'), findsOneWidget);
    });

    testWidgets('tap Tandai Selesai memanggil complete dan berubah status', (
      tester,
    ) async {
      final module = videoModuleFixture();
      final repository = FakeModuleRepository();
      await pump(
        tester,
        VideoModuleScreen(module: module, page: module.firstPage!),
        repository,
      );

      await tester.tap(find.text('Tandai Selesai'));
      await tester.pumpAndSettle();

      expect(repository.calls, contains('completeModulePage(1010)'));
      expect(find.text('Sudah selesai'), findsOneWidget);
    });
  });

  group('ArticleModuleScreen (materi/infografis/komik/opening)', () {
    testWidgets('merender seluruh jenis block', (tester) async {
      final module = articleModuleFixture();
      final repository = FakeModuleRepository();
      await pump(
        tester,
        ArticleModuleScreen(module: module, page: module.firstPage!),
        repository,
      );

      expect(
        find.text(
          'Setiap transaksi online tunduk pada UU Perlindungan Konsumen.',
        ),
        findsOneWidget,
      );
      expect(find.text('Infografis aturan belanja online'), findsOneWidget);
      expect(find.text('Simpan selalu bukti transaksi.'), findsOneWidget);
      // Satu-satunya block list_item di fixture ini -- nomornya "1" meski
      // urutan block-nya sendiri yang ke-3 (paragraph, image, LIST_ITEM,
      // reference), soalnya dihitung cuma dari sesama list_item.
      expect(find.text('1'), findsOneWidget);
      expect(
        find.text('UU No. 8 Tahun 1999 tentang Perlindungan Konsumen.'),
        findsOneWidget,
      );
    });

    testWidgets('tap Tandai Selesai menandai module ini selesai', (
      tester,
    ) async {
      final module = articleModuleFixture(type: ModuleContentType.infografis);
      final repository = FakeModuleRepository();
      await pump(
        tester,
        ArticleModuleScreen(module: module, page: module.firstPage!),
        repository,
      );

      await tester.tap(find.text('Tandai Selesai'));
      await tester.pumpAndSettle();

      expect(repository.calls, contains('completeModulePage(1012)'));
      expect(find.text('Sudah selesai'), findsOneWidget);
    });
  });

  group('QuizModuleScreen', () {
    testWidgets('mulai attempt otomatis begitu layar dibuka', (tester) async {
      final module = quizModuleFixture();
      final repository = FakeModuleRepository();
      await pump(
        tester,
        QuizModuleScreen(module: module, page: module.firstPage!),
        repository,
      );

      expect(repository.calls, contains('startQuizAttempt(100)'));
    });

    testWidgets('tombol kumpulkan nonaktif sampai semua soal terjawab', (
      tester,
    ) async {
      final module = quizModuleFixture();
      final repository = FakeModuleRepository();
      await pump(
        tester,
        QuizModuleScreen(module: module, page: module.firstPage!),
        repository,
      );

      final button = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Kumpulkan Jawaban'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('jawab semua benar menampilkan hasil lulus 100%', (
      tester,
    ) async {
      final module = quizModuleFixture();
      final repository = FakeModuleRepository();
      await pump(
        tester,
        QuizModuleScreen(module: module, page: module.firstPage!),
        repository,
      );

      await tester.tap(find.text('Mendapat informasi yang benar')); // Q1 benar
      await tester.tap(find.text('Bukti transaksi')); // Q2 benar
      await tester.tap(find.text('3')); // Q3 likert, nilai bebas
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kumpulkan Jawaban'));
      await tester.pumpAndSettle();

      expect(repository.calls, contains('submitQuizAttempt(1)'));
      expect(find.text('Selamat, kamu lulus!'), findsOneWidget);
      expect(find.text('100% benar (2/2)'), findsOneWidget);
    });

    testWidgets('jawab salah satu soal menampilkan hasil belum lulus', (
      tester,
    ) async {
      final module = quizModuleFixture();
      final repository = FakeModuleRepository();
      await pump(
        tester,
        QuizModuleScreen(module: module, page: module.firstPage!),
        repository,
      );

      await tester.tap(find.text('Dilarang komplain')); // Q1 salah
      await tester.tap(find.text('Bukti transaksi')); // Q2 benar
      await tester.tap(find.text('3'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kumpulkan Jawaban'));
      await tester.pumpAndSettle();

      expect(find.text('Belum lulus, coba lagi ya'), findsOneWidget);
      expect(find.text('50% benar (1/2)'), findsOneWidget);
    });
  });

  group('SimulationModuleScreen -- matching', () {
    testWidgets('pasangkan semua kartu dengan benar menyelesaikan simulasi', (
      tester,
    ) async {
      final module = simulationMatchingModuleFixture();
      final repository = FakeModuleRepository();
      await pump(
        tester,
        SimulationModuleScreen(module: module, page: module.firstPage!),
        repository,
      );

      expect(repository.calls, contains('startSimulationAttempt(500)'));

      await tester.tap(find.text('Barang datang tidak sesuai pesanan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ajukan komplain ke penjual'));
      await tester.pumpAndSettle();

      expect(find.text('1/2 pasangan benar'), findsOneWidget);

      await tester.tap(find.text('Harga terlalu murah dari pasaran'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Waspada indikasi penipuan'));
      await tester.pumpAndSettle();

      expect(find.text('Simulasi selesai!'), findsOneWidget);
    });

    testWidgets('pasangan salah menampilkan pesan dan tidak tersimpan', (
      tester,
    ) async {
      final module = simulationMatchingModuleFixture();
      final repository = FakeModuleRepository();
      await pump(
        tester,
        SimulationModuleScreen(module: module, page: module.firstPage!),
        repository,
      );

      await tester.tap(find.text('Barang datang tidak sesuai pesanan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Waspada indikasi penipuan')); // salah
      await tester.pumpAndSettle();

      expect(find.text('Belum pas, coba pasangan lain.'), findsOneWidget);
      expect(find.text('0/2 pasangan benar'), findsOneWidget);
    });
  });

  group('SimulationModuleScreen -- ordering', () {
    testWidgets('susun langkah sesuai urutan benar menyelesaikan simulasi', (
      tester,
    ) async {
      final module = simulationOrderingModuleFixture();
      final repository = FakeModuleRepository();
      await pump(
        tester,
        SimulationModuleScreen(module: module, page: module.firstPage!),
        repository,
      );

      await tester.tap(find.text('Hubungi penjual'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ajukan komplain ke platform'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Laporkan ke BPKN'));
      await tester.pumpAndSettle();

      expect(find.text('Simulasi selesai!'), findsOneWidget);
    });
  });

  group('ReflectionModuleScreen', () {
    testWidgets('memuat konten dan menyimpan jawaban', (tester) async {
      final module = reflectionModuleFixture();
      final repository = FakeModuleRepository()
        ..reflectionFixture =
            (module.firstPage!.content as ReflectionPageContent).content;
      await pump(
        tester,
        ReflectionModuleScreen(module: module, page: module.firstPage!),
        repository,
      );

      expect(repository.calls, contains('reflection(800)'));
      expect(
        find.text('Apa hak konsumen yang paling penting menurutmu?'),
        findsOneWidget,
      );

      await tester.enterText(
        find.byType(TextField),
        'Hak atas informasi yang benar.',
      );
      await tester.tap(find.text('Membaca ulasan sebelum membeli'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Simpan Jawaban'));
      await tester.pumpAndSettle();

      expect(repository.calls, contains('saveReflectionEntries(800)'));
      expect(find.text('Jawaban tersimpan.'), findsOneWidget);
      expect(find.text('Refleksimu sudah tersimpan.'), findsOneWidget);
    });
  });
}
