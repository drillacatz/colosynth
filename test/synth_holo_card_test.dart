import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colosynth/database/synth/synth_definition.dart';
import 'package:colosynth/database/synth/synth_instance.dart';
import 'package:colosynth/providers/inventory_provider.dart';
import 'package:colosynth/screens/overlays/synth_crate_opening_overlay.dart'
    show SynthRarity;
import 'package:colosynth/screens/synth/synth_card_showcase_overlay.dart';
import 'package:colosynth/screens/synth/synth_holo_card.dart';
import 'package:colosynth/screens/upgrade/upgrade_inventory_view.dart';
import 'package:colosynth/screens/upgrade/upgrade_notifier.dart';
import 'package:colosynth/services/sensor_tilt_service.dart';
import 'package:colosynth/widgets/comic/procedural_3d_chest.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/sensors/method'),
      (MethodCall methodCall) async => null,
    );
  });

  group('SensorTiltService Tests', () {
    test('starts and stops gracefully without throwing exceptions', () {
      final service = SensorTiltService.instance;
      expect(service.tiltNotifier.value, equals(SensorTiltData.zero));

      service.start();
      service.stop();
      expect(service.tiltNotifier.value, equals(SensorTiltData.zero));
    });

    test('SensorTiltData equality and hashcode', () {
      const data1 = SensorTiltData(pitch: 0.12, roll: -0.15);
      const data2 = SensorTiltData(pitch: 0.12, roll: -0.15);
      const data3 = SensorTiltData(pitch: 0.30, roll: 0.10);

      expect(data1, equals(data2));
      expect(data1.hashCode, equals(data2.hashCode));
      expect(data1 == data3, isFalse);
    });
  });

  group('SynthHoloCard Widget Tests', () {
    testWidgets('renders SynthHoloCard with correct title and stats', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const def = SynthDefinition(
        id: 'synth_01',
        name: 'Standard Strike',
        comboSequence: [],
        counterStaminaDamage: 10,
        bonusDamageMult: 1.2,
        activeSkillChargeBonus: 5,
        unlockCostPaint: 10,
        unlockCostInk: 50,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SynthHoloCard(
                definition: def,
                level: 3,
                isInteractive: false,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(SynthHoloCard), findsOneWidget);
      expect(find.text('STANDARD STRIKE'), findsOneWidget);
      expect(find.text('+3'), findsOneWidget);
      expect(find.text('STAMINA DMG'), findsOneWidget);
      expect(find.text('+10'), findsOneWidget);
      expect(find.text('DAMAGE MULT'), findsOneWidget);
      expect(find.text('×1.2'), findsOneWidget);
    });

    testWidgets('handles pan drag gestures to tilt card', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final def = globalSynthDefinitions.first;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SynthHoloCard(
                definition: def,
                level: 1,
                isInteractive: true,
              ),
            ),
          ),
        ),
      );

      final cardFinder = find.byType(SynthHoloCard);
      expect(cardFinder, findsOneWidget);

      // Perform a drag across the card
      await tester.drag(cardFinder, const Offset(60, -40));
      await tester.pump();

      // Pan end spring-back
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders SynthCardShowcaseOverlay cleanly', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final def = globalSynthDefinitions.first;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    SynthCardShowcaseOverlay.show(
                      context,
                      definition: def,
                      level: 2,
                    );
                  },
                  child: const Text('OPEN'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      expect(find.byType(SynthCardShowcaseOverlay), findsOneWidget);
      expect(find.text('SYNTH ARCHIVE // POKEBOX 3D'), findsNothing);
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.text(def.name.toUpperCase()), findsOneWidget);

      // Tap close button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byType(SynthCardShowcaseOverlay), findsNothing);
    });
  });

  group('Inventory Screen VIEW Button Tests', () {
    testWidgets('renders VIEW button only when a synth item is selected', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final synthItem = InventoryItem(
        id: 'inst_1',
        type: InventoryItemType.synth,
        stackCount: 1,
        synthInstance: SynthInstance(
          instanceId: 'inst_1',
          definitionId: 'synth_01',
          unlockedAtMs: 1000,
          level: 2,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inventoryProvider.overrideWith((ref) => Inventory(
                  characters: [],
                  upgradeItems: [synthItem],
                )),
            upgradeNotifierProvider.overrideWith(UpgradeNotifier.new),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: InventoryView(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // VIEW button should be present for synth
      expect(find.text('VIEW'), findsOneWidget);
      expect(find.byIcon(Icons.style), findsOneWidget);
    });

    testWidgets('does not render VIEW button for exp note or key items', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final keyItem = InventoryItem(
        id: 'synth_key',
        type: InventoryItemType.key,
        stackCount: 5,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inventoryProvider.overrideWith((ref) => Inventory(
                  characters: [],
                  upgradeItems: [keyItem],
                )),
            upgradeNotifierProvider.overrideWith(UpgradeNotifier.new),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: InventoryView(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // VIEW button should NOT be present for keys or exp items
      expect(find.text('VIEW'), findsNothing);
    });

    testWidgets('renders rarity outline on synth inventory slots', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final commonSynth = InventoryItem(
        id: 'synth_inst_common',
        type: InventoryItemType.synth,
        synthInstance: SynthInstance(
          instanceId: 'synth_inst_common',
          definitionId: 'synth_01', // Common (< 13)
          level: 1,
          unlockedAtMs: 0,
        ),
      );

      final legendarySynth = InventoryItem(
        id: 'synth_inst_legendary',
        type: InventoryItemType.synth,
        synthInstance: SynthInstance(
          instanceId: 'synth_inst_legendary',
          definitionId: 'synth_40', // Legendary (>= 39)
          level: 5,
          unlockedAtMs: 0,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inventoryProvider.overrideWith((ref) => Inventory(
                  characters: [],
                  upgradeItems: [commonSynth, legendarySynth],
                )),
            upgradeNotifierProvider.overrideWith(UpgradeNotifier.new),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: InventoryView(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find AnimatedContainers for the inventory slots
      final containers = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .where((c) => c.decoration is BoxDecoration)
          .toList();

      expect(containers.length, greaterThanOrEqualTo(2));

      // First slot is selected common synth -> Slate grey with selection width
      final firstDec = containers[0].decoration as BoxDecoration;
      final firstBorder = firstDec.border as Border;
      expect(firstBorder.top.color, const Color(0xFF78909C));

      // Second slot is unselected legendary synth -> Radiant gold outline
      final secondDec = containers[1].decoration as BoxDecoration;
      final secondBorder = secondDec.border as Border;
      expect(secondBorder.top.color, const Color(0xFFFFB300));
      expect(secondBorder.top.width, 1.8);
    });
  });

  group('Legendary Rainbow Holographic Crate & Chest Tests', () {
    test('SynthRarity.rainbowColors contains expected spectrum', () {
      expect(SynthRarity.rainbowColors.length, equals(6));
      expect(SynthRarity.rainbowColors.first, equals(const Color(0xFFFF0055)));
      expect(SynthRarity.rainbowColors.last, equals(const Color(0xFFFF0055)));
    });

    testWidgets('Procedural3dChest renders with isLegendary without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Procedural3dChest(
                tapsDone: 3,
                rarity: SynthRarity.legendary,
                isOpening: false,
                isOpened: true,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(Procedural3dChest), findsOneWidget);
    });
  });
}
