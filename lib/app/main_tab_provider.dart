import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainTabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final mainTabIndexProvider = NotifierProvider<MainTabIndexNotifier, int>(
  MainTabIndexNotifier.new,
);
