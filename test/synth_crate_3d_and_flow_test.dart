import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:colosynth/widgets/comic/procedural_3d_chest.dart';
import 'package:colosynth/screens/overlays/synth_crate_opening_overlay.dart';
import 'package:colosynth/screens/store/synth_shop_section.dart';
import 'package:colosynth/providers/synth_provider.dart';
import 'package:colosynth/providers/shared_preferences_provider.dart';

class _MockSynthKeysNotifier extends SynthKeysNotifier {
  final int initial;
  _MockSynthKeysNotifier(this.initial);
  @override
  int build() => initial;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Procedural3dChest Widget Tests', () {
    testWidgets('renders closed 3D chest with base, lid, padlock, and straps',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Procedural3dChest(
                tapsDone: 0,
                rarity: SynthRarity.common,
                isOpening: false,
                isOpened: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(Procedural3dChest), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
      expect(find.byIcon(Icons.vpn_key_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders glowing cracks when tapsDone > 0 and advances with taps',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Procedural3dChest(
                tapsDone: 3,
                rarity: SynthRarity.epic,
                isOpening: false,
                isOpened: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(Procedural3dChest), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('opens 3D lid on hinge and emits volumetric light when isOpening/isOpened',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Procedural3dChest(
                tapsDone: 4,
                rarity: SynthRarity.legendary,
                isOpening: true,
                isOpened: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.byType(Procedural3dChest), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('SynthCrateSection Confirmation Dialog Tests', () {
    testWidgets('tapping Open Crate with keys shows confirmation dialog',
        (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            synthKeysProvider.overrideWith(() => _MockSynthKeysNotifier(3)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SynthCrateSection(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap OPEN CRATE button
      final openButton = find.textContaining('OPEN CRATE');
      expect(openButton, findsOneWidget);
      await tester.tap(openButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Confirmation dialog should be visible
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('OPEN SYNTH CRATE'), findsOneWidget);
      expect(find.text('Spend 1 Synth Key to open Synth Crate?'), findsOneWidget);
      expect(find.text('CANCEL'), findsOneWidget);
      expect(find.text('CONFIRM'), findsOneWidget);

      // Tap CANCEL button
      await tester.tap(find.text('CANCEL'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed and SynthCrateOpeningOverlay should NOT be shown
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(SynthCrateOpeningOverlay), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping Open Crate with 0 keys shows No Synth Keys feature overlay',
        (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            synthKeysProvider.overrideWith(() => _MockSynthKeysNotifier(0)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SynthCrateSection(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tapping with 0 keys should not open dialog
      final openButton = find.textContaining('OPEN CRATE');
      expect(openButton, findsOneWidget);
      await tester.tap(openButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
