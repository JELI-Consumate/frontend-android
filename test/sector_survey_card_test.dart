// SectorSurveyCard di luar konteks JourneysScreen -- alur buka link lalu
// self-report selesai (lihat learning_flow_test.dart untuk kapan kartu ini
// tampil/tidak di layar Perjalanan).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perlindungan_konsumen/core/network/api_exception.dart';
import 'package:perlindungan_konsumen/features/learning/presentation/widgets/sector_survey_card.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'tombol "Saya Sudah Mengisi" baru muncul setelah link berhasil dibuka',
    (tester) async {
      await pump(
        tester,
        SectorSurveyCard(
          title: 'Survei Pretest Sektor',
          description: 'Isi survei singkat ini.',
          link: 'https://forms.gle/pretest-abc',
          openLink: (_) async => true,
          onComplete: () async {},
        ),
      );

      expect(find.text('Saya Sudah Mengisi'), findsNothing);

      await tester.tap(find.text('Buka Google Form'));
      await tester.pumpAndSettle();

      expect(find.text('Saya Sudah Mengisi'), findsOneWidget);
    },
  );

  testWidgets('tap "Saya Sudah Mengisi" memanggil onComplete', (tester) async {
    var completed = 0;

    await pump(
      tester,
      SectorSurveyCard(
        title: 'Survei Pretest Sektor',
        description: 'Isi survei singkat ini.',
        link: 'https://forms.gle/pretest-abc',
        openLink: (_) async => true,
        onComplete: () async => completed++,
      ),
    );

    await tester.tap(find.text('Buka Google Form'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saya Sudah Mengisi'));
    await tester.pumpAndSettle();

    expect(completed, 1);
  });

  testWidgets('link gagal dibuka menampilkan alert, bukan tombol konfirmasi', (
    tester,
  ) async {
    await pump(
      tester,
      SectorSurveyCard(
        title: 'Survei Pretest Sektor',
        description: 'Isi survei singkat ini.',
        link: 'https://forms.gle/pretest-abc',
        openLink: (_) async => false,
        onComplete: () async {},
      ),
    );

    await tester.tap(find.text('Buka Google Form'));
    await tester.pumpAndSettle();

    expect(find.text('Gagal Membuka Form'), findsOneWidget);
    expect(find.text('Saya Sudah Mengisi'), findsNothing);
  });

  testWidgets('onComplete gagal menampilkan pesan error dari server', (
    tester,
  ) async {
    await pump(
      tester,
      SectorSurveyCard(
        title: 'Survei Pretest Sektor',
        description: 'Isi survei singkat ini.',
        link: 'https://forms.gle/pretest-abc',
        openLink: (_) async => true,
        onComplete: () async {
          throw const ApiException(
            message: 'Sektor ini belum punya link survei pretest.',
          );
        },
      ),
    );

    await tester.tap(find.text('Buka Google Form'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saya Sudah Mengisi'));
    await tester.pumpAndSettle();

    expect(
      find.text('Sektor ini belum punya link survei pretest.'),
      findsOneWidget,
    );
  });
}
