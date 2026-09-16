import 'package:colosynth/game/logic/damage_calculator.dart';
import 'package:colosynth/game/skills/skill_effect.dart';
import 'package:colosynth/game/skills/skill_interface.dart';
import 'package:colosynth/game/app_shell/battle_screen.dart' show BattleWorld;


class ShadowStep extends CharacterSkillImpl {
  double _damageMult = 2.5;

  @override
  String get id => 'lilith_active';

  @override
  bool get isPassive => false;

  @override
  void onActivate(BattleWorld world) {
    final raw = DamageCalculator.activeSkill(
      baseAtk: world.playerStats.atk,
      enemyDef: 0,
      isEnemyGuarding: false,
      enemyDamageReduction: 0.0,
      enemyShield: 0,
    );

    world.applySkillEffect(SkillEffect(
      type: SkillEffectType.damageMultiplier,
      value: (raw * _damageMult).toDouble(),
    ));
  }

  @override
  void onPassiveTick(BattleWorld world, double dt) {}

  @override
  void reset() => _damageMult = 2.5;
}


class SoulDrain extends CharacterSkillImpl {
  double _lifeStealRatio = 0.20;

  @override
  String get id => 'lilith_passive';

  @override
  bool get isPassive => true;

  @override
  void onActivate(BattleWorld game) {}

  @override
  void onPassiveTick(BattleWorld game, double dt) {}

  @override
  void onHit(BattleWorld game) {
    game.applySkillEffect(SkillEffect(
      type: SkillEffectType.lifeSteal,
      value: _lifeStealRatio,
    ));
  }

  @override
  void reset() => _lifeStealRatio = 0.20;
}
