// Perilaku layar konsumsi konten module -- satu grup tes per tipe konten
// (`ContentType`): video, article (materi/infografis/komik/opening sama-sama
// lewat sini), quiz, simulation (matching & ordering), dan reflection.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perlindungan_konsumen/core/theme/app_theme.dart';
import 'package:perlindungan_konsumen/features/learning/data/models/learning_module.dart';
import 'package:perlindungan_konsumen/features/module/data/models/content/simulation_content.dart';
import 'package:perlindungan_konsumen/features/module/data/models/module_detail.dart';
import 'package:perlindungan_konsumen/features/module/data/models/module_page.dart';
import 'package:perlindungan_konsumen/features/module/data/module_repository.dart';
import 'package:perlindungan_konsumen/features/module/presentation/article_module_screen.dart';
import 'package:perlindungan_konsumen/features/module/presentation/module_screen.dart';
import 'package:perlindungan_konsumen/features/module/presentation/quiz_module_screen.dart';
import 'package:perlindungan_konsumen/features/module/presentation/reflection_module_screen.dart';
import 'package:perlindungan_konsumen/features/module/presentation/simulation_module_screen.dart';
import 'package:perlindungan_konsumen/features/module/presentation/video_module_screen.dart';
import 'package:perlindungan_konsumen/features/module/presentation/widgets/module_bottom_bar.dart';
import 'package:perlindungan_konsumen/features/module/presentation/widgets/module_page_nav.dart';
import 'package:perlindungan_konsumen/features/module/presentation/widgets/module_top_bar.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

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
        VideoModuleScreen(
          module: module,
          page: module.firstPage!,
          nav: ModulePageNav.single(),
        ),
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
      // Tanpa journeyModuleIds (dites langsung, bukan lewat ModuleScreen),
      // hasNext selalu false -- label tombol gabungannya jadi "Selesai".
      expect(find.text('Selesai'), findsOneWidget);
    });

    testWidgets(
      'player YouTube tidak dibuat di awal -- baru muncul kalau thumbnail disentuh',
      (tester) async {
        // Regresi: sebelumnya YoutubePlayerController langsung dibuat di
        // initState begitu layar ini muncul (bikin lag transisi buka layar).
        // Sekarang harus ditunda sampai user benar-benar niat nonton.
        final module = videoModuleFixture();
        final repository = FakeModuleRepository();
        await pump(
          tester,
          VideoModuleScreen(
            module: module,
            page: module.firstPage!,
            nav: ModulePageNav.single(),
          ),
          repository,
        );

        expect(find.byType(YoutubePlayer), findsNothing);
      },
    );

    testWidgets('tap Selesai memanggil complete lalu lanjut', (tester) async {
      var advanced = false;
      final module = videoModuleFixture();
      final repository = FakeModuleRepository();
      await pump(
        tester,
        VideoModuleScreen(
          module: module,
          page: module.firstPage!,
          nav: ModulePageNav.single(onAdvance: () => advanced = true),
        ),
        repository,
      );

      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();

      expect(repository.calls, contains('completeModulePage(1010)'));
      expect(advanced, isTrue);
    });
  });

  group('ArticleModuleScreen (materi/infografis/komik/opening)', () {
    testWidgets('merender seluruh jenis block, referensi diberi heading', (
      tester,
    ) async {
      final module = articleModuleFixture();
      final repository = FakeModuleRepository();
      await pump(
        tester,
        ArticleModuleScreen(
          module: module,
          page: module.firstPage!,
          nav: ModulePageNav.single(),
        ),
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
      expect(find.text('Referensi'), findsOneWidget);
      expect(
        find.text('UU No. 8 Tahun 1999 tentang Perlindungan Konsumen.'),
        findsOneWidget,
      );
    });

    testWidgets('tap Selesai menandai module ini selesai lalu lanjut', (
      tester,
    ) async {
      var advanced = false;
      final module = articleModuleFixture(type: ModuleContentType.infografis);
      final repository = FakeModuleRepository();
      await pump(
        tester,
        ArticleModuleScreen(
          module: module,
          page: module.firstPage!,
          nav: ModulePageNav.single(onAdvance: () => advanced = true),
        ),
        repository,
      );

      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();

      expect(repository.calls, contains('completeModulePage(1012)'));
      expect(advanced, isTrue);
    });
  });

  group('QuizModuleScreen', () {
    testWidgets('mulai attempt otomatis begitu layar dibuka', (tester) async {
      final module = quizModuleFixture();
      final repository = FakeModuleRepository();
      await pump(
        tester,
        QuizModuleScreen(
          module: module,
          page: module.firstPage!,
          nav: ModulePageNav.single(),
        ),
        repository,
      );

      expect(repository.calls, contains('startQuizAttempt(100)'));
    });

    testWidgets(
      'satu pertanyaan per halaman -- jawaban dicek dulu (umpan balik) sebelum lanjut',
      (tester) async {
        final module = quizModuleFixture();
        final repository = FakeModuleRepository();
        await pump(
          tester,
          QuizModuleScreen(
            module: module,
            page: module.firstPage!,
            nav: ModulePageNav.single(),
          ),
          repository,
        );

        // Cuma pertanyaan pertama yang tampil, bukan ketiganya sekaligus.
        expect(find.text('PERTANYAAN 1 DARI 3'), findsOneWidget);
        expect(
          find.text('Apa hak dasar konsumen saat belanja online?'),
          findsOneWidget,
        );
        expect(
          find.text('Apa yang sebaiknya disimpan setelah transaksi?'),
          findsNothing,
        );

        final button = tester.widget<FilledButton>(
          find.ancestor(
            of: find.text('Lanjut ke Pertanyaan Berikutnya'),
            matching: find.byType(FilledButton),
          ),
        );
        expect(button.onPressed, isNull);

        await tester.tap(find.text('Mendapat informasi yang benar'));
        await tester.pumpAndSettle();

        final buttonAfterAnswered = tester.widget<FilledButton>(
          find.ancestor(
            of: find.text('Lanjut ke Pertanyaan Berikutnya'),
            matching: find.byType(FilledButton),
          ),
        );
        expect(buttonAfterAnswered.onPressed, isNotNull);

        // Tap PERTAMA -- mengecek jawaban, masih di pertanyaan yang sama
        // tapi opsi jawabannya diganti kartu umpan balik.
        await tester.tap(find.text('Lanjut ke Pertanyaan Berikutnya'));
        await tester.pumpAndSettle();

        expect(find.text('Jawabanmu benar!'), findsOneWidget);
        expect(find.text('PERTANYAAN 1 DARI 3'), findsOneWidget);

        // Tap KEDUA -- baru pindah ke pertanyaan berikutnya.
        await tester.tap(find.text('Lanjut ke Pertanyaan Berikutnya'));
        await tester.pumpAndSettle();

        expect(find.text('PERTANYAAN 2 DARI 3'), findsOneWidget);
      },
    );

    testWidgets('jawab semua benar menampilkan hasil lulus 100%', (
      tester,
    ) async {
      final module = quizModuleFixture();
      final repository = FakeModuleRepository();
      await pump(
        tester,
        QuizModuleScreen(
          module: module,
          page: module.firstPage!,
          nav: ModulePageNav.single(),
        ),
        repository,
      );

      // Q1 -- cek dulu (tap 1), baru lanjut (tap 2).
      await tester.tap(find.text('Mendapat informasi yang benar')); // benar
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lanjut ke Pertanyaan Berikutnya'));
      await tester.pumpAndSettle();
      expect(find.text('Jawabanmu benar!'), findsOneWidget);
      await tester.tap(find.text('Lanjut ke Pertanyaan Berikutnya'));
      await tester.pumpAndSettle();

      // Q2 -- sama.
      await tester.tap(find.text('Bukti transaksi')); // benar
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lanjut ke Pertanyaan Berikutnya'));
      await tester.pumpAndSettle();
      expect(find.text('Jawabanmu benar!'), findsOneWidget);
      await tester.tap(find.text('Lanjut ke Pertanyaan Berikutnya'));
      await tester.pumpAndSettle();

      // Q3 (likert, terakhir) -- tidak ada umpan balik buat likert, jadi cek
      // + lanjut ke hasil terjadi dalam 1 tap saja.
      await tester.tap(find.text('3'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lanjut ke Pertanyaan Berikutnya'));
      await tester.pumpAndSettle();

      expect(repository.calls, contains('checkQuizAnswer(1, 203)'));
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
        QuizModuleScreen(
          module: module,
          page: module.firstPage!,
          nav: ModulePageNav.single(),
        ),
        repository,
      );

      await tester.tap(find.text('Dilarang komplain')); // Q1 salah
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lanjut ke Pertanyaan Berikutnya'));
      await tester.pumpAndSettle();

      // Umpan balik salah menampilkan jawaban yang benar, opsi lama hilang.
      expect(find.text('Jawabanmu belum tepat.'), findsOneWidget);
      expect(
        find.textContaining('Jawaban yang benar adalah A.'),
        findsOneWidget,
      );
      expect(find.text('Dilarang komplain'), findsNothing);

      await tester.tap(find.text('Lanjut ke Pertanyaan Berikutnya'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bukti transaksi')); // Q2 benar
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lanjut ke Pertanyaan Berikutnya'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lanjut ke Pertanyaan Berikutnya'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('3'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lanjut ke Pertanyaan Berikutnya'));
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
        SimulationModuleScreen(
          module: module,
          page: module.firstPage!,
          nav: ModulePageNav.single(),
        ),
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
        SimulationModuleScreen(
          module: module,
          page: module.firstPage!,
          nav: ModulePageNav.single(),
        ),
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
    testWidgets(
      'susun semua langkah dulu baru Cek Jalur, bukan dicek per-taruh',
      (tester) async {
        final module = simulationOrderingModuleFixture();
        final repository = FakeModuleRepository();
        await pump(
          tester,
          SimulationModuleScreen(
            module: module,
            page: module.firstPage!,
            nav: ModulePageNav.single(),
          ),
          repository,
        );

        // Menaruh langkah (tap dari "Langkah Tersedia") TIDAK langsung
        // memicu panggilan cek ke server -- beda dari game matching.
        await tester.tap(find.text('Hubungi penjual'));
        await tester.pumpAndSettle();
        expect(
          repository.calls.where((call) => call.startsWith('checkOrdering')),
          isEmpty,
        );

        await tester.tap(find.text('Ajukan komplain ke platform'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Laporkan ke BPKN'));
        await tester.pumpAndSettle();

        expect(
          repository.calls.where((call) => call.startsWith('checkOrdering')),
          isEmpty,
        );
        expect(find.text('Simulasi selesai!'), findsNothing);

        // Baru begitu "Cek Jalur" ditekan, ketiganya dicek sekaligus.
        await tester.tap(find.text('Cek Jalur'));
        await tester.pumpAndSettle();

        expect(
          repository.calls,
          containsAll([
            'checkOrderingAnswer(1, 601, 1)',
            'checkOrderingAnswer(1, 602, 2)',
            'checkOrderingAnswer(1, 603, 3)',
          ]),
        );
        expect(find.text('Simulasi selesai!'), findsOneWidget);
      },
    );

    testWidgets('bisa diseret (drag) langsung ke slot yang dituju', (
      tester,
    ) async {
      final module = simulationOrderingModuleFixture();
      final repository = FakeModuleRepository();
      await pump(
        tester,
        SimulationModuleScreen(
          module: module,
          page: module.firstPage!,
          nav: ModulePageNav.single(),
        ),
        repository,
      );

      final emptySlotPlaceholder =
          'Seret atau ketuk salah satu langkah di bawah';
      expect(find.text(emptySlotPlaceholder), findsNWidgets(3));

      final slots = find.byType(DragTarget<SimulationOrderingStep>);
      expect(slots, findsNWidgets(3));

      // LongPressDraggable perlu ditahan MELEWATI `delay`-nya dulu sebelum
      // drag beneran mulai -- gerak langsung tanpa jeda dianggap tap biasa.
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Hubungi penjual')),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await gesture.moveTo(tester.getCenter(slots.at(0)));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      // Pindah dari pool ke slot 1 -- tanpa memicu cek ke server sama sekali.
      expect(find.text('Hubungi penjual'), findsOneWidget);
      expect(find.text(emptySlotPlaceholder), findsNWidgets(2));
      expect(
        repository.calls.where((call) => call.startsWith('checkOrdering')),
        isEmpty,
      );
    });

    testWidgets(
      'langkah yang salah posisi dikembalikan ke pool untuk disusun ulang',
      (tester) async {
        final module = simulationOrderingModuleFixture();
        final repository = FakeModuleRepository();
        await pump(
          tester,
          SimulationModuleScreen(
            module: module,
            page: module.firstPage!,
            nav: ModulePageNav.single(),
          ),
          repository,
        );

        // Sengaja disusun terbalik -- "Laporkan ke BPKN" (harusnya posisi 3)
        // ditaruh duluan di posisi 1, dst.
        await tester.tap(find.text('Laporkan ke BPKN'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Ajukan komplain ke platform'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Hubungi penjual'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Cek Jalur'));
        await tester.pumpAndSettle();

        expect(
          find.text('Ada langkah yang belum tepat, susun ulang ya.'),
          findsOneWidget,
        );
        expect(find.text('Simulasi selesai!'), findsNothing);
        // Kembali ke "Langkah Tersedia" supaya bisa disusun ulang.
        expect(find.text('Langkah Tersedia:'), findsOneWidget);
      },
    );

    testWidgets(
      'submit ulang setelah sebagian benar tetap bisa selesai, bukan error '
      '"sudah disubmit"',
      (tester) async {
        final module = simulationOrderingModuleFixture();
        final repository = FakeModuleRepository();
        await pump(
          tester,
          SimulationModuleScreen(
            module: module,
            page: module.firstPage!,
            nav: ModulePageNav.single(),
          ),
          repository,
        );

        // Ronde 1: langkah 1 benar, dua sisanya tertukar.
        await tester.tap(find.text('Hubungi penjual')); // slot 1 -- benar
        await tester.pumpAndSettle();
        await tester.tap(find.text('Laporkan ke BPKN')); // slot 2 -- salah
        await tester.pumpAndSettle();
        await tester.tap(find.text('Ajukan komplain ke platform')); // slot 3 -- salah
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cek Jalur'));
        await tester.pumpAndSettle();

        expect(
          find.text('Ada langkah yang belum tepat, susun ulang ya.'),
          findsOneWidget,
        );
        await tester.tap(find.text('OK')); // tutup alert
        await tester.pumpAndSettle();

        // Ronde 2: perbaiki dua langkah yang salah lalu Cek Jalur lagi.
        await tester.tap(find.text('Ajukan komplain ke platform')); // slot 2
        await tester.pumpAndSettle();
        await tester.tap(find.text('Laporkan ke BPKN')); // slot 3
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cek Jalur'));
        await tester.pumpAndSettle();

        // Selesai bersih -- BUKAN alert "Attempt sudah pernah diselesaikan".
        expect(find.text('Simulasi selesai!'), findsOneWidget);
        expect(find.text('Gagal Mengecek Jawaban'), findsNothing);
      },
    );
  });

  group('ReflectionModuleScreen', () {
    testWidgets('memuat konten dan menyimpan jawaban', (tester) async {
      final module = reflectionModuleFixture();
      final repository = FakeModuleRepository()
        ..reflectionFixture =
            (module.firstPage!.content as ReflectionPageContent).content;
      await pump(
        tester,
        ReflectionModuleScreen(
          module: module,
          page: module.firstPage!,
          nav: ModulePageNav.single(),
        ),
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

    testWidgets(
      'tombol Selesai lanjut tanpa memunculkan alert simpan lagi -- alert '
      'yang ter-pop oleh onAdvance dulu bikin perayaan journey tidak muncul',
      (tester) async {
        final module = reflectionModuleFixture();
        final repository = FakeModuleRepository()
          ..reflectionFixture =
              (module.firstPage!.content as ReflectionPageContent).content;

        var advanced = 0;
        await pump(
          tester,
          ReflectionModuleScreen(
            module: module,
            page: module.firstPage!,
            nav: ModulePageNav.single(onAdvance: () => advanced++),
          ),
          repository,
        );

        await tester.enterText(
          find.byType(TextField),
          'Hak atas informasi yang benar.',
        );
        await tester.tap(find.text('Simpan Jawaban'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK')); // tutup alert simpan pertama
        await tester.pumpAndSettle();

        // Tombol kini "Selesai" -> memanggil _continue (simpan senyap + lanjut).
        await tester.tap(find.text('Selesai'));
        await tester.pumpAndSettle();

        expect(advanced, 1);
        // TIDAK ada alert "Jawaban tersimpan." kedua yang, di alur journey,
        // akan ter-pop oleh nav.onAdvance() dan menelan push layar perayaan.
        expect(find.text('Jawaban tersimpan.'), findsNothing);
      },
    );
  });

  group('ModuleScreen -- module dengan lebih dari satu halaman', () {
    // Gabungan video + artikel jadi satu module 2 halaman -- meniru kasus
    // nyata "video lalu ringkasan bacaan" (lihat Module 2 di seeder backend).
    ModuleDetail multiPageModuleFixture() {
      final video = videoModuleFixture();
      final article = articleModuleFixture();
      return ModuleDetail(
        id: '99',
        type: video.type,
        title: video.title,
        description: video.description,
        estimatedMinutes: video.estimatedMinutes,
        pages: [video.firstPage!, article.firstPage!],
      );
    }

    testWidgets(
      'halaman ke-2 baru terlihat setelah swipe, bukan tersembunyi selamanya',
      (tester) async {
        final module = multiPageModuleFixture();
        final repository = FakeModuleRepository(modules: {'99': module});
        await pump(tester, const ModuleScreen(moduleId: '99'), repository);

        // Halaman 1 (video) tampil duluan, halaman 2 (artikel) belum.
        expect(find.text('Tonton di YouTube'), findsOneWidget);
        expect(find.text('Simpan selalu bukti transaksi.'), findsNothing);

        await tester.drag(find.byType(PageView), const Offset(-800, 0));
        await tester.pumpAndSettle();

        // Setelah swipe, halaman 2 tampil dan halaman 1 sudah tidak.
        expect(find.text('Simpan selalu bukti transaksi.'), findsOneWidget);
        expect(find.text('Tonton di YouTube'), findsNothing);
      },
    );

    testWidgets(
      'header & footer digambar sekali di luar PageView -- tidak ikut menggeser',
      (tester) async {
        final module = multiPageModuleFixture();
        final repository = FakeModuleRepository(modules: {'99': module});
        await pump(tester, const ModuleScreen(moduleId: '99'), repository);

        // Cuma SATU top bar & SATU bottom bar untuk seluruh module (bukan
        // satu set per halaman), dan keduanya di luar `PageView` -- jadi
        // waktu body digeser, header/footer diam.
        expect(find.byType(ModuleTopBar), findsOneWidget);
        expect(find.byType(ModuleBottomBar), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(PageView),
            matching: find.byType(ModuleBottomBar),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: find.byType(PageView),
            matching: find.byType(ModuleTopBar),
          ),
          findsNothing,
        );

        // Footer halaman 1 (video) = tombol "Selanjutnya" (bukan halaman
        // terakhir), berada di dalam bottom bar tetap itu.
        expect(
          find.descendant(
            of: find.byType(ModuleBottomBar),
            matching: find.text('Selanjutnya'),
          ),
          findsOneWidget,
        );

        await tester.drag(find.byType(PageView), const Offset(-800, 0));
        await tester.pumpAndSettle();

        // Setelah swipe: masih satu-satunya, dan footer-nya sudah ganti ke
        // milik halaman 2 (artikel, halaman terakhir tanpa module lain) --
        // "Selesai".
        expect(find.byType(ModuleTopBar), findsOneWidget);
        expect(find.byType(ModuleBottomBar), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(ModuleBottomBar),
            matching: find.text('Selesai'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Selanjutnya: antar-halaman dulu, lalu di halaman terakhir pop dengan '
      'id module berikutnya di journey',
      (tester) async {
        // Satu tombol yang sama dipakai buat pindah ANTAR HALAMAN dalam
        // module ini (halaman 1 -> 2) MAUPUN "menyudahi" module ini. Begitu
        // seluruh halaman beres, ModuleScreen di-pop dengan id module
        // berikutnya -- pemanggil (JourneyDetailScreen) yang membuka module
        // berikutnya + memutuskan menampilkan layar perayaan.
        final module = multiPageModuleFixture();
        final repository = FakeModuleRepository(modules: {'99': module});

        String? poppedWith;
        var popped = false;

        await pump(
          tester,
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    poppedWith = await Navigator.of(context).push<String>(
                      MaterialPageRoute<String>(
                        builder: (_) => const ModuleScreen(
                          moduleId: '99',
                          journeyModuleIds: ['99', '100'],
                        ),
                      ),
                    );
                    popped = true;
                  },
                  child: const Text('buka module'),
                ),
              ),
            ),
          ),
          repository,
        );

        await tester.tap(find.text('buka module'));
        await tester.pumpAndSettle();

        // Halaman 1 (video, BUKAN terakhir) -- Selanjutnya cuma pindah
        // halaman, belum pop.
        expect(find.text('Tonton di YouTube'), findsOneWidget);
        await tester.tap(find.text('Selanjutnya'));
        await tester.pumpAndSettle();
        expect(repository.calls, contains('completeModulePage(1010)'));
        expect(find.text('Simpan selalu bukti transaksi.'), findsOneWidget);
        expect(popped, isFalse);

        // Halaman 2 (artikel, TERAKHIR, ada module berikutnya) -- pop dengan
        // '100'.
        await tester.tap(find.text('Selanjutnya'));
        await tester.pumpAndSettle();
        expect(repository.calls, contains('completeModulePage(1012)'));
        expect(popped, isTrue);
        expect(poppedWith, '100');
      },
    );

    testWidgets(
      'tanpa journeyModuleIds, halaman terakhir menampilkan Selesai (bukan Selanjutnya)',
      (tester) async {
        final module = multiPageModuleFixture();
        final repository = FakeModuleRepository(modules: {'99': module});
        await pump(tester, const ModuleScreen(moduleId: '99'), repository);

        await tester.tap(find.text('Selanjutnya'));
        await tester.pumpAndSettle();

        // Halaman terakhir, tidak ada module berikutnya (tanpa
        // journeyModuleIds) -- labelnya turun jadi "Selesai".
        expect(find.text('Selanjutnya'), findsNothing);
        expect(find.text('Selesai'), findsOneWidget);
      },
    );
  });
}
