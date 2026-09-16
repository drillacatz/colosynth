import 'package:flutter_riverpod/flutter_riverpod.dart';

class NavigationNotifier extends Notifier<int> {
  static const arenaIndex = 2;

  @override
  int build() => arenaIndex;

  void selectTab(int index) => state = index;
}

final navigationProvider = NotifierProvider<NavigationNotifier, int>(
  NavigationNotifier.new,
);
