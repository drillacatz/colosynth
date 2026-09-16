import 'package:colosynth/game/app_shell/battle_screen.dart';
import 'package:colosynth/game/logic/damage_calculator.dart';
import 'package:colosynth/game/skills/skill_effect.dart';
import 'package:colosynth/game/skills/skill_interface.dart';

class DivineStrike extends CharacterSkillImpl {
  @override
  String get id => 'arthur_active';

  @override
  bool get isPassive => false;

  @override
  void onActivate(BattleWorld game) {
    final dmg = DamageCalculator.activeSkill(
      baseAtk: game.playerStats.atk,
      enemyDef: game.enemy.def,
      isEnemyGuarding: game.enemy.isGuarding,
      enemyDamageReduction: game.enemy.damageReduction,
      enemyShield: game.enemy.shield,
    );

    game.applySkillEffect(SkillEffect(
      type: SkillEffectType.damageMultiplier,
      value: dmg.toDouble(),
    ));
  }

  @override
  void onPassiveTick(BattleWorld game, double dt) {}

  @override
  void reset() {}
}

class HolyAegis extends CharacterSkillImpl {
  double _healRatePerSec = 0.008;
  double _tickAccum = 0;

  @override
  String get id => 'arthur_passive';

  @override
  bool get isPassive => true;

  @override
  void onActivate(BattleWorld game) {}

  @override
  void onPassiveTick(BattleWorld game, double dt) {
    _tickAccum += dt;
    if (_tickAccum >= 1.0) {
      _tickAccum -= 1.0;
      game.applySkillEffect(SkillEffect(
        type: SkillEffectType.healPercent,
        value: _healRatePerSec,
      ));
    }
  }

  @override
  void reset() {
    _tickAccum = 0;
    _healRatePerSec = 0.008;
  }
}
