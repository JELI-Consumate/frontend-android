// JourneyCelebrationScreen di luar konteks alur penyelesaian journey penuh
// (lihat journey_celebration_flow_test.dart untuk itu) -- cuma variasi
// tampilan berdasarkan data yang diterimanya.

import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perlindungan_konsumen/core/navigation/main_tab_provider.dart';
import 'package:perlindungan_konsumen/features/badges/data/models/badge.dart';
import 'package:perlindungan_konsumen/features/learning/presentation/journey_celebration_screen.dart';

void main() {
  const badgeWithMotivation = Badge(
    id: '1',
    journeyId: '1',
    name: 'Consumer Rights Explorer',
    description: 'Memahami dasar-dasar hak dan kewajiban konsumen.',
    congratulationMessage: 'Selamat! Kamu telah menuntaskan Journey 1.',
    motivationalMessage: 'Yuk lanjut ke Journey 2!',
    iconUrl: null,
    earned: true,
    earnedAt: null,
  );

  Future<void> pump(
    WidgetTester tester,
    Widget screen, {
    ProviderContainer? container,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container ?? ProviderContainer(),
        child: MaterialApp(home: screen),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'tanpa journey berikutnya, tombol lanjut disembunyikan tapi kembali ke beranda tetap ada',
    (tester) async {
      await pump(
        tester,
        const JourneyCelebrationScreen(
          journeyOrder: 4,
          badge: badgeWithMotivation,
          modulesCompleted: 11,
          modulesTotal: 11,
          quizScore: 90,
          nextJourneyId: null,
        ),
      );

      expect(find.text('Lanjut ke Journey Berikutnya'), findsNothing);
      expect(find.text('Kembali ke Beranda'), findsOneWidget);
    },
  );

  testWidgets('tanpa pesan motivasi, captionnya tidak ikut tampil', (
    tester,
  ) async {
    const badgeWithoutMotivation = Badge(
      id: '1',
      journeyId: '1',
      name: 'Consumer Rights Explorer',
      description: 'Memahami dasar-dasar hak dan kewajiban konsumen.',
      congratulationMessage: 'Selamat! Kamu telah menuntaskan Journey 1.',
      motivationalMessage: null,
      iconUrl: null,
      earned: true,
      earnedAt: null,
    );

    await pump(
      tester,
      const JourneyCelebrationScreen(
        journeyOrder: 1,
        badge: badgeWithoutMotivation,
        modulesCompleted: 1,
        modulesTotal: 1,
        quizScore: null,
        nextJourneyId: '2',
      ),
    );

    expect(find.text('Yuk lanjut ke Journey 2!'), findsNothing);
    // Skor kuis null -> tanda strip, bukan "null%" atau kosong diam-diam.
    expect(find.text('–'), findsOneWidget);
  });

  testWidgets(
    'tombol Kembali ke Beranda pindah ke tab pertama lalu pop ke root',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(mainTabIndexProvider.notifier).select(2);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const JourneyCelebrationScreen(
                          journeyOrder: 1,
                          badge: badgeWithMotivation,
                          modulesCompleted: 1,
                          modulesTotal: 1,
                          quizScore: 100,
                          nextJourneyId: '2',
                        ),
                      ),
                    ),
                    child: const Text('buka perayaan'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('buka perayaan'));
      await tester.pumpAndSettle();
      expect(find.text('PENCAPAIAN BARU!'), findsOneWidget);

      await tester.tap(find.text('Kembali ke Beranda'));
      await tester.pumpAndSettle();

      expect(find.text('buka perayaan'), findsOneWidget);
      expect(find.text('PENCAPAIAN BARU!'), findsNothing);
      expect(container.read(mainTabIndexProvider), 0);
    },
  );
}
