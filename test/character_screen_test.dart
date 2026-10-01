import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colosynth/screens/character/character_screen.dart';
import 'package:colosynth/screens/character/character_misc.dart';
import 'package:colosynth/game_data/character_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestHost({required Widget child}) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: child,
        ),
      ),
    );
  }

  group('CharacterScreen Layout & ParentDataWidget Tests', () {
    testWidgets('CharacterArtBackdrop returns art directly and can be wrapped by RepaintBoundary in a Stack without ParentDataWidget error', (tester) async {
      await tester.pumpWidget(
        buildTestHost(
          child: Stack(
            children: [
              RepaintBoundary(
                child: CharacterArtBackdrop(
                  character: CharacterDatabase.all.first,
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(CharacterArtBackdrop), findsOneWidget);
    });

    testWidgets('CharacterScreen builds and renders without ParentDataWidget exception', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestHost(
          child: const CharacterScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
      expect(find.byType(CharacterScreen), findsOneWidget);
      expect(find.byType(CharacterArtBackdrop), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
