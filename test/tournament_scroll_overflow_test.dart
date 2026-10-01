import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:colosynth/providers/shared_preferences_provider.dart';
import 'package:colosynth/providers/tournament_provider.dart';
import 'package:colosynth/providers/tutorial_provider.dart';
import 'package:colosynth/screens/tournament/tournament_screen.dart';

class _FakeTournamentProgressNotifier extends TournamentProgressNotifier {
  @override
  Map<String, String> build() => {
    't1_1': 'arthur',
    't1_2': 'arthur',
    't1_3': 'arthur',
    't1_4': 'arthur',
    't1_5': 'arthur',
    't1_6': 'arthur',
  };

  @override
  Future<void> markCompleted(String slotId) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildHost(SharedPreferences prefs, {Size size = const Size(360, 640)}) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        tournamentProgressProvider.overrideWith(() => _FakeTournamentProgressNotifier()),
        tutorialCompletedProvider.overrideWith((ref) => true),
      ],
      child: MediaQuery(
        data: MediaQueryData(size: size),
        child: const MaterialApp(
          home: Scaffold(
            body: TournamentScreen(),
          ),
        ),
      ),
    );
  }

  testWidgets('Scrolling TournamentScreen does not cause RenderFlex overflow', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final oldHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      FlutterError.dumpErrorToConsole(details);
      oldHandler?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldHandler);

    await tester.pumpWidget(buildHost(prefs));
    await tester.pump(const Duration(milliseconds: 500));

    // Scroll forward through multiple cards
    for (int i = 0; i < 15; i++) {
      await tester.drag(find.byType(TournamentScreen), const Offset(-80, 80));
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Scroll backward through cards
    for (int i = 0; i < 15; i++) {
      await tester.drag(find.byType(TournamentScreen), const Offset(80, -80));
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('Scrolling TournamentScreen on 320x568 with 1.3x text scale does not cause RenderFlex overflow', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final oldHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      FlutterError.dumpErrorToConsole(details);
      oldHandler?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldHandler);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          tournamentProgressProvider.overrideWith(() => _FakeTournamentProgressNotifier()),
          tutorialCompletedProvider.overrideWith((ref) => true),
        ],
        child: const MediaQuery(
          data: MediaQueryData(
            size: Size(320, 568),
            textScaler: TextScaler.linear(1.3),
          ),
          child: MaterialApp(
            home: Scaffold(
              body: TournamentScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    // Scroll forward through multiple cards
    for (int i = 0; i < 15; i++) {
      await tester.drag(find.byType(TournamentScreen), const Offset(-80, 80));
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Scroll backward through cards
    for (int i = 0; i < 15; i++) {
      await tester.drag(find.byType(TournamentScreen), const Offset(80, -80));
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
