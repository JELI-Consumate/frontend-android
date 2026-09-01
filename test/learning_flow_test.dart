// Perilaku layar Dashboard, Perjalanan, dan detail journey.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perlindungan_konsumen/core/network/api_exception.dart';
import 'package:perlindungan_konsumen/core/storage/sector_storage.dart';
import 'package:perlindungan_konsumen/core/theme/app_theme.dart';
import 'package:perlindungan_konsumen/features/auth/application/auth_controller.dart';
import 'package:perlindungan_konsumen/features/auth/data/models/app_user.dart';
import 'package:perlindungan_konsumen/features/learning/data/learning_repository.dart';
import 'package:perlindungan_konsumen/features/learning/data/models/journey.dart';
import 'package:perlindungan_konsumen/features/learning/data/models/learning_status.dart';
import 'package:perlindungan_konsumen/features/learning/data/models/sector.dart';
import 'package:perlindungan_konsumen/features/learning/data/models/sector_survey.dart';
import 'package:perlindungan_konsumen/features/main/presentation/dashboard_screen.dart';
import 'package:perlindungan_konsumen/features/main/presentation/journeys_screen.dart';
import 'package:perlindungan_konsumen/features/module/data/module_repository.dart';

import 'support/fake_learning_repository.dart';
import 'support/fake_module_repository.dart';
import 'support/fake_sector_storage.dart';
import 'support/module_fixtures.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget screen,
    FakeLearningRepository repository, {
    FakeModuleRepository? moduleRepository,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          learningRepositoryProvider.overrideWithValue(repository),
          currentUserProvider.overrideWithValue(
            const AppUser(id: '1', name: 'Argy', email: 'argy@example.com'),
          ),
          // DashboardScreen/JourneysScreen sekarang lewat
          // primarySectorDetailProvider -> selectedSectorSlugProvider ->
          // sectorStorageProvider -- tanpa override ini providernya akan
          // coba baca flutter_secure_storage sungguhan (tidak ada plugin
          // di widget test).
          sectorStorageProvider.overrideWithValue(
            FakeSectorStorage(initialSlug: 'e-commerce'),
          ),
          // Cuma benar-benar dibaca kalau test menavigasi ke ModuleScreen
          // (lihat grup JourneyDetailScreen di bawah) -- provider Riverpod
          // malas, jadi aman dioverride di semua test lewat helper ini.
          moduleRepositoryProvider.overrideWithValue(
            moduleRepository ?? FakeModuleRepository(),
          ),
        ],
        child: MaterialApp(theme: AppTheme.light, home: screen),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('DashboardScreen', () {
    testWidgets('sapaan pakai nama user yang sedang login', (tester) async {
      final repository = FakeLearningRepository();
      await pump(tester, const DashboardScreen(), repository);

      expect(find.textContaining('Argy'), findsWidgets);
    });

    testWidgets('journey in_progress muncul di kartu Lanjutkan Belajar', (
      tester,
    ) async {
      final repository = FakeLearningRepository();
      await pump(tester, const DashboardScreen(), repository);

      expect(find.text('Lanjutkan Belajar'), findsOneWidget);
      // Module pertama yang belum selesai (id 2) yang jadi judul kartu,
      // bukan judul journey-nya.
      expect(
        find.text('Pentingnya Perlindungan Konsumen dalam E-Commerce'),
        findsOneWidget,
      );
      expect(find.text('10 menit tersisa'), findsOneWidget);
    });

    testWidgets('tanpa progress sama sekali, kartu lanjutkan belajar hilang', (
      tester,
    ) async {
      final journeys = FakeLearningRepository.defaultJourneys
          .map(
            (j) => j.id == '1'
                ? Journey(
                    id: j.id,
                    slug: j.slug,
                    title: j.title,
                    description: j.description,
                    order: j.order,
                    estimatedMinutes: j.estimatedMinutes,
                    isUnlocked: j.isUnlocked,
                    modulesCount: j.modulesCount,
                    progress: LearningProgress.zero,
                  )
                : j,
          )
          .toList();
      final repository = FakeLearningRepository(journeys: journeys);
      await pump(tester, const DashboardScreen(), repository);

      expect(find.text('Lanjutkan Belajar'), findsNothing);
      expect(find.text('Perjalanan'), findsOneWidget);
    });

    testWidgets('gagal memuat menampilkan pesan error', (tester) async {
      final repository = FakeLearningRepository()
        ..failWith = const ApiException(message: 'Server bermasalah.');
      await pump(tester, const DashboardScreen(), repository);

      expect(
        find.textContaining('Gagal memuat data pembelajaran'),
        findsOneWidget,
      );
    });
  });

  group('JourneysScreen', () {
    testWidgets('journey terbuka tampil dengan progress, sisanya terkunci', (
      tester,
    ) async {
      final repository = FakeLearningRepository();
      await pump(tester, const JourneysScreen(), repository);

      expect(find.text('Kenali Hakmu sebagai Konsumen'), findsOneWidget);
      expect(find.text('12 Materi'), findsOneWidget);
      expect(find.text('2%'), findsOneWidget);

      // 3 journey lain terkunci (belum menyelesaikan journey 1).
      expect(find.text('Selesaikan journey sebelumnya'), findsNWidgets(3));
    });

    testWidgets('tap journey terbuka masuk ke detail', (tester) async {
      final repository = FakeLearningRepository();
      await pump(tester, const JourneysScreen(), repository);

      await tester.tap(find.text('Kenali Hakmu sebagai Konsumen'));
      await tester.pumpAndSettle();

      expect(find.text('Journey 1'), findsOneWidget);
      expect(find.text('Progres Belajar'), findsOneWidget);
    });

    testWidgets('tap journey terkunci tidak melakukan apa-apa', (tester) async {
      final repository = FakeLearningRepository();
      await pump(tester, const JourneysScreen(), repository);

      await tester.tap(find.text('Belanja Online dengan Lebih Cerdas'));
      await tester.pumpAndSettle();

      expect(find.text('Progres Belajar'), findsNothing);
    });
  });

  group('JourneysScreen survei sektor', () {
    Sector sectorWithSurveys({SectorSurvey? pretest, SectorSurvey? posttest}) {
      final defaultSector = FakeLearningRepository.defaultSector;
      return Sector(
        id: defaultSector.id,
        slug: defaultSector.slug,
        name: defaultSector.name,
        description: defaultSector.description,
        iconUrl: defaultSector.iconUrl,
        color: defaultSector.color,
        order: defaultSector.order,
        progress: defaultSector.progress,
        surveys: SectorSurveys(
          pretest: pretest ?? SectorSurvey.empty,
          posttest: posttest ?? SectorSurvey.empty,
        ),
      );
    }

    testWidgets(
      'kartu pretest tampil kalau link dikonfigurasi & belum selesai',
      (tester) async {
        final repository = FakeLearningRepository(
          sector: sectorWithSurveys(
            pretest: const SectorSurvey(
              link: 'https://forms.gle/pretest-abc',
              completedAt: null,
            ),
          ),
        );
        await pump(tester, const JourneysScreen(), repository);

        expect(find.text('Survei Pretest Sektor'), findsOneWidget);
      },
    );

    testWidgets('kartu pretest tidak tampil kalau link belum dikonfigurasi', (
      tester,
    ) async {
      final repository = FakeLearningRepository(sector: sectorWithSurveys());
      await pump(tester, const JourneysScreen(), repository);

      expect(find.text('Survei Pretest Sektor'), findsNothing);
    });

    testWidgets(
      'kartu pretest tidak tampil kalau sudah pernah ditandai selesai',
      (tester) async {
        final repository = FakeLearningRepository(
          sector: sectorWithSurveys(
            pretest: SectorSurvey(
              link: 'https://forms.gle/pretest-abc',
              completedAt: DateTime(2026),
            ),
          ),
        );
        await pump(tester, const JourneysScreen(), repository);

        expect(find.text('Survei Pretest Sektor'), findsNothing);
      },
    );

    testWidgets(
      'kartu posttest TIDAK tampil selama belum seluruh journey selesai',
      (tester) async {
        // Fixture default: journey 1 in_progress, 3 lainnya terkunci --
        // belum "seluruh journey selesai".
        final repository = FakeLearningRepository(
          sector: sectorWithSurveys(
            posttest: const SectorSurvey(
              link: 'https://forms.gle/posttest-abc',
              completedAt: null,
            ),
          ),
        );
        await pump(tester, const JourneysScreen(), repository);

        expect(find.text('Survei Posttest Sektor'), findsNothing);
      },
    );

    testWidgets(
      'kartu posttest tampil begitu seluruh journey selesai & link dikonfigurasi',
      (tester) async {
        final allCompleted = FakeLearningRepository.defaultJourneys
            .map(
              (journey) => Journey(
                id: journey.id,
                slug: journey.slug,
                title: journey.title,
                description: journey.description,
                order: journey.order,
                estimatedMinutes: journey.estimatedMinutes,
                isUnlocked: true,
                modulesCount: journey.modulesCount,
                progress: const LearningProgress(
                  status: LearningStatus.completed,
                  percent: 100,
                ),
              ),
            )
            .toList();

        final repository = FakeLearningRepository(
          journeys: allCompleted,
          sector: sectorWithSurveys(
            posttest: const SectorSurvey(
              link: 'https://forms.gle/posttest-abc',
              completedAt: null,
            ),
          ),
        );
        await pump(tester, const JourneysScreen(), repository);

        // 4 journey card + kartu survei sekaligus tidak muat di satu layar --
        // ListView men-virtualisasi item di luar viewport+cache, jadi harus
        // digulir dulu sebelum finder-nya ketemu (bukan cuma soal terlihat).
        await tester.scrollUntilVisible(
          find.text('Survei Posttest Sektor'),
          300,
        );

        expect(find.text('Survei Posttest Sektor'), findsOneWidget);
      },
    );
  });

  group('JourneyDetailScreen', () {
    testWidgets('checklist menampilkan status selesai/berjalan/berikutnya', (
      tester,
    ) async {
      final repository = FakeLearningRepository();
      await pump(tester, const JourneysScreen(), repository);
      await tester.tap(find.text('Kenali Hakmu sebagai Konsumen'));
      await tester.pumpAndSettle();

      // Fraksi module selesai dari 5 module fixture (1 selesai).
      // Subtitle-nya sekarang beberapa Text terpisah (ikon + label + "•" +
      // status), bukan satu string gabungan lagi -- cek tiap bagiannya.
      expect(find.text('1/5'), findsOneWidget);
      expect(find.text('Opening'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);
      expect(find.text('Video'), findsOneWidget); // module current (id 2)
      expect(find.text('10 menit'), findsOneWidget);
    });

    testWidgets('tap module membuka layar konsumsi konten sesuai tipenya', (
      tester,
    ) async {
      final repository = FakeLearningRepository();
      // Module id 2 di fixture default ("Pentingnya Perlindungan Konsumen
      // dalam E-Commerce") bertipe video -- lihat isi lengkap tiap tipe
      // konten di `module_flow_test.dart`, di sini cukup pastikan
      // navigasinya benar-benar terjadi ke layar yang sesuai.
      final moduleRepository = FakeModuleRepository(
        modules: {'2': videoModuleFixture()},
      );
      await pump(
        tester,
        const JourneysScreen(),
        repository,
        moduleRepository: moduleRepository,
      );
      await tester.tap(find.text('Kenali Hakmu sebagai Konsumen'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.text('2. Pentingnya Perlindungan Konsumen dalam E-Commerce'),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Apa risiko belanja online yang paling sering kamu temui?'),
        findsOneWidget,
      );

      await tester.pageBack();
      await tester.pumpAndSettle();

      // Kembali dari ModuleScreen me-refresh checklist journey ini --
      // panggilan `journeyDetail` bertambah lagi (sekali waktu buka layar,
      // sekali lagi waktu kembali).
      expect(
        repository.calls.where((call) => call.startsWith('journeyDetail')),
        hasLength(2),
      );
    });

    testWidgets('module terkunci menampilkan gembok dan tidak bisa disentuh', (
      tester,
    ) async {
      final repository = FakeLearningRepository();
      // Module id 3 di fixture default ("Mengenal Aturan Hukum Saat Belanja
      // Online") terkunci -- module 2 sebelumnya belum completed.
      final moduleRepository = FakeModuleRepository(
        modules: {'3': articleModuleFixture()},
      );
      await pump(
        tester,
        const JourneysScreen(),
        repository,
        moduleRepository: moduleRepository,
      );
      await tester.tap(find.text('Kenali Hakmu sebagai Konsumen'));
      await tester.pumpAndSettle();

      expect(find.text('Selesaikan modul sebelumnya'), findsOneWidget);

      await tester.tap(
        find.text('3. Mengenal Aturan Hukum Saat Belanja Online'),
      );
      await tester.pumpAndSettle();

      // Tidak menavigasi kemana-mana -- masih di layar detail journey.
      expect(find.text('Progres Belajar'), findsOneWidget);
      expect(moduleRepository.calls, isEmpty);
    });
  });
}
