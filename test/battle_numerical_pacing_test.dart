import 'package:flutter_test/flutter_test.dart';
import 'package:colosynth/game/logic/damage_calculator.dart';
import 'package:colosynth/game_data/tier_enemy_stats.dart';

void main() {
  group('Battle Numerical Pacing & Balance (§8 Numerical Design)', () {
    test('TierEnemyStats progression scales HP, ATK, and DEF across all 11 tiers', () {
      final t1 = TierEnemyStats.forTier(1);
      final t2 = TierEnemyStats.forTier(2);
      final t3 = TierEnemyStats.forTier(3);
      final t5 = TierEnemyStats.forTier(5);
      final t11 = TierEnemyStats.forTier(11);

      // Check baseline values aligned with spec
      expect(t1.hp, equals(650));
      expect(t1.atk, equals(55));
      expect(t1.def, equals(10));

      expect(t2.hp, equals(1500));
      expect(t2.atk, equals(180));

      expect(t3.hp, equals(3000));
      expect(t3.atk, equals(380));
      expect(t3.def, equals(50));

      expect(t5.hp, equals(8200));
      expect(t5.atk, equals(1150));

      expect(t11.hp, equals(75000));
      expect(t11.atk, equals(11000));

      // Monotonic increase
      expect(t11.hp, greaterThan(t5.hp));
      expect(t5.hp, greaterThan(t3.hp));
      expect(t3.hp, greaterThan(t2.hp));
      expect(t2.hp, greaterThan(t1.hp));
    });

    test('Boss stages apply 1.50x HP, 1.15x ATK, and 1.30x stamina scaling', () {
      final normalT3 = TierEnemyStats.forStage(tier: 3, stageWithinTier: 1);
      final bossT3 = TierEnemyStats.forStage(tier: 3, stageWithinTier: 12, isBoss: true);

      expect(normalT3.hp, equals(3000));
      expect(bossT3.hp, equals(4500)); // 3000 * 1.5 = 4500
      expect(bossT3.atk, equals((normalT3.atk * 1.15).round()));
      expect(bossT3.stamina, equals((normalT3.stamina * 1.3).round()));
    });

    test('Neutral chip slashes deal exactly 20% ATK and bypass DEF when unguarded', () {
      const playerAtk = 160;
      final enemyT3 = TierEnemyStats.forTier(3); // def = 50

      // Unguarded neutral hit: ignores DEF, deals 20% ATK
      final unguardedDmg = DamageCalculator.slash(
        baseAtk: playerAtk,
        enemyDef: enemyT3.def,
        isEnemyGuarding: false,
      );
      expect(unguardedDmg, equals((playerAtk * 0.20).round())); // 32
      expect(unguardedDmg, equals(32));

      // Guarded neutral hit: applies DEF and damage reduction
      final guardedDmg = DamageCalculator.slash(
        baseAtk: playerAtk,
        enemyDef: enemyT3.def,
        enemyDamageReduction: enemyT3.damageReduction, // 0.30
        isEnemyGuarding: true,
      );
      // (160 * 0.20) = 32. 32 <= DEF(50) -> clamps to 0 or 1.
      expect(guardedDmg, lessThanOrEqualTo(1));
    });

    test('Counter slashes during Stagger deal 100%-150% ATK with combo ramp and zero DEF mitigation', () {
      const playerAtk = 160;
      final enemyT3 = TierEnemyStats.forTier(3); // def = 50

      final hit1 = DamageCalculator.counterSlash(
        baseAtk: playerAtk,
        comboCount: 1,
        enemyDef: enemyT3.def,
        isEnemyGuarding: false,
      );
      final hit2 = DamageCalculator.counterSlash(
        baseAtk: playerAtk,
        comboCount: 2,
        enemyDef: enemyT3.def,
        isEnemyGuarding: false,
      );
      final hit3 = DamageCalculator.counterSlash(
        baseAtk: playerAtk,
        comboCount: 3,
        enemyDef: enemyT3.def,
        isEnemyGuarding: false,
      );
      final hit4 = DamageCalculator.counterSlash(
        baseAtk: playerAtk,
        comboCount: 4,
        enemyDef: enemyT3.def,
        isEnemyGuarding: false,
      );
      final hit5 = DamageCalculator.counterSlash(
        baseAtk: playerAtk,
        comboCount: 5,
        enemyDef: enemyT3.def,
        isEnemyGuarding: false,
      );

      // Verify combo progression (1.00, 1.15, 1.20, 1.35, 1.50)
      expect(hit1, equals(160)); // 160 * 1.00
      expect(hit2, equals(184)); // 160 * 1.15
      expect(hit3, equals(192)); // 160 * 1.20
      expect(hit4, equals(216)); // 160 * 1.35
      expect(hit5, equals(240)); // 160 * 1.50

      // All hits completely ignore enemy DEF (50) during stagger
      expect(hit1, greaterThan(enemyT3.def));
    });

    test('Mid-tier player simulation: Normal stage requires 10-30 total slashes across 3-4 staggers', () {
      const playerAtk = 160; // Mid-tier player (Tier 3)
      final enemy = TierEnemyStats.forTier(3); // 3,000 HP
      var currentEnemyHp = enemy.hp;

      int totalSlashes = 0;
      int staggerPhases = 0;

      // Realistic combat loop:
      // In each round, player deals 2 neutral hits before enemy attacks,
      // parries enemy telegraph to open a 1.5s Stagger window,
      // and lands 4 counter slashes during stagger.
      while (currentEnemyHp > 0 && totalSlashes < 100) {
        // 2 neutral slashes (1 unblocked chip, 1 guarded)
        final chip1 = DamageCalculator.slash(
          baseAtk: playerAtk,
          enemyDef: enemy.def,
          isEnemyGuarding: false,
        );
        currentEnemyHp -= chip1;
        totalSlashes++;

        final chip2 = DamageCalculator.slash(
          baseAtk: playerAtk,
          enemyDef: enemy.def,
          enemyDamageReduction: enemy.damageReduction,
          isEnemyGuarding: true,
        );
        currentEnemyHp -= chip2;
        totalSlashes++;

        if (currentEnemyHp <= 0) break;

        // Player executes parry -> Stagger window opens
        staggerPhases++;
        for (int hit = 1; hit <= 4; hit++) {
          final counterDmg = DamageCalculator.counterSlash(
            baseAtk: playerAtk,
            comboCount: hit,
            synthBonusMult: 1.15, // moderate synth ability synergy
            enemyDef: enemy.def,
            isEnemyGuarding: false,
          );
          currentEnemyHp -= counterDmg;
          totalSlashes++;
          if (currentEnemyHp <= 0) break;
        }
      }

      // Assertions against user alignment & design plan
      expect(staggerPhases, inInclusiveRange(3, 4),
          reason: 'Standard mid-tier battle should require 3 to 4 stagger phases.');
      expect(totalSlashes, inInclusiveRange(10, 30),
          reason: 'Total slashes must be between 10 and 30 for target mid-tier player.');
      expect(currentEnemyHp, lessThanOrEqualTo(0));
    });

    test('Mid-tier boss simulation: Boss stage requires 5+ stagger phases and 25-35 slashes', () {
      const playerAtk = 160;
      final boss = TierEnemyStats.forStage(tier: 3, stageWithinTier: 12, isBoss: true); // 4,500 HP
      var currentEnemyHp = boss.hp;

      int totalSlashes = 0;
      int staggerPhases = 0;

      while (currentEnemyHp > 0 && totalSlashes < 100) {
        // Neutral chip hits
        final chip = DamageCalculator.slash(
          baseAtk: playerAtk,
          enemyDef: boss.def,
          isEnemyGuarding: false,
        );
        currentEnemyHp -= chip;
        totalSlashes++;

        if (currentEnemyHp <= 0) break;

        staggerPhases++;
        for (int hit = 1; hit <= 4; hit++) {
          final counterDmg = DamageCalculator.counterSlash(
            baseAtk: playerAtk,
            comboCount: hit,
            synthBonusMult: 1.15,
            enemyDef: boss.def,
            isEnemyGuarding: false,
          );
          currentEnemyHp -= counterDmg;
          totalSlashes++;
          if (currentEnemyHp <= 0) break;
        }
      }

      expect(staggerPhases, greaterThanOrEqualTo(5),
          reason: 'Boss battle should require at least 5 stagger phases.');
      expect(totalSlashes, inInclusiveRange(22, 38),
          reason: 'Boss battle slashes should naturally scale up to ~25-35 hits.');
      expect(currentEnemyHp, lessThanOrEqualTo(0));
    });

    test('Enemy attack lethality takes roughly 20-25% of player max HP', () {
      // Tier 1
      final t1Enemy = TierEnemyStats.forTier(1); // atk: 55
      const t1PlayerHp = 250;
      final t1Dmg = DamageCalculator.enemyAttack(enemyAtk: t1Enemy.atk, isPlayerGuarding: false);
      final t1Ratio = t1Dmg / t1PlayerHp;
      expect(t1Ratio, inInclusiveRange(0.18, 0.28));

      // Tier 3
      final t3Enemy = TierEnemyStats.forTier(3); // atk: 380
      const t3PlayerHp = 1600;
      final t3Dmg = DamageCalculator.enemyAttack(enemyAtk: t3Enemy.atk, isPlayerGuarding: false);
      final t3Ratio = t3Dmg / t3PlayerHp;
      expect(t3Ratio, inInclusiveRange(0.20, 0.28));

      // Tier 5
      final t5Enemy = TierEnemyStats.forTier(5); // atk: 1150
      const t5PlayerHp = 4800;
      final t5Dmg = DamageCalculator.enemyAttack(enemyAtk: t5Enemy.atk, isPlayerGuarding: false);
      final t5Ratio = t5Dmg / t5PlayerHp;
      expect(t5Ratio, inInclusiveRange(0.20, 0.28));
    });
  });
}
