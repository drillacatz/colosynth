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
  final int tournamentTier;
  final bool isBoss;

  EnemyComponent({
    required AiProfile profile,
    required int tournamentTier,
    bool isBoss = false,
    TierEnemyStats? stats,
  }) : this._internal(
          profile: profile,
          tournamentTier: tournamentTier,
          isBoss: isBoss,
          stats: stats ??
              TierEnemyStats.forStage(
                tier: tournamentTier,
                stageWithinTier: isBoss ? 12 : 1,
                isBoss: isBoss,
              ),
        );

  EnemyComponent._internal({
    required this.profile,
    required this.tournamentTier,
    required this.isBoss,
    required TierEnemyStats stats,
  })  : tierStats = stats,
        _maxHp = stats.hp,
        _currentHp = stats.hp,
        stamina = StaminaSystem(maxStamina: stats.stamina > 0 ? stats.stamina : profile.staminaMax),
        activeSkill = profile.activeSkillEnabled ? ActiveSkillMeter() : null,
        hpNotifier = ValueNotifier(stats.hp),
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
      final spritePath = isBoss
          ? SpriteRepository.bossSpriteForTier(tournamentTier)
          : SpriteRepository.enemy;
      final sprite = await Sprite.load(spritePath);
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
    add(_GuardShieldAura(enemy: this, parentSize: size));

    _stateText = TextComponent(
      text: 'IDLE',
      textRenderer: _getLabelPaintForColor(_currentLabelColor(BattleState.idle)),
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
    _refreshStateLabel();
  }

  final _colorPaints = <Color, TextPaint>{};

  TextPaint _getLabelPaintForColor(Color c) {
    return _colorPaints.putIfAbsent(c, () {
      return TextPaint(
        style: TextStyle(
          color: c,
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

  String _currentLabel(BattleState s) {
    if (_isBlocking && s != BattleState.counterWindow && s != BattleState.defeat) {
      return 'GUARD';
    }
    return _enemyLabel(s);
  }

  Color _currentLabelColor(BattleState s) {
    if (_isBlocking && s != BattleState.counterWindow && s != BattleState.defeat) {
      return const Color(0xFF00E5FF);
    }
    return _enemyLabelColor(s);
  }

  void _refreshStateLabel() {
    if (!isMounted || !_fsmListenerAdded) return;
    final state = world.fsm.current;
    _stateText.text = _currentLabel(state);
    _stateText.textRenderer = _getLabelPaintForColor(_currentLabelColor(state));
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
    _refreshStateLabel();

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
    _refreshStateLabel();
  }

  void endBlock() {
    _isBlocking = false;
    stamina.setBlocking(false);
    _refreshStateLabel();
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
    if (_fsmListenerAdded) {
      _telegraphArrow.text = '';
      _refreshStateLabel();
    }
  }

  @override
  void onRemove() {
    if (_fsmListenerAdded) world.fsm.removeListener(_onFsmChanged);
    stamina.dispose();
    activeSkill?.dispose();
    hpNotifier.dispose();
    _colorPaints.clear();
    super.onRemove();
  }
}

class _GuardShieldAura extends PositionComponent {
  final EnemyComponent enemy;
  double _auraTimer = 0.0;

  _GuardShieldAura({required this.enemy, required Vector2 parentSize})
      : super(
          size: Vector2(parentSize.x * 1.15, parentSize.y * 1.05),
          position: Vector2(-parentSize.x * 0.075, -parentSize.y * 0.025),
          priority: 5,
        );

  final Paint _fillPaint = Paint()
    ..color = const Color(0x3300E5FF)
    ..style = PaintingStyle.fill;

  final Paint _strokePaint = Paint()
    ..color = const Color(0xFF00E5FF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.0;

  final Paint _glowPaint = Paint()
    ..color = const Color(0x8800E5FF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6.0
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

  final Paint _linePaint = Paint()
    ..color = const Color(0x6600E5FF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  @override
  void update(double dt) {
    super.update(dt);
    if (enemy.isBlocking) {
      _auraTimer += dt * 4.0;
    }
  }

  @override
  void render(Canvas canvas) {
    if (!enemy.isBlocking) return;

    final pulse = 0.96 + 0.04 * math.sin(_auraTimer);
    final w = size.x;
    final h = size.y;
    final cx = w / 2;
    final cy = h / 2;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(pulse, pulse);
    canvas.translate(-cx, -cy);

    final path = Path();
    path.moveTo(w * 0.15, 0);
    path.lineTo(w * 0.85, 0);
    path.lineTo(w, h * 0.35);
    path.lineTo(w * 0.85, h * 0.85);
    path.lineTo(cx, h);
    path.lineTo(w * 0.15, h * 0.85);
    path.lineTo(0, h * 0.35);
    path.close();

    canvas.drawPath(path, _glowPaint);
    canvas.drawPath(path, _fillPaint);
    canvas.drawPath(path, _strokePaint);

    for (double y = h * 0.2; y <= h * 0.8; y += 18.0) {
      final lineW = (1.0 - ((y - cy).abs() / cy)) * (w * 0.7);
      canvas.drawLine(
        Offset(cx - lineW / 2, y),
        Offset(cx + lineW / 2, y),
        _linePaint,
      );
    }

    canvas.restore();
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
