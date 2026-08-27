// Perilaku tab "Profil", khususnya bottom sheet ubah nama.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perlindungan_konsumen/core/storage/sector_storage.dart';
import 'package:perlindungan_konsumen/features/auth/data/auth_repository.dart';
import 'package:perlindungan_konsumen/features/badges/data/badge_repository.dart';
import 'package:perlindungan_konsumen/features/learning/data/learning_repository.dart';
import 'package:perlindungan_konsumen/main.dart';

import 'support/fake_auth_repository.dart';
import 'support/fake_badge_repository.dart';
import 'support/fake_learning_repository.dart';
import 'support/fake_sector_storage.dart';

void main() {
  Future<FakeAuthRepository> pumpProfileTab(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final repository = FakeAuthRepository(storedToken: 'token-123');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          // MainShell me-render semua tab lewat IndexedStack sekaligus.
          learningRepositoryProvider.overrideWithValue(
            FakeLearningRepository(),
          ),
          badgeRepositoryProvider.overrideWithValue(FakeBadgeRepository()),
          sectorStorageProvider.overrideWithValue(
            FakeSectorStorage(initialSlug: 'e-commerce'),
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    return repository;
  }

  Future<void> openEditNameSheet(WidgetTester tester) async {
    await tester.tap(find.text('Ubah Nama'));
    await tester.pumpAndSettle();
  }

  testWidgets('tap Ubah Nama membuka bottom sheet berisi nama saat ini', (
    tester,
  ) async {
    await pumpProfileTab(tester);
    await openEditNameSheet(tester);

    expect(
      find.text('Nama ini akan tampil di profil dan sertifikatmu.'),
      findsOneWidget,
    );
    // Header profil + field yang sudah terisi nama sekarang -- `find.text`
    // ikut mencocokkan isi `EditableText`, jadi field terprefill juga
    // kehitung di sini.
    expect(find.text('Budi Santoso'), findsNWidgets(2));
  });

  testWidgets('tombol Simpan nonaktif selama nama belum diubah', (
    tester,
  ) async {
    await pumpProfileTab(tester);
    await openEditNameSheet(tester);

    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Simpan'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('ubah nama lalu Simpan memperbarui profil dan menutup sheet', (
    tester,
  ) async {
    final repository = await pumpProfileTab(tester);
    await openEditNameSheet(tester);

    await tester.enterText(find.byType(TextField), 'Nama Baru');
    await tester.pump();

    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(repository.calls, contains('updateProfile(Nama Baru)'));
    expect(find.text('Nama Baru'), findsOneWidget); // header ter-update
    expect(
      find.text('Nama ini akan tampil di profil dan sertifikatmu.'),
      findsNothing, // sheet sudah tertutup
    );
    expect(find.text('Nama berhasil diperbarui.'), findsOneWidget);
  });

  testWidgets('tombol Batal menutup sheet tanpa menyimpan', (tester) async {
    final repository = await pumpProfileTab(tester);
    await openEditNameSheet(tester);

    await tester.enterText(find.byType(TextField), 'Nama Yang Dibatalkan');
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(
      repository.calls,
      isNot(contains('updateProfile(Nama Yang Dibatalkan)')),
    );
    expect(find.text('Budi Santoso'), findsOneWidget); // nama tidak berubah
    expect(
      find.text('Nama ini akan tampil di profil dan sertifikatmu.'),
      findsNothing,
    );
  });
}
