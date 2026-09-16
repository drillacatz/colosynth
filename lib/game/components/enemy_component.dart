import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:colosynth/services/sprite_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:colosynth/game_data/battle_anim.dart';
import 'package:colosynth/game/logic/battle_constants.dart';
import 'package:colosynth/game/logic/direction.dart';
import 'package:colosynth/game/logic/stamina_system.dart';
import 'package:colosynth/game/logic/skill_meter.dart';
import 'package:colosynth/game/ai/ai_profiles.dart';
import 'package:colosynth/game_data/tier_enemy_stats.dart';
import 'package:colosynth/game/logic/battle_state_machine.dart';
import 'package:colosynth/game/app_shell/battle_models.dart';
import 'package:colosynth/game/components/slash_effect.dart';

class EnemyComponent extends PositionComponent
    with HasGameReference<BattleWorld>
    implements Combatant {
  BattleWorld get world => game;
  final AiProfile profile;
  final TierEnemyStats tierStats;

  int _currentHp;
  final int _maxHp;
  bool _isBlocking = false;

  final StaminaSystem stamina;
  final ActiveSkillMeter? activeSkill;
  final ValueNotifier<int> hpNotifier;

  late final TextComponent _stateText;
  bool _fsmListenerAdded = false;

  late final TextComponent _telegraphArrow;
  double _telegraphPulse = 0.0;
  bool _telegraphActive = false;

  final _labelPaints = <BattleState, TextPaint>{};
  final _telegraphPaint = TextPaint(
    style: const TextStyle(
      color: Color(0xFFFF4400),
      fontSize: 30,
      fontWeight: FontWeight.w900,
      shadows: [
        Shadow(color: Color(0xFF000000), blurRadius: 6, offset: Offset(1, 1)),
        Shadow(color: Color(0xFFFF2200), blurRadius: 10, offset: Offset(0, 0)),
      ],
    ),
  );

  @override
  int get currentHp => _currentHp;
  @override
  int get maxHp => _maxHp;
  @override
  int get def => tierStats.def;
  @override
  bool get isGuarding => _isBlocking;
  @override
  double get damageReduction => tierStats.damageReduction;
  @override
  int get shield => tierStats.shield;
  @override
  int get currentStamina => stamina.current;
  @override
  int get maxStamina => stamina.maxStamina;
  @override
  bool get isDead => _currentHp <= 0;
  @override
  double get hpRatio => _maxHp > 0 ? _currentHp / _maxHp : 0.0;

  bool get isBlocking => _isBlocking;

  EnemyComponent({required this.profile, required int tournamentTier})
      : tierStats = TierEnemyStats.forTier(tournamentTier),
        _maxHp = TierEnemyStats.forTier(tournamentTier).hp,
        _currentHp = TierEnemyStats.forTier(tournamentTier).hp,
        stamina = StaminaSystem(maxStamina: profile.staminaMax),
        activeSkill = profile.activeSkillEnabled ? ActiveSkillMeter() : null,
        hpNotifier = ValueNotifier(TierEnemyStats.forTier(tournamentTier).hp),
        super(
          size: Vector2(EnemyConstants.spriteW, EnemyConstants.spriteH),
          position: Vector2(EnemyConstants.startX, EnemyConstants.startY),
          anchor: Anchor.bottomCenter,
          priority: 10,
        );

  @override
  Future<void> onLoad() async {
    stamina.onExhausted = _onStaminaExhausted;

    try {
      final sprite = await Sprite.load(SpriteRepository.enemy);
      add(SpriteComponent(sprite: sprite, size: size, priority: 1)
        ..flipHorizontally());
    } catch (_) {
      add(RectangleComponent(
        size: size,
        paint: Paint()..color = const Color(0xFFD9344A),
        priority: 1,
      ));
    }

    add(_EnemyGroundShadow(parentWidth: size.x));

    _stateText = TextComponent(
      text: 'IDLE',
      textRenderer: _getLabelPaint(BattleState.idle),
      position: Vector2(size.x / 2, -6),
      anchor: Anchor.bottomCenter,
    );
    add(_stateText);

    _telegraphArrow = TextComponent(
      text: '',
      textRenderer: _telegraphPaint,
      position: Vector2(size.x / 2, -26),
      anchor: Anchor.bottomCenter,
      priority: 2,
    );
    add(_telegraphArrow);

    world.fsm.addListener(_onFsmChanged);
    _fsmListenerAdded = true;
    _stateText.text = _enemyLabel(world.fsm.current);
  }

  TextPaint _getLabelPaint(BattleState s) {
    return _labelPaints.putIfAbsent(s, () {
      return TextPaint(
        style: TextStyle(
          color: _enemyLabelColor(s),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          shadows: const [
            Shadow(
                color: Color(0xFF000000), blurRadius: 3, offset: Offset(1, 1)),
          ],
        ),
      );
    });
  }

  @override
  void update(double dt) {
    if (_telegraphActive) {
      _telegraphPulse += dt * 8.0;
      final s = 1.0 + 0.22 * math.sin(_telegraphPulse);
      _telegraphArrow.scale
        ..x = s
        ..y = s;
    }
  }

  void _onStaminaExhausted() {
    if (!isMounted) return;
    if (world.fsm.isBattleOver) return;
    world.onEnemyStaminaExhausted();
  }

  static String _enemyLabel(BattleState s) => switch (s) {
        BattleState.idle => 'IDLE',
        BattleState.enemyTelegraph => 'ATTACK!',
        BattleState.enemyHurt => 'HIT',
        BattleState.victory => 'WIN',
        BattleState.defeat => 'DEAD',
        BattleState.playerSlash => 'SLASH',
        BattleState.blockedRecoil => 'BLOCKED',
        BattleState.parrySuccess => 'PARRIED',
        BattleState.blockSuccess => 'BLOCKED',
        BattleState.dodgeSuccess => '',
        BattleState.dodgeFail => '',
        BattleState.enemyHit => '',
        BattleState.playerHurt => '',
        BattleState.activeSkill => '!!',
        BattleState.counterWindow => 'COUNTER',
      };

  static Color _enemyLabelColor(BattleState s) => switch (s) {
        BattleState.enemyTelegraph => const Color(0xFFFF3300),
        BattleState.enemyHurt => const Color(0xFFFF4444),
        BattleState.defeat => const Color(0xFF660000),
        BattleState.parrySuccess => const Color(0xFF00E5FF),
        BattleState.blockSuccess => const Color(0xFFFF8800),
        BattleState.blockedRecoil => const Color(0xFFFF8800),
        BattleState.activeSkill => const Color(0xFFFF2200),
        BattleState.dodgeFail => const Color(0xFFFF6655),
        BattleState.counterWindow => const Color(0xFF00E5FF),
        _ => const Color(0xFFFF6655),
      };

  void _onFsmChanged(BattleState prev, BattleState next) {
    _stateText.text = _enemyLabel(next);
    _stateText.textRenderer = _getLabelPaint(next);

    if (next == BattleState.enemyTelegraph) {
      final arrow = world.currentEnemyDirection.arrow;
      _telegraphArrow.text = arrow;
      _telegraphActive = true;
      _telegraphPulse = 0.0;
      _telegraphArrow.scale
        ..x = 1.0
        ..y = 1.0;
    } else if (prev == BattleState.enemyTelegraph) {
      _telegraphActive = false;
      _telegraphArrow.text = '';
      _telegraphArrow.scale
        ..x = 1.0
        ..y = 1.0;
    }
  }

  @override
  void takeDamage(int amount, DamageType type, {AttackDirection? direction}) {
    _currentHp = (_currentHp - amount).clamp(0, _maxHp);
    hpNotifier.value = _currentHp;
    activeSkill?.onHurt();
    if (isMounted && parent != null) {
      final worldPos = position - Vector2(0, size.y * 0.5);
      parent!.add(SlashEffect(
        worldPosition: worldPos,
        direction: direction ?? AttackDirection.n,
        isPlayerAttack: true,
        isFullDamage: type != DamageType.empty,
      ));
    }
  }

  @override
  void heal(int amount) {
    _currentHp = (_currentHp + amount).clamp(0, _maxHp);
    hpNotifier.value = _currentHp;
  }

  @override
  void restoreStamina(int amount) => stamina.restore(amount);
  @override
  void drainStamina(int amount) => stamina.drain(amount);

  @override
  void playAnimation(CombatAnimation anim) {
    if (kDebugMode) debugPrint('[Enemy] anim: $anim');
  }

  void startBlock() {
    _isBlocking = true;
    stamina.setBlocking(true);
  }

  void endBlock() {
    _isBlocking = false;
    stamina.setBlocking(false);
  }

  bool tryActivateSkill() {
    if (activeSkill == null || !activeSkill!.canActivate) return false;
    return activeSkill!.consume();
  }

  void reset() {
    _currentHp = _maxHp;
    _isBlocking = false;
    stamina.reset();
    activeSkill?.reset();
    _telegraphActive = false;
    _telegraphArrow.text = '';
    if (_fsmListenerAdded) {
      _stateText.text = _enemyLabel(BattleState.idle);
      _stateText.textRenderer = _getLabelPaint(BattleState.idle);
    }
  }

  @override
  void onRemove() {
    if (_fsmListenerAdded) world.fsm.removeListener(_onFsmChanged);
    stamina.dispose();
    activeSkill?.dispose();
    hpNotifier.dispose();
    _labelPaints.clear();
    super.onRemove();
  }
}

class _EnemyGroundShadow extends PositionComponent {
  final double parentWidth;
  late final Rect _shadowRect;

  _EnemyGroundShadow({required this.parentWidth}) : super(priority: -1) {
    _shadowRect = Rect.fromCenter(
      center: Offset(parentWidth / 2, 3),
      width: parentWidth * 1.1,
      height: 12,
    );
  }

  final Paint _shadowPaint = Paint()
    ..color = const Color(0x44000000)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

  @override
  void render(Canvas canvas) {
    canvas.drawOval(
      _shadowRect,
      _shadowPaint,
    );
  }
}
