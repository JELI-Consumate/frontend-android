// Layar "Pilih Sektor" versi grid: kartu per sektor (warna dari field
// `color`), sektor pertama terpilih otomatis, panel bawah mengikuti pilihan,
// dan "Mulai Belajar" yang menyetel sektor aktif sesi ini (bukan tap kartu).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perlindungan_konsumen/core/theme/app_theme.dart';
import 'package:perlindungan_konsumen/features/learning/data/learning_repository.dart';
import 'package:perlindungan_konsumen/features/learning/data/models/learning_status.dart';
import 'package:perlindungan_konsumen/features/learning/data/models/sector.dart';
import 'package:perlindungan_konsumen/features/onboarding/application/sector_selection_provider.dart';
import 'package:perlindungan_konsumen/features/onboarding/presentation/sector_selection_screen.dart';

import 'support/fake_learning_repository.dart';

Sector _sector(String slug, String name, {String? color}) => Sector(
  id: slug,
  slug: slug,
  name: name,
  description: 'Deskripsi singkat sektor $name.',
  iconUrl: null,
  color: color,
  order: 1,
  progress: const LearningProgress(
    status: LearningStatus.notStarted,
    percent: 0,
  ),
);

final _sectors = [
  _sector('e-commerce', 'E-Commerce', color: '#0037B0'),
  _sector('kesehatan', 'Layanan Kesehatan', color: '#1E9E5A'),
  _sector('transportasi', 'Jasa Transportasi', color: '#7A3FF2'),
  _sector('perumahan', 'Perumahan, Air & Sanitasi', color: '#E9A23B'),
  _sector('keuangan', 'Jasa Keuangan & Asuransi', color: '#1E9E5A'),
  _sector('obat-makanan', 'Obat, Kosmetika & Makanan', color: '#E9A23B'),
  _sector('elektronik', 'Elektronik & Kendaraan Bermotor'),
  _sector('energi', 'Listrik, BBM & Gas Rumah Tangga', color: '#D1344B'),
];

void main() {
  Future<ProviderContainer> pump(
    WidgetTester tester, {
    Size size = const Size(1170, 12000),
  }) async {
    // Default sengaja sangat tinggi supaya seluruh grid (8 kartu) ter-build
    // tanpa perlu scroll -- GridView memvirtualisasi item di luar viewport.
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        learningRepositoryProvider.overrideWithValue(
          FakeLearningRepository(sectorList: _sectors),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const SectorSelectionScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('menampilkan judul, semua kartu sektor, dan panel pilihan', (
    tester,
  ) async {
    await pump(tester);

    expect(
      find.text('Pilih sektor yang akan kamu pelajari'),
      findsOneWidget,
    );
    expect(find.text('Jasa Transportasi'), findsOneWidget);
    expect(find.text('Listrik, BBM & Gas Rumah Tangga'), findsOneWidget);

    // Sektor pertama terpilih otomatis -> muncul di kartu DAN panel bawah.
    expect(find.text('Kamu memilih'), findsOneWidget);
    expect(find.text('E-Commerce'), findsNWidgets(2));
    expect(find.text('Mulai Belajar'), findsOneWidget);
  });

  testWidgets('tap kartu lain memindah pilihan di panel, belum menyetel', (
    tester,
  ) async {
    final container = await pump(tester);

    await tester.tap(find.text('Layanan Kesehatan'));
    await tester.pumpAndSettle();

    expect(find.text('Layanan Kesehatan'), findsNWidgets(2));
    expect(find.text('E-Commerce'), findsOneWidget);
    // Belum ada sektor aktif sampai "Mulai Belajar" ditekan.
    expect(container.read(activeSectorSlugProvider), isNull);
  });

  testWidgets('"Mulai Belajar" menyetel sektor aktif sesi', (tester) async {
    final container = await pump(tester);

    await tester.tap(find.text('Jasa Transportasi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mulai Belajar'));
    // Bukan pumpAndSettle: setelah menyetel, tombol tetap loading (di app
    // sungguhan AppRoot langsung pindah layar & widget ini dibuang).
    await tester.pump();

    expect(container.read(activeSectorSlugProvider), 'transportasi');
  });

  testWidgets('tanpa warna dari server, kartu tetap render (fallback)', (
    tester,
  ) async {
    await pump(tester);

    // Sektor "elektronik" sengaja tanpa `color` -- tidak boleh bikin error.
    expect(find.text('Elektronik & Kendaraan Bermotor'), findsOneWidget);
  });

  testWidgets('tidak overflow di layar HP kecil', (tester) async {
    await pump(tester, size: const Size(1080, 1920)); // ~360x640 dp

    expect(tester.takeException(), isNull);
    expect(find.text('Mulai Belajar'), findsOneWidget);
  });
}
