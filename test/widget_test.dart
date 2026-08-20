// Basic smoke test to make sure the app boots and shows the home screen.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:perlindungan_konsumen/main.dart';

void main() {
  testWidgets('App boots and shows home screen title', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    expect(find.text('Perlindungan Konsumen'), findsWidgets);
  });
}
