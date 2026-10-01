import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:colosynth/game_data/tier_enemy_stats.dart';
import 'package:colosynth/game/widgets/hp_bar_widget.dart';
import 'package:colosynth/services/sprite_repository.dart';
import 'package:colosynth/game/components/player_component.dart';
import 'package:flame/game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tutorial Enemy Stats Tests', () {
    test('TierEnemyStats.tutorial has reduced HP and ATK for beginner onboarding', () {
      expect(TierEnemyStats.tutorial.hp, 200);
      expect(TierEnemyStats.tutorial.atk, 15);
      expect(TierEnemyStats.tutorial.def, 0);
      expect(TierEnemyStats.tutorial.shield, 0);
      expect(TierEnemyStats.tutorial.stamina, 30);
    });

    test('TierEnemyStats.forTier(0) maps to tutorial stats', () {
      final stats = TierEnemyStats.forTier(0);
      expect(stats.hp, 200);
      expect(stats.atk, 15);
    });
  });

  group('Health Bar Colors Tests', () {
    testWidgets('HpBar defaults to enemy red baseColor', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HpBar(
              current: 100,
              max: 100,
              label: 'ENEMY',
            ),
          ),
        ),
      );

      final hpBarFinder = find.byType(HpBar);
      expect(hpBarFinder, findsOneWidget);

      final hpBar = tester.widget<HpBar>(hpBarFinder);
      expect(hpBar.baseColor, isNull); // Default internal base is Color(0xFFFF3333)
    });
  });

  group('Sprite Repository & Shield Barrier Tests', () {
    test('SpriteRepository.blockEffect references vfx/vfx_shield_barrier.png', () {
      expect(SpriteRepository.blockEffect, 'vfx/vfx_shield_barrier.png');
    });

    test('PlayerShieldBarrierComponent instantiates with correct geometry', () {
      final barrier = PlayerShieldBarrierComponent(parentSize: Vector2(100, 150));
      expect(barrier.size.x, closeTo(150.0, 0.01));
      expect(barrier.size.y, closeTo(142.5, 0.01));
      expect(barrier.priority, 25);
    });
  });
}
