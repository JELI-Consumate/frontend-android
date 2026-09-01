// Perilaku tab "Pencapaian" (BadgesScreen).

import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:perlindungan_konsumen/core/network/api_exception.dart';
import 'package:perlindungan_konsumen/core/storage/sector_storage.dart';
import 'package:perlindungan_konsumen/core/theme/app_theme.dart';
import 'package:perlindungan_konsumen/features/badges/data/badge_repository.dart';
import 'package:perlindungan_konsumen/features/badges/data/models/badge.dart';
import 'package:perlindungan_konsumen/features/badges/presentation/badges_screen.dart';
import 'package:perlindungan_konsumen/features/learning/data/learning_repository.dart';

import 'support/fake_badge_repository.dart';
import 'support/fake_learning_repository.dart';
import 'support/fake_sector_storage.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  Future<void> pump(
    WidgetTester tester, {
    FakeLearningRepository? learningRepository,
    FakeBadgeRepository? badgeRepository,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          learningRepositoryProvider.overrideWithValue(
            learningRepository ?? FakeLearningRepository(),
          ),
          badgeRepositoryProvider.overrideWithValue(
            badgeRepository ?? FakeBadgeRepository(),
          ),
          sectorStorageProvider.overrideWithValue(
            FakeSectorStorage(initialSlug: 'e-commerce'),
          ),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const BadgesScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('badge journey di luar sektor aktif tidak ikut tampil', (
    tester,
  ) async {
    // FakeLearningRepository.defaultJourneys cuma sampai id 4, jadi badge
    // id 5 (journey 99, di luar sektor) semestinya tersaring keluar oleh
    // sectorBadgesProvider.
    final badgeRepository = FakeBadgeRepository(
      items: [
        ...FakeBadgeRepository.defaultBadges,
        const Badge(
          id: '5',
          journeyId: '99',
          name: 'Badge Sektor Lain',
          description: 'Tidak boleh muncul.',
          congratulationMessage: null,
          motivationalMessage: null,
          iconUrl: null,
          earned: false,
          earnedAt: null,
        ),
      ],
    );
    await pump(tester, badgeRepository: badgeRepository);

    expect(find.text('Consumer Rights Explorer'), findsOneWidget);
    expect(find.text('Badge Sektor Lain'), findsNothing);
  });

  testWidgets('ringkasan menghitung jumlah badge yang sudah diraih', (
    tester,
  ) async {
    await pump(tester);

    // 1 dari 4 badge fixture (journey 1) yang earned: true.
    expect(find.text('1/4 Lencana diraih'), findsOneWidget);
    expect(find.textContaining('Diraih 10 Januari 2026'), findsOneWidget);
  });

  testWidgets('badge yang belum diraih menampilkan petunjuk, bukan tanggal', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Smart Shopper'), findsOneWidget);
    expect(
      find.text('Selesaikan journey terkait untuk meraih ini'),
      findsNWidgets(3),
    );
  });

  testWidgets('gagal memuat menampilkan pesan error', (tester) async {
    final badgeRepository = FakeBadgeRepository()
      ..failWith = const ApiException(message: 'Server bermasalah.');
    await pump(tester, badgeRepository: badgeRepository);

    expect(find.textContaining('Gagal memuat lencana'), findsOneWidget);
  });

  testWidgets(
    'tap badge yang sudah diraih membuka detail berisi pesan ucapan selamat & motivasi',
    (tester) async {
      await pump(tester);

      await tester.tap(find.text('Consumer Rights Explorer'));
      await tester.pumpAndSettle();

      expect(find.text('DESKRIPSI BADGE'), findsOneWidget);
      expect(find.text('PESAN SAAT DIRAIH'), findsOneWidget);
      expect(
        find.textContaining('Kenali Hakmu sebagai Konsumen'),
        findsOneWidget,
      );
      expect(find.text('PESAN MOTIVASI'), findsOneWidget);
      expect(find.textContaining('Journey 2'), findsOneWidget);
    },
  );

  testWidgets(
    'tap badge yang belum diraih membuka detail tanpa pesan ucapan selamat',
    (tester) async {
      await pump(tester);

      await tester.tap(find.text('Smart Shopper'));
      await tester.pumpAndSettle();

      expect(find.text('DESKRIPSI BADGE'), findsOneWidget);
      expect(find.text('PESAN SAAT DIRAIH'), findsNothing);
      expect(find.text('PESAN MOTIVASI'), findsNothing);
      // Baris status di dalam sheet menambah 1 lagi dari yang di list.
      expect(
        find.text('Selesaikan journey terkait untuk meraih ini'),
        findsNWidgets(4),
      );
    },
  );

  testWidgets('tombol Tutup menutup detail sheet', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Consumer Rights Explorer'));
    await tester.pumpAndSettle();
    expect(find.text('DESKRIPSI BADGE'), findsOneWidget);

    // Sheet-nya scrollable sekarang (lihat badge_detail_sheet.dart) -- badge
    // yang sudah diraih plus pesan ucapan selamat & motivasi bikin "Tutup"
    // ada di bawah lipatan, perlu discroll ke pandangan dulu sebelum tap.
    await tester.ensureVisible(find.text('Tutup'));
    await tester.tap(find.text('Tutup'));
    await tester.pumpAndSettle();

    expect(find.text('DESKRIPSI BADGE'), findsNothing);
  });
}
