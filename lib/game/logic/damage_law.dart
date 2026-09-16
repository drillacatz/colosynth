import 'dart:math';
import 'package:colosynth/game/logic/battle_constants.dart';

enum HitType { normal, activeskill, counterSlash }

class DamageLaw {
  static double resolveMult(HitType type, {int comboCount = 1, Random? rng}) {
    switch (type) {
      case HitType.normal:
        return DamageConstants.outOfStaggerDamageMult;
      case HitType.activeskill:
        return DamageConstants.activeSkillDamageMult;
      case HitType.counterSlash:
        if (comboCount >= 5) return DamageConstants.counterComboMult5;
        if (comboCount == 4) return DamageConstants.counterComboMult4;
        if (comboCount == 3) return DamageConstants.counterComboMult3;
        if (comboCount == 2) return DamageConstants.counterComboMult2;
        return DamageConstants.counterComboMult1;
    }
  }

  static int computeWithSynthBonus(
    int baseAtk,
    double damageReduction,
    int shield, {
    required HitType type,
    int defenderDef = 0,
    bool isDefenderGuarding = false,
    int comboCount = 1,
    double synthBonusMult = 1.0,
    Random? rng,
  }) {
    final mult = resolveMult(type, comboCount: comboCount, rng: rng) * synthBonusMult;
    final base = (baseAtk * mult).round();
    final effectiveDef = defenderDef > 0 ? defenderDef : shield;
    final net = isDefenderGuarding ? max(0, base - effectiveDef) : base;
    return net.clamp(DamageConstants.minDamage, DamageConstants.maxDamage);
  }

  static int compute(
    int baseAtk, {
    required HitType type,
    int defenderDef = 0,
    bool isDefenderGuarding = false,
    int comboCount = 1,
    double synthBonusMult = 1.0,
    Random? rng,
    double damageReduction = 0.0,
    int shield = 0,
  }) =>
      computeWithSynthBonus(
        baseAtk,
        damageReduction,
        shield,
        type: type,
        defenderDef: defenderDef,
        isDefenderGuarding: isDefenderGuarding,
        comboCount: comboCount,
        synthBonusMult: synthBonusMult,
        rng: rng,
      );
}
