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
import 'package:perlindungan_konsumen/features/learning/presentation/dashboard_screen.dart';
import 'package:perlindungan_konsumen/features/learning/presentation/journeys_screen.dart';

import 'support/fake_learning_repository.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget screen,
    FakeLearningRepository repository,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          learningRepositoryProvider.overrideWithValue(repository),
          currentUserProvider.overrideWithValue(
            const AppUser(id: 1, name: 'Argy', email: 'argy@example.com'),
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
            (j) => j.id == 1
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

  group('JourneyDetailScreen', () {
    testWidgets('checklist menampilkan status selesai/berjalan/berikutnya', (
      tester,
    ) async {
      final repository = FakeLearningRepository();
      await pump(tester, const JourneysScreen(), repository);
      await tester.tap(find.text('Kenali Hakmu sebagai Konsumen'));
      await tester.pumpAndSettle();

      // Fraksi module selesai dari 5 module fixture (1 selesai).
      expect(find.text('1/5'), findsOneWidget);
      expect(find.text('Opening · Selesai'), findsOneWidget);
      expect(
        find.text('Video · 10 menit'),
        findsOneWidget,
      ); // module current (id 2)
    });

    testWidgets('tap module memunculkan pesan belum tersedia', (tester) async {
      final repository = FakeLearningRepository();
      await pump(tester, const JourneysScreen(), repository);
      await tester.tap(find.text('Kenali Hakmu sebagai Konsumen'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.text('2. Pentingnya Perlindungan Konsumen dalam E-Commerce'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Materi ini belum tersedia.'), findsOneWidget);
    });
  });
}
