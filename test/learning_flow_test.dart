// Perilaku layar Dashboard, Perjalanan, dan detail journey.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perlindungan_konsumen/core/network/api_exception.dart';
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

import 'support/active_sector_override.dart';
import 'support/fake_learning_repository.dart';
import 'support/fake_module_repository.dart';
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
          // DashboardScreen/JourneysScreen lewat primarySectorDetailProvider
          // -> activeSectorSlugProvider. Seed 'e-commerce' supaya langsung ke
          // kontennya, tidak mampir ke SectorSelectionScreen.
          activeSectorOverride('e-commerce'),
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

  group('Survei sektor', () {
    Sector sectorWithSurveys({SectorSurvey? pretest, SectorSurvey? posttest}) {
      final base = FakeLearningRepository.defaultSector;
      return Sector(
        id: base.id,
        slug: base.slug,
        name: base.name,
        description: base.description,
        iconUrl: base.iconUrl,
        color: base.color,
        order: base.order,
        progress: base.progress,
        surveys: SectorSurveys(
          pretest: pretest ?? SectorSurvey.empty,
          posttest: posttest ?? SectorSurvey.empty,
        ),
      );
    }

    List<Journey> journeysWithStatus(
      LearningStatus status, {
      bool firstUnlocked = true,
    }) {
      return FakeLearningRepository.defaultJourneys
          .map(
            (journey) => Journey(
              id: journey.id,
              slug: journey.slug,
              title: journey.title,
              description: journey.description,
              order: journey.order,
              estimatedMinutes: journey.estimatedMinutes,
              isUnlocked: firstUnlocked && journey.order == 1
                  ? true
                  : status == LearningStatus.completed,
              modulesCount: journey.modulesCount,
              progress: LearningProgress(
                status: status,
                percent: status == LearningStatus.completed ? 100 : 0,
              ),
            ),
          )
          .toList();
    }

    List<Journey> allJourneysCompleted() =>
        journeysWithStatus(LearningStatus.completed);

    List<Journey> noJourneyStarted() =>
        journeysWithStatus(LearningStatus.notStarted);

    group('DashboardScreen kartu pre-test', () {
      testWidgets(
        'tampil saat pretest dikonfigurasi & belum ada journey dikerjakan',
        (tester) async {
          final repository = FakeLearningRepository(
            journeys: noJourneyStarted(),
            sector: sectorWithSurveys(
              pretest: const SectorSurvey(
                link: 'https://forms.gle/pretest-abc',
                completedAt: null,
              ),
            ),
          );
          await pump(tester, const DashboardScreen(), repository);

          expect(find.text('Survei Pre-Test Sektor'), findsOneWidget);
        },
      );

      testWidgets('tidak tampil kalau ada journey yang sudah dikerjakan', (
        tester,
      ) async {
        // Fixture default: journey 1 sudah in_progress.
        final repository = FakeLearningRepository(
          sector: sectorWithSurveys(
            pretest: const SectorSurvey(
              link: 'https://forms.gle/pretest-abc',
              completedAt: null,
            ),
          ),
        );
        await pump(tester, const DashboardScreen(), repository);

        expect(find.text('Survei Pre-Test Sektor'), findsNothing);
      });

      testWidgets('tidak tampil kalau pretest sudah ditandai selesai', (
        tester,
      ) async {
        final repository = FakeLearningRepository(
          journeys: noJourneyStarted(),
          sector: sectorWithSurveys(
            pretest: SectorSurvey(
              link: 'https://forms.gle/pretest-abc',
              completedAt: DateTime(2026),
            ),
          ),
        );
        await pump(tester, const DashboardScreen(), repository);

        expect(find.text('Survei Pre-Test Sektor'), findsNothing);
      });

      testWidgets('tidak tampil kalau link pretest belum dikonfigurasi', (
        tester,
      ) async {
        final repository = FakeLearningRepository(
          journeys: noJourneyStarted(),
          sector: sectorWithSurveys(),
        );
        await pump(tester, const DashboardScreen(), repository);

        expect(find.text('Survei Pre-Test Sektor'), findsNothing);
      });
    });

    group('JourneysScreen gerbang pre-test', () {
      testWidgets('journey 1 terkunci dengan hint pre-test & tidak bisa ditap', (
        tester,
      ) async {
        final repository = FakeLearningRepository(
          journeys: noJourneyStarted(),
          sector: sectorWithSurveys(
            pretest: const SectorSurvey(
              link: 'https://forms.gle/pretest-abc',
              completedAt: null,
            ),
          ),
        );
        await pump(tester, const JourneysScreen(), repository);

        expect(find.text('Selesaikan Pre-Test dulu'), findsOneWidget);

        await tester.tap(find.text('Kenali Hakmu sebagai Konsumen'));
        await tester.pumpAndSettle();

        // Tetap di daftar journey -- detail tidak terbuka.
        expect(find.text('Progres Belajar'), findsNothing);
      });

      testWidgets('journey 1 kebuka lagi setelah pretest ditandai selesai', (
        tester,
      ) async {
        final repository = FakeLearningRepository(
          journeys: noJourneyStarted(),
          sector: sectorWithSurveys(
            pretest: SectorSurvey(
              link: 'https://forms.gle/pretest-abc',
              completedAt: DateTime(2026),
            ),
          ),
        );
        await pump(tester, const JourneysScreen(), repository);

        expect(find.text('Selesaikan Pre-Test dulu'), findsNothing);

        await tester.tap(find.text('Kenali Hakmu sebagai Konsumen'));
        await tester.pumpAndSettle();

        expect(find.text('Progres Belajar'), findsOneWidget);
      });
    });

    group('DashboardScreen survei post-test', () {
      testWidgets(
        'kartu post-test tidak tampil selama belum semua journey selesai',
        (tester) async {
          // Fixture default: journey 1 in_progress, sisanya terkunci.
          final repository = FakeLearningRepository(
            sector: sectorWithSurveys(
              posttest: const SectorSurvey(
                link: 'https://forms.gle/posttest-abc',
                completedAt: null,
              ),
            ),
          );
          await pump(tester, const DashboardScreen(), repository);

          expect(find.text('Survei Post-Test Sektor'), findsNothing);
        },
      );

      testWidgets(
        'kartu post-test tampil begitu semua journey selesai & link ada',
        (tester) async {
          final repository = FakeLearningRepository(
            journeys: allJourneysCompleted(),
            sector: sectorWithSurveys(
              posttest: const SectorSurvey(
                link: 'https://forms.gle/posttest-abc',
                completedAt: null,
              ),
            ),
          );
          await pump(tester, const DashboardScreen(), repository);

          expect(find.text('Survei Post-Test Sektor'), findsOneWidget);
        },
      );

      testWidgets('kartu post-test tidak tampil kalau sudah ditandai selesai', (
        tester,
      ) async {
        final repository = FakeLearningRepository(
          journeys: allJourneysCompleted(),
          sector: sectorWithSurveys(
            posttest: SectorSurvey(
              link: 'https://forms.gle/posttest-abc',
              completedAt: DateTime(2026),
            ),
          ),
        );
        await pump(tester, const DashboardScreen(), repository);

        expect(find.text('Survei Post-Test Sektor'), findsNothing);
      });
    });
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
