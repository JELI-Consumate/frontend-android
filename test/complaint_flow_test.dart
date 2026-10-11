import 'package:consumate/core/network/api_exception.dart';
import 'package:consumate/core/theme/app_theme.dart';
import 'package:consumate/features/complaint/application/complaint_providers.dart';
import 'package:consumate/features/complaint/data/complaint_repository.dart';
import 'package:consumate/features/complaint/data/models/complaint_agency.dart';
import 'package:consumate/features/complaint/presentation/complaint_agencies_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_complaint_repository.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    FakeComplaintRepository repository, {
    List<Uri>? launched,
    bool launchResult = true,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          complaintRepositoryProvider.overrideWithValue(repository),
          externalUrlLauncherProvider.overrideWithValue((uri) async {
            launched?.add(uri);
            return launchResult;
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ComplaintAgenciesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('model', () {
    test('tipe kanal tidak dikenal jatuh ke website', () {
      expect(
        ComplaintChannelType.parse('telegram'),
        ComplaintChannelType.website,
      );
      expect(ComplaintChannelType.parse('phone'), ComplaintChannelType.phone);
    });

    test('label tombol memakai button_label, fallback ke label bawaan', () {
      final withLabel = ComplaintChannel.fromJson({
        'type': 'email',
        'label': 'Email',
        'value': 'a@b.id',
        'url': 'mailto:a@b.id',
        'button_label': 'Kirim ke BPKN',
      });
      final withoutLabel = ComplaintChannel.fromJson({
        'type': 'email',
        'label': 'Email',
        'value': 'a@b.id',
        'url': 'mailto:a@b.id',
        'button_label': null,
      });

      expect(withLabel.actionLabel, 'Kirim ke BPKN');
      expect(withoutLabel.actionLabel, 'Kirim Email');
    });
  });

  testWidgets('menampilkan daftar lembaga dari API', (tester) async {
    await pump(tester, FakeComplaintRepository());

    expect(find.text('Badan Pengawas Obat dan Makanan'), findsOneWidget);
    expect(find.text('Yayasan Lembaga Konsumen Indonesia'), findsOneWidget);
  });

  testWidgets('gagal memuat menampilkan pesan error dan tombol coba lagi', (
    tester,
  ) async {
    final repository = FakeComplaintRepository()
      ..failAgenciesWith = const ApiException(message: 'Server bermasalah.');
    await pump(tester, repository);

    expect(find.text('Gagal memuat daftar lembaga.'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });

  testWidgets('tab panduan membuka lembaga relevan lalu ke detail', (
    tester,
  ) async {
    final repository = FakeComplaintRepository();
    await pump(tester, repository);

    await tester.tap(find.text('Pilih Sesuai Masalah'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dugaan produk obat atau makanan ilegal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('BPOM'));
    await tester.pumpAndSettle();

    expect(repository.calls, contains('agencyDetail(bpom)'));
    expect(find.text('Kapan Perlu Menghubungi?'), findsOneWidget);
    expect(find.text('Menemukan produk ilegal.'), findsOneWidget);
  });

  testWidgets('tombol kanal membuka URL dari backend, alamat tanpa tombol', (
    tester,
  ) async {
    final launched = <Uri>[];
    await pump(tester, FakeComplaintRepository(), launched: launched);

    await tester.tap(find.text('Badan Pengawas Obat dan Makanan'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Jl. Percetakan Negara'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Jl. Percetakan Negara'), findsOneWidget);
    expect(find.text('Hubungi Halo BPOM'), findsOneWidget);

    await tester.ensureVisible(find.text('Hubungi Halo BPOM'));
    await tester.tap(find.text('Hubungi Halo BPOM'));
    await tester.pumpAndSettle();

    expect(launched, [Uri.parse('https://wa.me/6281191811533')]);
  });

  testWidgets('gagal membuka tautan menampilkan alert error', (tester) async {
    await pump(tester, FakeComplaintRepository(), launchResult: false);

    await tester.tap(find.text('Badan Pengawas Obat dan Makanan'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Hubungi Halo BPOM'));
    await tester.tap(find.text('Hubungi Halo BPOM'));
    await tester.pumpAndSettle();

    expect(find.text('Gagal Membuka Tautan'), findsOneWidget);
  });

  testWidgets('lembaga tanpa kanal menampilkan info kontak belum tersedia', (
    tester,
  ) async {
    await pump(tester, FakeComplaintRepository(channels: const []));

    await tester.tap(find.text('Badan Pengawas Obat dan Makanan'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Kontak resmi lembaga ini belum tersedia'),
      findsOneWidget,
    );
  });
}
