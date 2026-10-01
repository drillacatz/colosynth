import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:colosynth/screens/battle/p5_cut_in_overlay.dart';
import 'package:colosynth/services/sprite_repository.dart';
import 'package:colosynth/game/app_shell/battle_models.dart';

void main() {
  group('VFX & Sprite Repository Tests', () {
    test('SpriteRepository.skillVfx resolves valid sprite sheet paths', () {
      expect(SpriteRepository.skillVfx('slash'), equals('vfx/vfx_slash.png'));
      expect(SpriteRepository.skillVfx('lightning'), equals('vfx/vfx_lightning.png'));
      expect(SpriteRepository.skillVfx('arcane_nuke'), equals('vfx/vfx_arcane_nuke.png'));
      expect(SpriteRepository.skillVfx('fire_blast'), equals('vfx/vfx_fire_blast.png'));
      expect(SpriteRepository.skillVfx('shield_barrier'), equals('vfx/vfx_shield_barrier.png'));
      expect(SpriteRepository.skillVfx('holy_light'), equals('vfx/vfx_holy_light.png'));
      // Fallback
      expect(SpriteRepository.skillVfx('unknown_vfx'), equals('vfx/vfx_slash.png'));
    });

    test('vfxInfoForCharacter resolves archetype and color for all 12 heroes', () {
      final characters = [
        'centrium',
        'lilith',
        'ignis',
        'valeria',
        'centurio',
        'freya',
        'kaelen',
        'orion',
        'vargas',
        'nyx',
        'sariel',
        'centrium_clean',
      ];

      for (final id in characters) {
        final info = SpriteRepository.vfxInfoForCharacter(id);
        expect(info.$1, isNotEmpty);
        expect(info.$2, isA<bool>());
        final archetype = info.$1;
        expect(SpriteRepository.skillVfx(archetype), isNotEmpty);
      }
    });

    test('SkillCutInData initializes correctly', () {
      const data = SkillCutInData(
        characterId: 'ignis',
        characterName: 'Ignis',
        skillName: 'Solar Flare',
        accentColor: Color(0xFFFF5722),
      );

      expect(data.characterId, equals('ignis'));
      expect(data.characterName, equals('Ignis'));
      expect(data.skillName, equals('Solar Flare'));
      expect(data.accentColor, equals(const Color(0xFFFF5722)));
    });
  });

  group('P5CutInOverlay Widget Tests', () {
    testWidgets('renders P5CutInOverlay and displays hero & skill name', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: P5CutInOverlay(
              characterId: 'ignis',
              characterName: 'IGNIS',
              skillName: 'CRIMSON NOVA',
              accentColor: const Color(0xFFFF5722),
              onComplete: () {
                completed = true;
              },
            ),
          ),
        ),
      );

      // Verify widget elements rendered
      expect(find.byType(P5CutInOverlay), findsOneWidget);

      // Advance into expansion & focus phase (after laser stroke slide-in at 350ms)
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('IGNIS'), findsOneWidget);
      expect(find.text('CRIMSON NOVA'), findsOneWidget);
      expect(completed, isFalse);

      // Advance animation to completion (total duration is 1400ms)
      await tester.pump(const Duration(milliseconds: 950));
      expect(completed, isTrue);
    });

    testWidgets('renders P5CutInOverlay on compact screen without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 568); // iPhone SE 1st gen compact size
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: P5CutInOverlay(
              characterId: 'lilith',
              characterName: 'LILITH',
              skillName: 'ABYSSAL SURGE',
              accentColor: const Color(0xFF9C27B0),
              onComplete: () {},
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
