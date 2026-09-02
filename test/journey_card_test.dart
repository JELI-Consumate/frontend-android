// JourneyCard: foto depan journey dari `imageUrl` (fallback ke ilustrasi
// dummy kalau kosong / gagal / masih dimuat / journey terkunci).

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perlindungan_konsumen/features/learning/data/models/journey.dart';
import 'package:perlindungan_konsumen/features/learning/data/models/learning_status.dart';
import 'package:perlindungan_konsumen/features/main/presentation/widgets/journey_card.dart';

Journey _journey({String? imageUrl, bool unlocked = true}) => Journey(
  id: '1',
  slug: 'kenali-hakmu',
  title: 'Kenali Hakmu sebagai Konsumen',
  description: 'Pengantar hak konsumen.',
  order: 1,
  estimatedMinutes: 30,
  isUnlocked: unlocked,
  modulesCount: 5,
  progress: const LearningProgress(
    status: LearningStatus.notStarted,
    percent: 0,
  ),
  imageUrl: imageUrl,
);

Future<void> _pump(WidgetTester tester, Journey journey) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: JourneyCard(
          journey: journey,
          label: 'Journey 1',
          onTap: () {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('pakai Image.network kalau imageUrl ada', (tester) async {
    await _pump(tester, _journey(imageUrl: 'https://cdn.example/j1.jpg'));

    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('fallback ke ilustrasi dummy kalau imageUrl kosong', (
    tester,
  ) async {
    await _pump(tester, _journey());

    expect(find.byType(Image), findsNothing);
    expect(find.byType(SvgPicture), findsOneWidget);
  });

  testWidgets('journey terkunci: gembok, bukan foto', (tester) async {
    await _pump(
      tester,
      _journey(imageUrl: 'https://cdn.example/j1.jpg', unlocked: false),
    );

    // Gembok muncul di thumbnail (dan juga di baris alasan terkunci).
    expect(find.byIcon(Icons.lock_outline), findsWidgets);
    expect(find.byType(Image), findsNothing);
    expect(find.byType(SvgPicture), findsNothing);
  });
}
