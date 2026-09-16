import 'dart:math';

import 'package:colosynth/game/logic/battle_state_machine.dart';
import 'package:colosynth/game_data/battle_anim.dart';
import 'package:colosynth/game/logic/direction.dart';
import 'package:colosynth/game/logic/stamina_system.dart';
import 'package:colosynth/game/ai/ai_profiles.dart';

class EnemyBehaviorTree {
  final AiProfile profile;
  final BattleStateMachine fsm;
  final Combatant enemy;
  final Combatant player;
  final StaminaSystem enemyStamina;

  final _rng = Random();

  double _attackCooldown = 0;
  bool _isBlocking = false;



  bool _nextAttackIsCombo = false;
  bool _nextAttackIsUnblockable = false;
  AttackDirection _currentAttackDirection = AttackDirection.e;


  bool get isBlocking => _isBlocking;

  bool get isAttackingCombo => _nextAttackIsCombo;


  bool get isAttackingUnblockable => _nextAttackIsUnblockable;


  AttackDirection get currentAttackDirection => _currentAttackDirection;

  EnemyBehaviorTree({
    required this.profile,
    required this.fsm,
    required this.enemy,
    required this.player,
    required this.enemyStamina,
  }) {
    _attackCooldown = profile.attackInterval;
  }


  void update(double dt) {
    if (fsm.isBattleOver) return;

    enemyStamina.update(dt);

    final desperationMod = enemy.hpRatio < 0.20 ? 0.5 : 1.0;
    _attackCooldown -= dt;
    if (_attackCooldown <= 0 && fsm.isIdle) {
      _decideNextAttack();
      _triggerAttack();
      _attackCooldown = profile.attackInterval * desperationMod;
    }
  }

  void _decideNextAttack() {

    _nextAttackIsCombo = false;
    _nextAttackIsUnblockable = false;

    _currentAttackDirection =
        AttackDirection.values[_rng.nextInt(AttackDirection.values.length)];

    if (_roll(profile.comboProbability)) {
      _nextAttackIsCombo = true;
    }

    if (_roll(profile.unblockableRate)) {
      _nextAttackIsUnblockable = true;
    }
  }

  void _triggerAttack() {
    fsm.transition(BattleState.enemyTelegraph);
  }

  bool tryDefend() {
    _isBlocking = false;

    if (!enemyStamina.isExhausted && _roll(profile.blockProbability)) {
      _isBlocking = true;
      enemyStamina.setBlocking(true);
      return true;
    }

    if (_roll(profile.dodgeProbability)) {
      return false;
    }

    return false;
  }

  void clearBlock() {
    _isBlocking = false;
    enemyStamina.setBlocking(false);
  }

  void reset() {
    _attackCooldown = profile.attackInterval;
    _isBlocking = false;

    _nextAttackIsCombo = false;
    _nextAttackIsUnblockable = false;
    _currentAttackDirection = AttackDirection.e;
  }

  bool _roll(double probability) => _rng.nextDouble() < probability;
}
