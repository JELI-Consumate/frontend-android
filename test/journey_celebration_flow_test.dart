// Alur "journey baru saja selesai" -- dari JourneyDetailScreen, lewat
// ModuleScreen, sampai JourneyCelebrationScreen terbuka dengan data yang
// benar (badge, ringkasan modul, skor kuis, journey berikutnya).

import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perlindungan_konsumen/features/badges/data/badge_repository.dart';
import 'package:perlindungan_konsumen/features/badges/data/models/badge.dart';
import 'package:perlindungan_konsumen/features/learning/data/learning_repository.dart';
import 'package:perlindungan_konsumen/features/learning/data/models/journey.dart';
import 'package:perlindungan_konsumen/features/learning/data/models/learning_module.dart';
import 'package:perlindungan_konsumen/features/learning/data/models/learning_status.dart';
import 'package:perlindungan_konsumen/features/learning/presentation/journey_detail_screen.dart';
import 'package:perlindungan_konsumen/features/module/data/module_repository.dart';

import 'support/active_sector_override.dart';
import 'support/fake_badge_repository.dart';
import 'support/fake_learning_repository.dart';
import 'support/fake_module_repository.dart';
import 'support/module_fixtures.dart';

void main() {
  // Journey 1 sengaja disusun dengan CUMA SATU module ("Mengenal Aturan
  // Hukum...", id 12 -- fixture yang sama dipakai module_flow_test.dart)
  // yang belum selesai, supaya menuntaskannya lewat tombol "Selesai" di
  // ArticleModuleScreen langsung membuat journey 1 selesai juga -- tanpa
  // perlu menyusun seluruh 12 module asli journey 1 di fixture.
  Journey inProgressJourney1() => const Journey(
    id: '1',
    slug: 'kenali-hakmu-sebagai-konsumen',
    title: 'Kenali Hakmu sebagai Konsumen',
    description: null,
    order: 1,
    estimatedMinutes: 5,
    isUnlocked: true,
    modulesCount: 1,
    progress: LearningProgress(status: LearningStatus.inProgress, percent: 0),
  );

  Journey completedJourney1() => const Journey(
    id: '1',
    slug: 'kenali-hakmu-sebagai-konsumen',
    title: 'Kenali Hakmu sebagai Konsumen',
    description: null,
    order: 1,
    estimatedMinutes: 5,
    isUnlocked: true,
    modulesCount: 1,
    progress: LearningProgress(status: LearningStatus.completed, percent: 100),
  );

  Journey lockedJourney2() => const Journey(
    id: '2',
    slug: 'belanja-online-dengan-lebih-cerdas',
    title: 'Belanja Online dengan Lebih Cerdas',
    description: null,
    order: 2,
    estimatedMinutes: 10,
    isUnlocked: false,
    modulesCount: 1,
    progress: LearningProgress.zero,
  );

  Journey unlockedJourney2() => const Journey(
    id: '2',
    slug: 'belanja-online-dengan-lebih-cerdas',
    title: 'Belanja Online dengan Lebih Cerdas',
    description: null,
    order: 2,
    estimatedMinutes: 10,
    isUnlocked: true,
    modulesCount: 1,
    progress: LearningProgress.zero,
  );

  const soloModule = LearningModule(
    id: '12',
    type: ModuleContentType.materi,
    title: 'Mengenal Aturan Hukum Saat Belanja Online',
    description: null,
    order: 1,
    estimatedMinutes: 5,
    isRequired: true,
    progress: LearningProgress.zero,
    locked: false,
  );

  const completedSoloModule = LearningModule(
    id: '12',
    type: ModuleContentType.materi,
    title: 'Mengenal Aturan Hukum Saat Belanja Online',
    description: null,
    order: 1,
    estimatedMinutes: 5,
    isRequired: true,
    progress: LearningProgress(status: LearningStatus.completed, percent: 100),
    locked: false,
  );

  Future<
    ({
      FakeLearningRepository learning,
      FakeBadgeRepository badge,
      FakeModuleRepository module,
    })
  >
  pumpAlmostDoneJourney(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final learningRepository = FakeLearningRepository(
      journeys: [inProgressJourney1(), lockedJourney2()],
      modules: [soloModule],
    );
    final badgeRepository = FakeBadgeRepository(
      items: [
        Badge(
          id: '1',
          journeyId: '1',
          name: 'Consumer Rights Explorer',
          description: 'Memahami dasar-dasar hak dan kewajiban konsumen.',
          congratulationMessage: 'Selamat! Kamu telah menuntaskan Journey 1.',
          motivationalMessage: 'Yuk lanjut ke Journey 2!',
          iconUrl: null,
          earned: true,
          earnedAt: DateTime.utc(2026, 1, 10),
        ),
      ],
    );

    // Efek samping "server" begitu satu-satunya module journey 1 ditandai
    // selesai -- meniru apa yang beneran terjadi di backend secara
    // sinkron (ProgressService::recalculateJourney + AwardJourneyBadge)
    // lewat mutasi manual ke fixture, karena fake ini tidak punya mesin
    // kalkulasi progress sungguhan.
    final moduleRepository = FakeModuleRepository(
      modules: {'12': articleModuleFixture()},
      onComplete: (_) {
        learningRepository.modules = [completedSoloModule];
        learningRepository.journeys = [completedJourney1(), unlockedJourney2()];
        learningRepository.quizScore = 100;
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          learningRepositoryProvider.overrideWithValue(learningRepository),
          badgeRepositoryProvider.overrideWithValue(badgeRepository),
          moduleRepositoryProvider.overrideWithValue(moduleRepository),
          activeSectorOverride('e-commerce'),
        ],
        child: const MaterialApp(home: JourneyDetailScreen(journeyId: '1')),
      ),
    );
    await tester.pumpAndSettle();

    return (
      learning: learningRepository,
      badge: badgeRepository,
      module: moduleRepository,
    );
  }

  testWidgets(
    'menuntaskan module terakhir journey membuka layar perayaan dengan data yang benar',
    (tester) async {
      await pumpAlmostDoneJourney(tester);

      await tester.tap(
        find.text('1. Mengenal Aturan Hukum Saat Belanja Online'),
      );
      await tester.pumpAndSettle();

      // Masih di dalam ArticleModuleScreen, konten fixture-nya tampil.
      expect(find.text('Selesai'), findsOneWidget);

      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();

      expect(find.text('PENCAPAIAN BARU!'), findsOneWidget);
      expect(find.text('Journey 1 Selesai'), findsOneWidget);
      expect(find.text('Consumer Rights Explorer'), findsOneWidget);
      expect(
        find.text('Selamat! Kamu telah menuntaskan Journey 1.'),
        findsOneWidget,
      );
      expect(find.text('Yuk lanjut ke Journey 2!'), findsOneWidget);
      expect(find.text('Ringkasan Journey 1'), findsOneWidget);
      expect(find.text('1/1'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('Lanjut ke Journey Berikutnya'), findsOneWidget);
      expect(find.text('Kembali ke Beranda'), findsOneWidget);
    },
  );

  testWidgets(
    'tombol Lanjut ke Journey Berikutnya membuka detail journey berikutnya',
    (tester) async {
      await pumpAlmostDoneJourney(tester);

      await tester.tap(
        find.text('1. Mengenal Aturan Hukum Saat Belanja Online'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lanjut ke Journey Berikutnya'));
      await tester.pumpAndSettle();

      expect(find.text('Belanja Online dengan Lebih Cerdas'), findsOneWidget);
    },
  );

  testWidgets(
    'membuka ulang journey yang memang sudah lama selesai tidak memunculkan layar perayaan lagi',
    (tester) async {
      final learningRepository = FakeLearningRepository(
        journeys: [completedJourney1(), lockedJourney2()],
        modules: [completedSoloModule],
      );
      final moduleRepository = FakeModuleRepository(
        modules: {'12': articleModuleFixture(status: LearningStatus.completed)},
      );

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            learningRepositoryProvider.overrideWithValue(learningRepository),
            badgeRepositoryProvider.overrideWithValue(FakeBadgeRepository()),
            moduleRepositoryProvider.overrideWithValue(moduleRepository),
            activeSectorOverride('e-commerce'),
          ],
          child: const MaterialApp(home: JourneyDetailScreen(journeyId: '1')),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.text('1. Mengenal Aturan Hukum Saat Belanja Online'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();

      expect(find.text('PENCAPAIAN BARU!'), findsNothing);
      // Balik ke JourneyDetailScreen seperti biasa, bukan ke celebration.
      expect(find.text('Progres Belajar'), findsOneWidget);
    },
  );
}
