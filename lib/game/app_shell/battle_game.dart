import 'dart:math' as math;
import 'package:colosynth/services/battle_stats_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flame/game.dart';

import 'package:colosynth/database/character/battle_stats.dart';
import 'package:colosynth/game_data/battle_anim.dart';
import 'package:colosynth/providers/battle_provider.dart';
import 'package:colosynth/providers/save_provider.dart';
import 'package:colosynth/game/ai/ai_profiles.dart';
import 'package:colosynth/game/event_bus/game_event_bus.dart';
import 'package:colosynth/game/event_bus/game_events.dart';
import 'package:colosynth/services/stats/player_stats_tracker.dart';
import 'package:colosynth/game/camera/game_camera.dart';
import 'package:colosynth/game/components/damage_number.dart';
import 'package:colosynth/game/components/dodge_effect.dart';
import 'package:colosynth/game/components/enemy_component.dart';
import 'package:colosynth/game/components/hurt_overlay.dart';
import 'package:colosynth/game/components/parry_particle.dart';
import 'package:colosynth/game/components/player_component.dart';
import 'package:colosynth/game/logic/battle_constants.dart';
import 'package:colosynth/game/logic/battle_engine.dart';
import 'package:colosynth/game/logic/battle_state_machine.dart';
import 'package:colosynth/game/logic/combat_input_handler.dart';
import 'package:colosynth/game/logic/direction.dart';
import 'package:colosynth/game/logic/skill_meter.dart';
import 'package:colosynth/game/logic/stamina_system.dart';
import 'package:colosynth/game/logic/counter_synth_controller.dart';
import 'package:colosynth/game/skills/skill_effect.dart';
import 'package:colosynth/services/synth/synth_crate_service.dart';
import 'package:colosynth/game/app_shell/battle_models.dart';
import 'package:colosynth/utils/component_pool.dart';

final battleGameProvider =
    Provider.family.autoDispose<BattleFlameGame, BattleGameParams>(
  (ref, params) {
    final stats = ref.watch(battleStatsProvider).value;
    if (stats == null) {
      throw StateError('BattleStats not loaded yet');
    }

    final game = BattleFlameGame(
      ref: ref,
      playerStats: stats,
      aiProfile: params.aiProfile,
      tier: params.tier,
      slotId: params.slotId,
      mode: params.mode,
    );
    ref.onDispose(() => game.onRemove());
    return game;
  },
);

class BattleFlameGame extends BattleGameBase with BattleGameApi {
  @override
  final ValueNotifier<BattleResult?> battleResultNotifier = ValueNotifier(null);
  @override
  final ValueNotifier<double> playerHpFraction = ValueNotifier(1.0);
  @override
  final ValueNotifier<double> enemyHpFraction = ValueNotifier(1.0);
  @override
  final ValueNotifier<int> damageEventNotifier = ValueNotifier(0);

  @override
  final BattleStats playerStats;
  final Ref ref;
  final AiProfile aiProfile;
  final int tier;
  final String slotId;
  final BattleMode mode;

  late final BattleStateMachine _fsm;
  late final StaminaSystem _stamina;
  late final ActiveSkillMeter _activeSkill;
  late final BattleStatsTracker _stats;
  late final PlayerComponent _playerComponent;
  late final EnemyComponent _enemyComponent;
  late final BattleEngine _engine;
  late final ComponentPool<DamageNumber> _damageNumberPool;
  late CounterSynthController _counterSynth;

  AttackDirection _enemyDir = AttackDirection.n;
  AttackDirection? _queuedSwipe;
  double _stateTimer = 0;
  double _idleTimer = 0;
  int _damageId = 0;
  bool _battleEnded = false;
  int _battleSessionId = 0;
  bool _isDisposed = false;
  double _timeScale = 1.0;
  AttackDirection? _bufferedSlash;
  double _bufferTimer = 0.0;

  static const double _minIdleSecs = BattleTimings.minIdleSecs;
  static const double _maxIdleSecs = BattleTimings.maxIdleSecs;
  static const double _telegraphDuration = BattleTimings.telegraphDuration;
  static const double _parryFlashDuration = BattleTimings.parryFlashDuration;
  static const double _slashBriefDuration = BattleTimings.slashBriefDuration;
  static const double _hurtDuration = BattleTimings.hurtDuration;
  static const double _dodgeStateDuration = BattleTimings.dodgeStateDuration;
  static const double _enemyHitLeadIn = BattleTimings.enemyHitLeadIn;
  static const double _skillDuration = BattleTimings.skillDuration;
  static const double _kMaxBufferTime = InputConstants.maxBufferTime;

  final math.Random _rng = math.Random();

  BattleFlameGame({
    required this.ref,
    required this.playerStats,
    required this.aiProfile,
    required this.tier,
    required this.slotId,
    required this.mode,
  });

  @override
  BattleStateMachine get fsm => _fsm;
  @override
  AttackDirection get currentEnemyDirection => _enemyDir;
  @override
  String get enemyDisplayName => aiProfile.name;
  @override
  Combatant get player => _playerComponent;
  @override
  Combatant get enemy => _enemyComponent;
  @override
  StaminaSystem get stamina => _stamina;
  @override
  ActiveSkillMeter get activeSkill => _activeSkill;
  @override
  BattleStatsTracker get stats => _stats;

  @override
  Future<void> onLoad() async {
    PlayerStatsTracker.instance.startBattle();
    _damageNumberPool = ComponentPool<DamageNumber>(
        create: () => DamageNumber(), initialSize: 12);
    _fsm = BattleStateMachine();
    _stamina = StaminaSystem();
    _activeSkill = ActiveSkillMeter();
    _stats = BattleStatsTracker();

    final equippedCharId = ref.read(equippedCharacterIdProvider);
    _enemyComponent = EnemyComponent(profile: aiProfile, tournamentTier: tier);
    _playerComponent = PlayerComponent(
      playerStats: playerStats,
      characterId: equippedCharId,
    );

    final equippedDefs = SynthCrateService.instance.loadEquippedDefinitions(
      equippedCharId,
    );
    _counterSynth = CounterSynthController(equippedDefinitions: equippedDefs);

    _engine = BattleEngine(
      player: _playerComponent,
      enemy: _enemyComponent,
      fsm: _fsm,
      playerStamina: _stamina,
      enemyStamina: _enemyComponent.stamina,
      playerSkill: _activeSkill,
    );

    await addAll([
      _enemyComponent,
      _playerComponent,
      BattleCamera(
        fsm: _fsm,
        player: _playerComponent,
        enemy: _enemyComponent,
      ),
      CombatInputHandler(world: this),
    ]);

    _scheduleIdle();
  }

  @override
  void update(double dt) {
    final effectiveDt = dt * _timeScale;
    super.update(effectiveDt);
    if (_fsm.isBattleOver) return;

    final stamina = _stamina;
    final enemyStamina = _enemyComponent.stamina;

    stamina.update(effectiveDt);
    enemyStamina.update(effectiveDt);

    if (_stateTimer > 0) {
      _stateTimer -= effectiveDt;
      if (_stateTimer <= 0) {
        _stateTimer = 0;
        _onTimerExpired();
        return;
      }
    } else {
      if (_fsm.isIdle) {
        _idleTimer -= effectiveDt;
        if (_idleTimer <= 0) _beginEnemyTelegraph();
      }

      if (_bufferTimer > 0) {
        _bufferTimer -= effectiveDt;
        if (_bufferTimer <= 0) {
          _bufferTimer = 0;
          _bufferedSlash = null;
        } else if (_canPlayerSlash()) {
          final dir = _bufferedSlash!;
          _bufferedSlash = null;
          _bufferTimer = 0;
          _executePlayerSlash(dir);
        }
      }
    }
  }

  @pragma('vm:prefer-inline')
  void _scheduleIdle() {
    _idleTimer =
        _minIdleSecs + _rng.nextDouble() * (_maxIdleSecs - _minIdleSecs);
  }

  @pragma('vm:prefer-inline')
  void _returnToIdle() {
    _fsm.transition(BattleState.idle);
    _scheduleIdle();
  }

  @pragma('vm:prefer-inline')
  void _beginEnemyTelegraph() {
    _enemyDir =
        AttackDirection.values[_rng.nextInt(AttackDirection.values.length)];
    _queuedSwipe = null;
    _fsm.transition(BattleState.enemyTelegraph);
    _stateTimer = _telegraphDuration;
  }

  void _onTimerExpired() {
    switch (_fsm.current) {
      case BattleState.enemyTelegraph:
        _resolveEnemyAttack();
      case BattleState.parrySuccess:
      case BattleState.dodgeSuccess:
        if (!_battleEnded) {
          _fsm.transition(BattleState.counterWindow);
          _stateTimer = 1.5;
          GameEventBus.instance.emit(const CounterStartEvent());
        }
      case BattleState.playerSlash:
        if (!_battleEnded) {
          _fsm.transition(BattleState.enemyHurt);
          _stateTimer = _hurtDuration;
        }
      case BattleState.enemyHurt:
        _returnToIdle();
      case BattleState.blockSuccess:
      case BattleState.blockedRecoil:
        _returnToIdle();
      case BattleState.dodgeFail:
        _applyEnemyDamage();
      case BattleState.enemyHit:
        _applyEnemyDamage();
      case BattleState.playerHurt:
        _returnToIdle();
      case BattleState.activeSkill:
        if (!_battleEnded) {
          _triggerCounterWindow();
        }
      case BattleState.counterWindow:
        _returnToIdle();
      default:
        break;
    }
  }

  void _resolveEnemyAttack() {
    final resultState = _engine.resolveEnemyAttack(
      enemyDir: _enemyDir,
      queuedSwipe: _queuedSwipe,
      isPlayerBlocking: _playerComponent.isBlocking,
      isPlayerDodging: _playerComponent.isDodging,
      dodgeIsLeft: _playerComponent.dodgeIsLeft,
      enemyAtk: _enemyComponent.tierStats.atk,
      playerDamageReduction: playerStats.damageReduction,
      playerShield: playerStats.shield,
    );

    if (resultState == BattleState.parrySuccess) {
      _stats.recordParry();
      spawnParryParticles(this, _enemyCenter());
      GameEventBus.instance.emit(const ParrySuccessEvent());
    } else if (resultState == BattleState.dodgeSuccess) {
      _stats.recordSuccessfulDodge();
      spawnDodgeEffect(this, _playerCenter());
      GameEventBus.instance.emit(const DodgeSuccessEvent());
    } else if (resultState == BattleState.blockSuccess) {
      GameEventBus.instance.emit(const BlockSuccessEvent());
    }

    _fsm.transition(resultState);
    _stateTimer = (resultState == BattleState.parrySuccess)
        ? _parryFlashDuration
        : (resultState == BattleState.enemyHit ||
                resultState == BattleState.dodgeFail)
            ? _enemyHitLeadIn
            : (resultState == BattleState.dodgeSuccess)
                ? _dodgeStateDuration
                : _hurtDuration;
  }

  @pragma('vm:prefer-inline')
  void _applyEnemyDamage() {
    if (_battleEnded) return;

    final dmg = _engine.applyEnemyDamage(
      enemyAtk: _enemyComponent.tierStats.atk,
      playerDef: playerStats.def,
      isPlayerGuarding: _playerComponent.isBlocking,
      playerDamageReduction: playerStats.damageReduction,
      playerShield: playerStats.shield,
      direction: _enemyDir,
    );

    playerHpFraction.value = _playerComponent.hpRatio;
    _emitDamageEvent(dmg, isPlayer: true);
    _stats.resetCombo();

    if (_playerComponent.isDead) {
      _endBattle(victory: false);
      return;
    }

    _fsm.transition(BattleState.playerHurt);
    _stateTimer = _hurtDuration;
  }

  bool _canPlayerSlash() {
    final s = _fsm.current;
    if (s == BattleState.idle) return true;

    if (s == BattleState.playerSlash &&
        _stateTimer < BattleTimings.slashCancelEarlyWindow) {
      return true;
    }

    if (s == BattleState.enemyHurt &&
        _stateTimer < BattleTimings.hurtCancelEarlyWindow) {
      return true;
    }

    return false;
  }

  void _executePlayerSlash(AttackDirection direction) {
    final currentCombo = _stats.currentCombo + 1;
    final dmg = _engine.resolvePlayerAttack(
      direction: direction,
      playerAtk: playerStats.atk,
      enemyDef: _enemyComponent.tierStats.def,
      isEnemyGuarding: _enemyComponent.isGuarding,
      enemyDamageReduction: _enemyComponent.tierStats.damageReduction,
      enemyShield: _enemyComponent.tierStats.shield,
      comboCount: currentCombo,
    );

    enemyHpFraction.value = _enemyComponent.hpRatio;
    _emitDamageEvent(dmg, isPlayer: false);

    if (dmg > 0) {
      _stats.recordHit();
    }

    if (_enemyComponent.isDead) {
      _endBattle(victory: true);
      return;
    }

    _fsm.transition(BattleState.playerSlash);
    _stateTimer = _slashBriefDuration;
  }

  void _executePlayerCounterSlash(
      AttackDirection direction, double synthBonusMult) {
    final dmg = _engine.resolveCounterSlash(
      direction: direction,
      playerAtk: playerStats.atk,
      enemyDef: _enemyComponent.tierStats.def,
      isEnemyGuarding: false,
      enemyDamageReduction: _enemyComponent.tierStats.damageReduction,
      enemyShield: _enemyComponent.tierStats.shield,
      synthBonusMult: synthBonusMult,
    );

    enemyHpFraction.value = _enemyComponent.hpRatio;
    _emitDamageEvent(dmg, isPlayer: false);

    if (dmg > 0) {
      _stats.recordHit();
      GameEventBus.instance.emit(CounterSlashEvent(dmg.toDouble()));
    }

    if (_enemyComponent.isDead) {
      _endBattle(victory: true);
      return;
    }

    _playerComponent.playAnimation(CombatAnimation.attack);
  }

  double _getSynthBonusMult(AttackDirection direction) {
    final result = _counterSynth.feedDirectionInCounterWindow(direction);
    if (result.completed.isNotEmpty) {
      final triggered = _counterSynth.lastTriggered;
      if (triggered != null) {
        GameEventBus.instance.emit(SynthAbilityTriggeredEvent(triggered.id));
        _activeSkill.addCharge(triggered.activeSkillChargeBonus);
        return triggered.bonusDamageMult;
      }
    }
    return 1.0;
  }

  @override
  void onPlayerSwipe(AttackDirection direction) {
    if (_battleEnded || _fsm.isBattleOver) return;

    if (_fsm.isInCounterWindow) {
      final mult = _getSynthBonusMult(direction);
      _executePlayerCounterSlash(direction, mult);
      return;
    }

    if (_fsm.current == BattleState.enemyTelegraph) {
      _queuedSwipe = direction;
      if (direction.isOppositeOf(_enemyDir)) {
        _stateTimer = 0.01;
      }
      return;
    }

    if (_canPlayerSlash()) {
      _executePlayerSlash(direction);
    } else {
      _bufferedSlash = direction;
      _bufferTimer = _kMaxBufferTime;
    }
  }

  @override
  void onPlayerBlockStart() {
    if (_battleEnded || _fsm.isBattleOver) return;
    _playerComponent.startBlock();
  }

  @override
  void onPlayerBlockEnd() {
    _playerComponent.endBlock();
  }

  @override
  void onPlayerDodge({required bool isLeft}) {
    if (_battleEnded || _fsm.isBattleOver || !_stamina.canDodge) return;
    _playerComponent.setDodgeDirection(isLeft: isLeft);
    _stamina.consumeDodge();
    if (_fsm.current != BattleState.enemyTelegraph) {
      _fsm.transition(BattleState.dodgeSuccess);
      _stateTimer = _dodgeStateDuration;
    }
  }

  @override
  void onPlayerActiveSkill() {
    if (_battleEnded || _fsm.isBattleOver || !_activeSkill.canActivate) return;
    if (!_activeSkill.consume()) return;

    _stats.recordSkillUse();

    final dmg = _engine.resolveActiveSkill(
      playerAtk: playerStats.atk,
      enemyDef: _enemyComponent.tierStats.def,
      isEnemyGuarding: _enemyComponent.isGuarding,
      enemyDamageReduction: _enemyComponent.tierStats.damageReduction,
      enemyShield: _enemyComponent.tierStats.shield,
      direction: _enemyDir,
    );
    enemyHpFraction.value = _enemyComponent.hpRatio;
    _emitDamageEvent(dmg, isPlayer: false);

    if (_enemyComponent.isDead) {
      _endBattle(victory: true);
      return;
    }

    _fsm.transition(BattleState.activeSkill);
    _stateTimer = _skillDuration;
  }

  @override
  void applySkillEffect(SkillEffect effect) {
    switch (effect.type) {
      case SkillEffectType.damageMultiplier:
        final dmg = (playerStats.atk * effect.value).round();
        _enemyComponent.takeDamage(dmg, DamageType.activeSkill,
            direction: AttackDirection.n);
        enemyHpFraction.value = _enemyComponent.hpRatio;
        _emitDamageEvent(dmg, isPlayer: false);
      case SkillEffectType.healPercent:
        _playerComponent.heal((_playerComponent.maxHp * effect.value).round());
        playerHpFraction.value = _playerComponent.hpRatio;
      case SkillEffectType.staminaRestore:
        _stamina.restore(effect.value.round());
      case SkillEffectType.activeSkillCharge:
        _activeSkill.addCharge(effect.value.round());
      case SkillEffectType.lifeSteal:
        final heal = (playerStats.atk * effect.value).round();
        _playerComponent.heal(heal);
        playerHpFraction.value = _playerComponent.hpRatio;
      case SkillEffectType.damageReduction:
        break;
      case SkillEffectType.damageReflect:
        break;
    }
  }

  @override
  void shakeCamera(double amplitude) {
    final camera = children.query<BattleCamera>().firstOrNull;
    camera?.shake(amplitude);
  }

  @override
  void quit() {
    if (_battleEnded) return;
    _battleEnded = true;
    battleResultNotifier.value = BattleResult.empty(BattleOutcome.quit);
    GameEventBus.instance.emit(const BattleQuitEvent());
  }

  @override
  void resetBattle() {
    PlayerStatsTracker.instance.startBattle();
    _battleEnded = false;
    _timeScale = 1.0;
    _battleSessionId++;
    _stateTimer = 0;
    _queuedSwipe = null;
    _fsm.reset();
    _stamina.reset();
    _activeSkill.reset();
    _stats.reset();
    _playerComponent.reset();
    _enemyComponent.reset();
    playerHpFraction.value = 1.0;
    enemyHpFraction.value = 1.0;
    battleResultNotifier.value = null;
    _scheduleIdle();
  }

  @override
  void revive() {
    PlayerStatsTracker.instance.startBattle();
    _battleEnded = false;
    _timeScale = 1.0;
    _battleSessionId++;
    _stateTimer = 0;
    _queuedSwipe = null;
    _fsm.reset();
    _stamina.reset();
    _activeSkill.reset();
    _playerComponent.revive();
    playerHpFraction.value = 1.0;
    battleResultNotifier.value = null;
    _scheduleIdle();
  }

  void _endBattle({required bool victory}) {
    if (_battleEnded) return;
    _battleEnded = true;

    _playerComponent.endBlock();

    _fsm.transition(victory ? BattleState.victory : BattleState.defeat);

    if (victory) {
      GameEventBus.instance
          .emit(VictoryEvent(mode, tier: tier, slotId: slotId));
    } else {
      GameEventBus.instance.emit(DefeatEvent(mode));
    }

    final score = (enemy.maxHp - enemy.currentHp).round() +
        _stats.maxCombo * RewardConstants.comboScorePerHit;
    final rewardMult =
        _playerComponent.hpRatio >= RewardConstants.rewardHpThreshold
            ? RewardConstants.rewardMultFull
            : RewardConstants.rewardMultLow;

    final inkEarned = victory
        ? (score / RewardConstants.inkScoreDivisor * rewardMult).round().clamp(
            RewardConstants.inkMinPerVictory, RewardConstants.inkMaxPerVictory)
        : 0;

    const paintEarned = 0;
    final xpEarned = victory
        ? (tier * RewardConstants.xpTierMultiplier +
            RewardConstants.xpVictoryBase)
        : RewardConstants.xpOnDefeat;

    final result = BattleResult(
      outcome: victory ? BattleOutcome.victory : BattleOutcome.defeat,
      finalHpPercent: _playerComponent.hpRatio,
      parryCount: _stats.parryCount,
      dodgeCount: _stats.dodgeCount,
      brokenCount: _stats.brokenCount,
      skillUseCount: _stats.skillUseCount,
      score: score,
      inkEarned: inkEarned,
      paintEarned: paintEarned,
      xpEarned: xpEarned,
    );

    if (victory) {
      _timeScale = BattleTimings.victorySlowMoScale;
    }

    final capturedSessionId = _battleSessionId;
    Future.delayed(
      Duration(
        milliseconds: victory
            ? BattleTimings.victoryResultDelayMs
            : BattleTimings.defeatResultDelayMs,
      ),
      () {
        if (_isDisposed) {
          debugPrint('BattleFlameGame: Disposed before result could be set.');
          return;
        }
        if (_battleSessionId != capturedSessionId) return;

        try {
          battleResultNotifier.value = result;
        } catch (e) {
          debugPrint('Error updating battle result: $e');
        }
      },
    );
  }

  @pragma('vm:prefer-inline')
  void _emitDamageEvent(int amount, {required bool isPlayer}) {
    _damageId = (_damageId + 1) & 0x7FFFFFFF;
    damageEventNotifier.value = _damageId;

    final targetPos = isPlayer ? _playerCenter() : _enemyCenter();
    final dmgNum = _damageNumberPool.obtain((d) {
      d.reinit(
        amount: amount,
        position: targetPos,
        isPlayerDamage: isPlayer,
        onRecycle: _damageNumberPool.recycle,
      );
    });
    add(dmgNum);

    if (isPlayer) {
      add(HurtOverlay());
      shakeCamera(6.0);
    }
  }

  Vector2 _enemyCenter() => Vector2(
        _enemyComponent.position.x,
        _enemyComponent.position.y - _enemyComponent.size.y * 0.5,
      );

  Vector2 _playerCenter() => Vector2(
        _playerComponent.position.x,
        _playerComponent.position.y - _playerComponent.size.y * 0.5,
      );

  @override
  void onEnemyStaminaExhausted() {
    if (_battleEnded || _fsm.isBattleOver) return;
    final s = _fsm.current;
    if (s == BattleState.activeSkill ||
        s == BattleState.parrySuccess ||
        s == BattleState.dodgeSuccess ||
        s == BattleState.counterWindow) {
      return;
    }
    _triggerCounterWindow();
  }

  void _triggerCounterWindow() {
    if (_fsm.isBattleOver) return;
    _stats.recordBroken();
    GameEventBus.instance.emit(const BrokenEvent());
    _fsm.transition(BattleState.counterWindow);
    _stateTimer = 1.5;
    GameEventBus.instance.emit(const CounterStartEvent());
    _enemyComponent.stamina.reset();
  }

  @override
  void onRemove() {
    if (_isDisposed) return;
    _isDisposed = true;

    _damageNumberPool.clear();
    _stamina.dispose();
    _activeSkill.dispose();
    battleResultNotifier.dispose();
    playerHpFraction.dispose();
    enemyHpFraction.dispose();
    damageEventNotifier.dispose();

    super.onRemove();
  }
}
