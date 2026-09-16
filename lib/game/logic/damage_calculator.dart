import 'dart:math';

import 'package:colosynth/game/logic/battle_constants.dart';
import 'package:colosynth/game/logic/damage_law.dart';

class DamageCalculator {
  static int slash({
    required int baseAtk,
    int enemyDef = 0,
    bool isEnemyGuarding = false,
    double enemyDamageReduction = 0.0,
    int enemyShield = 0,
    int comboCount = 1,
    double synthBonusMult = 1.0,
  }) {
    return DamageLaw.computeWithSynthBonus(
      baseAtk,
      enemyDamageReduction,
      enemyShield,
      type: HitType.normal,
      defenderDef: enemyDef > 0 ? enemyDef : enemyShield,
      isDefenderGuarding: isEnemyGuarding,
      comboCount: comboCount,
      synthBonusMult: synthBonusMult,
    );
  }

  static int counterSlash({
    required int baseAtk,
    int enemyDef = 0,
    bool isEnemyGuarding = false,
    double enemyDamageReduction = 0.0,
    int enemyShield = 0,
    int comboCount = 1,
    double synthBonusMult = 1.0,
  }) {
    return DamageLaw.computeWithSynthBonus(
      baseAtk,
      enemyDamageReduction,
      enemyShield,
      type: HitType.counterSlash,
      defenderDef: enemyDef > 0 ? enemyDef : enemyShield,
      isDefenderGuarding: isEnemyGuarding,
      comboCount: comboCount,
      synthBonusMult: synthBonusMult,
    );
  }

  static int activeSkill({
    required int baseAtk,
    int enemyDef = 0,
    bool isEnemyGuarding = false,
    double enemyDamageReduction = 0.0,
    int enemyShield = 0,
    double synthBonusMult = 1.0,
  }) {
    return DamageLaw.computeWithSynthBonus(
      baseAtk,
      enemyDamageReduction,
      enemyShield,
      type: HitType.activeskill,
      defenderDef: enemyDef > 0 ? enemyDef : enemyShield,
      isDefenderGuarding: isEnemyGuarding,
      synthBonusMult: synthBonusMult,
    );
  }

  static int enemyAttack({
    required int enemyAtk,
    int playerDef = 0,
    bool isPlayerGuarding = false,
    double playerDamageReduction = 0.0,
    int playerShield = 0,
  }) {
    final baseAtk = (enemyAtk * 1.0).round();
    final effectiveDef = playerDef > 0 ? playerDef : playerShield;
    final net = isPlayerGuarding ? max(0, baseAtk - effectiveDef) : baseAtk;
    return net.clamp(DamageConstants.minDamage, DamageConstants.maxDamage);
  }
}
