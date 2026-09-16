import 'package:colosynth/game_data/battle_anim.dart';
import 'package:colosynth/game/logic/battle_state_machine.dart';
import 'package:colosynth/game/logic/damage_calculator.dart';
import 'package:colosynth/game/logic/direction.dart';
import 'package:colosynth/game/logic/stamina_system.dart';
import 'package:colosynth/game/logic/skill_meter.dart';


class BattleEngine {
  final Combatant player;
  final Combatant enemy;
  final BattleStateMachine fsm;
  final StaminaSystem playerStamina;
  final StaminaSystem enemyStamina;
  final ActiveSkillMeter playerSkill;
  final ActiveSkillMeter? enemySkill;

  BattleEngine({
    required this.player,
    required this.enemy,
    required this.fsm,
    required this.playerStamina,
    required this.enemyStamina,
    required this.playerSkill,
    this.enemySkill,
  });


  int resolvePlayerAttack({
    required AttackDirection direction,
    required int playerAtk,
    int enemyDef = 0,
    bool isEnemyGuarding = false,
    double enemyDamageReduction = 0.0,
    int enemyShield = 0,
    int comboCount = 1,
  }) {
    final dmg = DamageCalculator.slash(
      baseAtk: playerAtk,
      enemyDef: enemyDef > 0 ? enemyDef : enemyShield,
      isEnemyGuarding: isEnemyGuarding,
      enemyDamageReduction: enemyDamageReduction,
      enemyShield: enemyShield,
      comboCount: comboCount,
    );

    enemy.takeDamage(dmg, DamageType.normal, direction: direction);
    playerSkill.onHitNormal();

    return dmg;
  }

  BattleState resolveEnemyAttack({
    required AttackDirection enemyDir,
    required AttackDirection? queuedSwipe,
    required bool isPlayerBlocking,
    required bool isPlayerDodging,
    required bool? dodgeIsLeft,
    required int enemyAtk,
    double playerDamageReduction = 0.0,
    int playerShield = 0,
  }) {
    if (queuedSwipe != null && queuedSwipe.isOppositeOf(enemyDir)) {
      enemyStamina.drainFromSuccessfulParry();
      playerSkill.onParry();
      return BattleState.parrySuccess;
    }

    if (isPlayerDodging && dodgeIsLeft != null) {
      final dodgeDir = dodgeIsLeft ? DodgeDirection.left : DodgeDirection.right;
      if (enemyDir.canDodgeWith(dodgeDir)) {
        enemyStamina.drainFromSuccessfulDodge();
        playerSkill.onDodge();
        return BattleState.dodgeSuccess;
      }
      return BattleState.dodgeFail;
    }

    if (isPlayerBlocking && !playerStamina.isExhausted) {
      enemyStamina.drainFromSuccessfulDefense();
      return BattleState.blockSuccess;
    }

    return BattleState.enemyHit;
  }

  int applyEnemyDamage({
    required int enemyAtk,
    int playerDef = 0,
    bool isPlayerGuarding = false,
    double playerDamageReduction = 0.0,
    int playerShield = 0,
    required AttackDirection direction,
  }) {
    final dmg = DamageCalculator.enemyAttack(
      enemyAtk: enemyAtk,
      playerDef: playerDef > 0 ? playerDef : playerShield,
      isPlayerGuarding: isPlayerGuarding,
      playerDamageReduction: playerDamageReduction,
      playerShield: playerShield,
    );
    player.takeDamage(dmg, DamageType.normal, direction: direction);
    return dmg;
  }

  int resolveActiveSkill({
    required int playerAtk,
    int enemyDef = 0,
    bool isEnemyGuarding = false,
    double enemyDamageReduction = 0.0,
    int enemyShield = 0,
    required AttackDirection direction,
  }) {
    final dmg = DamageCalculator.activeSkill(
      baseAtk: playerAtk,
      enemyDef: enemyDef > 0 ? enemyDef : enemyShield,
      isEnemyGuarding: isEnemyGuarding,
      enemyDamageReduction: enemyDamageReduction,
      enemyShield: enemyShield,
    );
    enemy.takeDamage(dmg, DamageType.activeSkill, direction: direction);
    enemyStamina.drainPercent(1.0);
    return dmg;
  }

  int resolveCounterSlash({
    required AttackDirection direction,
    required int playerAtk,
    int enemyDef = 0,
    bool isEnemyGuarding = false,
    double enemyDamageReduction = 0.0,
    int enemyShield = 0,
    int counterComboCount = 1,
    double synthBonusMult = 1.0,
  }) {
    final dmg = DamageCalculator.counterSlash(
      baseAtk: playerAtk,
      enemyDef: enemyDef > 0 ? enemyDef : enemyShield,
      isEnemyGuarding: isEnemyGuarding,
      enemyDamageReduction: enemyDamageReduction,
      enemyShield: enemyShield,
      comboCount: counterComboCount,
      synthBonusMult: synthBonusMult,
    );

    enemy.takeDamage(dmg, DamageType.normal, direction: direction);
    playerSkill.onCounterSlash();

    return dmg;
  }
}
