import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:colosynth/game/logic/damage_calculator.dart';
import 'package:colosynth/game/logic/damage_law.dart';
import 'package:colosynth/services/battle_stats_resolver.dart';
import 'package:colosynth/growth/character/character_module.dart';
import 'package:colosynth/database/equipment/equipment_stat_block.dart';
import 'package:colosynth/growth/character/skills/skill_tree_module.dart';

void main() {
  group('DamageCalculator Unit Tests (§8.1 Combat Law)', () {
    test('enemyAttack does not reduce damage when player is not guarding', () {
      final dmg = DamageCalculator.enemyAttack(
        enemyAtk: 100,
        playerDef: 30,
        isPlayerGuarding: false,
      );
      expect(dmg, equals(100));
    });

    test('enemyAttack subtracts DEF when player is actively guarding', () {
      final dmg = DamageCalculator.enemyAttack(
        enemyAtk: 100,
        playerDef: 30,
        isPlayerGuarding: true,
      );
      expect(dmg, equals(70));
    });

    test('DEF exceeding attack clamps damage to minDamage (0) when guarding', () {
      final dmg = DamageCalculator.enemyAttack(
        enemyAtk: 50,
        playerDef: 100,
        isPlayerGuarding: true,
      );
      expect(dmg, equals(0));
    });

    test('slash damage produces 0.25x baseAtk normal damage', () {
      final dmg = DamageCalculator.slash(
        baseAtk: 400,
      );
      expect(dmg, equals(100));
    });

    test('slash damage subtracts enemy DEF when enemy is guarding', () {
      final dmg = DamageCalculator.slash(
        baseAtk: 400,
        enemyDef: 30,
        isEnemyGuarding: true,
      );
      expect(dmg, equals(70));
    });

    test('activeSkill produces 1.0x baseAtk, higher than standard slash', () {
      final slashDmg = DamageCalculator.slash(baseAtk: 400);
      final skillDmg = DamageCalculator.activeSkill(baseAtk: 400);
      expect(slashDmg, equals(100));
      expect(skillDmg, equals(400));
      expect(skillDmg, greaterThan(slashDmg));
    });

    test('DamageLaw produces 100% deterministic output when seeded', () {
      final rng1 = math.Random(12345);
      final rng2 = math.Random(12345);

      final mult1 = DamageLaw.resolveMult(HitType.normal, rng: rng1);
      final mult2 = DamageLaw.resolveMult(HitType.normal, rng: rng2);

      expect(mult1, equals(mult2));
    });

    test('BattleStatsResolver aggregates 0 def and 0 shield when empty', () {
      final stats = BattleStatsResolver.aggregate(
        char: const CharStatBlock(atk: 100, hp: 1000),
        equip: EquipmentStatBlock.zero,
        skillTree: const SkillTreeStats(),
      );
      expect(stats.def, equals(0));
      expect(stats.shield, equals(0));
    });

    test('BattleStatsResolver aggregates equipment def correctly', () {
      final stats = BattleStatsResolver.aggregate(
        char: const CharStatBlock(atk: 100, hp: 1000),
        equip: const EquipmentStatBlock(atk: 10, hp: 50, def: 45, shield: 0),
        skillTree: const SkillTreeStats(),
      );
      expect(stats.def, equals(45));
    });
  });
}
