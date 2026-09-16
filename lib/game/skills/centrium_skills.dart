import 'package:colosynth/game/app_shell/battle_screen.dart';
import 'package:colosynth/game/logic/damage_calculator.dart';
import 'package:colosynth/game/skills/skill_effect.dart';
import 'package:colosynth/game/skills/skill_interface.dart';

class ArcSurge extends CharacterSkillImpl {
  double _damageMult = 1.5;

  @override
  String get id => 'centrium_active';

  @override
  bool get isPassive => false;

  @override
  void onActivate(BattleWorld game) {
    final raw = DamageCalculator.activeSkill(
      baseAtk: game.playerStats.atk,
      enemyDef: game.enemy.def,
      isEnemyGuarding: game.enemy.isGuarding,
      enemyDamageReduction: game.enemy.damageReduction,
      enemyShield: game.enemy.shield,
    );

    game.applySkillEffect(SkillEffect(
      type: SkillEffectType.damageMultiplier,
      value: (raw * _damageMult).toDouble(),
    ));

    game.applySkillEffect(const SkillEffect(
      type: SkillEffectType.activeSkillCharge,
      value: 25,
    ));
  }

  @override
  void onPassiveTick(BattleWorld game, double dt) {}

  @override
  void reset() => _damageMult = 1.5;
}

class StoneSkin extends CharacterSkillImpl {
  double _damageReduction = 0.15;
  double _reflectRatio = 0.05;

  @override
  String get id => 'centrium_passive';

  @override
  bool get isPassive => true;

  @override
  void onActivate(BattleWorld game) {}

  @override
  void onPassiveTick(BattleWorld game, double dt) {
    game.applySkillEffect(SkillEffect(
      type: SkillEffectType.damageReduction,
      value: _damageReduction,
    ));
  }

  @override
  void onHurt(BattleWorld game) {
    game.applySkillEffect(SkillEffect(
      type: SkillEffectType.damageReflect,
      value: _reflectRatio,
    ));
  }

  @override
  void reset() {
    _damageReduction = 0.15;
    _reflectRatio = 0.05;
  }
}
