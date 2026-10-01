import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:colosynth/database/character/battle_stats.dart';
import 'package:colosynth/game/app_shell/battle_models.dart';
import 'package:colosynth/game_data/battle_anim.dart';
import 'package:colosynth/game/logic/battle_constants.dart';
import 'package:colosynth/game/logic/battle_state_machine.dart';
import 'package:colosynth/game/components/slash_effect.dart';
import 'package:colosynth/game/components/parry_particle.dart';
import 'package:colosynth/game/logic/direction.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:colosynth/services/sprite_repository.dart';
import 'package:colosynth/services/audio_service.dart';
import 'package:colosynth/game_settings.dart' show SfxEvent;

class PlayerComponent extends PositionComponent
    with HasGameReference<BattleWorld>
    implements Combatant {

  BattleWorld get world => game;
  final BattleStats playerStats;
  final String characterId;

  int _currentHp;
  final int _maxHp;
  bool _isBlocking = false;
  bool _isDodging = false;

  bool? _dodgeIsLeft;
  double _originalX = 0.0;
  double _dodgeTimer = 0;

  static const double _dodgeDistance = PlayerConstants.dodgeDistance;
  static const double _dodgeDuration = PlayerConstants.dodgeDuration;

  final ValueNotifier<int> hpNotifier;

  late final TextComponent _stateText;
  bool _fsmListenerAdded = false;

  late final PlayerShieldBarrierComponent _shieldBarrier;
  late final StateAnimationController _animCtrl;

  final _labelPaints = <BattleState, TextPaint>{};

  @override
  int get currentHp => _currentHp;
  @override
  int get maxHp => _maxHp;
  @override
  int get def => playerStats.def;
  @override
  bool get isGuarding => _isBlocking;
  @override
  double get damageReduction => playerStats.damageReduction;
  @override
  int get shield => playerStats.shield;
  @override
  int get currentStamina => world.stamina.current;
  @override
  int get maxStamina => world.stamina.maxStamina;
  @override
  bool get isDead => _currentHp <= 0;
  @override
  double get hpRatio => _maxHp > 0 ? _currentHp / _maxHp : 0.0;

  bool get isBlocking => _isBlocking;
  bool get isDodging => _isDodging;
  bool? get dodgeIsLeft => _dodgeIsLeft;
  bool get hasDodgeWindow => _dodgeTimer > 0;

  PlayerComponent({required this.playerStats, this.characterId = 'arthur'})
      : _maxHp = playerStats.hp,
        _currentHp = playerStats.hp,
        hpNotifier = ValueNotifier(playerStats.hp),
        super(
          size: Vector2(PlayerConstants.spriteW, PlayerConstants.spriteH),
          position: Vector2(PlayerConstants.startX, PlayerConstants.startY),
          anchor: Anchor.bottomCenter,
          priority: 10,
        ) {
    _animCtrl = StateAnimationController(characterId: characterId);
  }

  @override
  Future<void> onLoad() async {
    final animComponent = await _animCtrl.load(size);
    if (_animCtrl.hasAnimations) {
      add(animComponent);
    } else {
      try {
        final sprite = await Sprite.load(SpriteRepository.characterSprite(characterId));
        add(SpriteComponent(sprite: sprite, size: size, priority: 1));
      } catch (_) {
        try {
          final defaultSprite = await Sprite.load(SpriteRepository.player);
          add(SpriteComponent(sprite: defaultSprite, size: size, priority: 1));
        } catch (_) {
          add(RectangleComponent(
            size: size,
            paint: Paint()..color = const Color(0xFF4A90D9),
            priority: 1,
          ));
        }
      }
    }

    add(_GroundShadow(parentWidth: size.x));

    _stateText = TextComponent(
      text: 'IDLE',
      textRenderer: _getLabelPaint(BattleState.idle),
      position: Vector2(size.x / 2, -10),
      anchor: Anchor.bottomCenter,
    );
    add(_stateText);

    _shieldBarrier = PlayerShieldBarrierComponent(parentSize: size);


    world.fsm.addListener(_onFsmChanged);
    _fsmListenerAdded = true;
    _stateText.text = _playerLabel(world.fsm.current);
  }

  TextPaint _getLabelPaint(BattleState s) {
    return _labelPaints.putIfAbsent(s, () {
      return TextPaint(
        style: TextStyle(
          color: _playerLabelColor(s),
          fontSize: 14,
          fontWeight: FontWeight.w900,
          shadows: const [
            Shadow(
                color: Color(0xFF000000), blurRadius: 4, offset: Offset(1, 1)),
          ],
        ),
      );
    });
  }

  @override
  void update(double dt) {
    _updateDodgeWindow(dt);
    if (_isBlocking && world.stamina.isExhausted) {
      _breakShield();
    }
  }

  void _updateDodgeWindow(double dt) {
    if (_dodgeTimer <= 0) return;
    _dodgeTimer -= dt;
    if (_dodgeTimer <= 0) {
      _dodgeTimer = 0;
      _isDodging = false;
      position.x = _originalX;
      _dodgeIsLeft = null;
    }
  }

  String _playerLabel(BattleState s) {
    if (_isBlocking && s != BattleState.counterWindow && s != BattleState.defeat) {
      return 'GUARD';
    }
    return switch (s) {
      BattleState.idle => 'IDLE',
      BattleState.playerSlash => 'SLASH',
      BattleState.blockedRecoil => 'BLOCKED',
      BattleState.parrySuccess => 'PARRY!',
      BattleState.blockSuccess => 'BLOCK',
      BattleState.dodgeSuccess => 'DODGE',
      BattleState.dodgeFail => 'MISS!',
      BattleState.activeSkill => 'SKILL!!',
      BattleState.playerHurt => 'HIT',
      BattleState.enemyHit => 'READY',
      BattleState.enemyTelegraph => 'READY',
      BattleState.enemyHurt => 'READY',
      BattleState.victory => 'WIN',
      BattleState.defeat => 'DEAD',
      BattleState.counterWindow => 'COUNTER!',
    };
  }

  Color _playerLabelColor(BattleState s) {
    if (_isBlocking && s != BattleState.counterWindow && s != BattleState.defeat) {
      return const Color(0xFF00E5FF);
    }
    return switch (s) {
      BattleState.parrySuccess => const Color(0xFF00E5FF),
      BattleState.activeSkill => const Color(0xFFFFAA00),
      BattleState.playerHurt => const Color(0xFFFF4444),
      BattleState.dodgeFail => const Color(0xFFFF4444),
      BattleState.defeat => const Color(0xFF880000),
      BattleState.blockedRecoil => const Color(0xFFFF8800),
      BattleState.victory => const Color(0xFF00E5FF),
      _ => const Color(0xFF4AB8FF),
    };
  }

  void _onFsmChanged(BattleState prev, BattleState next) {
    _refreshStateLabel();

    switch (next) {
      case BattleState.playerSlash:
        playAnimation(CombatAnimation.attack);
      case BattleState.playerHurt:
      case BattleState.blockedRecoil:
        playAnimation(CombatAnimation.hurt);
      case BattleState.idle:
        playAnimation(CombatAnimation.idle);
      case BattleState.parrySuccess:
        playAnimation(CombatAnimation.parry);
      case BattleState.dodgeSuccess:
        playAnimation(CombatAnimation.dodge);
      case BattleState.activeSkill:
        playAnimation(CombatAnimation.activeSkill);
      default:
        break;
    }

    if (next == BattleState.enemyHit ||
        next == BattleState.playerHurt ||
        next == BattleState.blockedRecoil) {
      if (_isBlocking) {
        _breakShield();
      } else {
        _removeShieldBarrier();
      }
    }
  }

  @override
  void takeDamage(int amount, DamageType type, {AttackDirection? direction}) {
    _currentHp = (_currentHp - amount).clamp(0, _maxHp);
    hpNotifier.value = _currentHp;
    if (!isDead) world.activeSkill.onHurt();
    if (isMounted && parent != null) {
      final worldPos = position - Vector2(0, size.y * 0.6);
      parent!.add(SlashEffect(
        worldPosition: worldPos,
        direction: direction ?? AttackDirection.n,
        isPlayerAttack: false,
        isFullDamage: true,
      ));
    }
  }

  @override
  void heal(int amount) {
    _currentHp = (_currentHp + amount).clamp(0, _maxHp);
    hpNotifier.value = _currentHp;
  }

  @override
  void restoreStamina(int amount) => world.stamina.restore(amount);

  @override
  void drainStamina(int amount) => world.stamina.drain(amount);

  @override
  void playAnimation(CombatAnimation anim) => _animCtrl.play(anim);

  void startBlock() {
    if (isDead || world.stamina.isExhausted) return;
    _isBlocking = true;
    world.stamina.setBlocking(true);
    _addShieldBarrier();
    _refreshStateLabel();
  }

  void endBlock() {
    _isBlocking = false;
    world.stamina.setBlocking(false);
    _removeShieldBarrier();
    _refreshStateLabel();
  }

  void _addShieldBarrier() {
    if (!_shieldBarrier.isMounted) {
      add(_shieldBarrier);
    }
  }

  void _removeShieldBarrier() {
    if (_shieldBarrier.isMounted) {
      _shieldBarrier.removeFromParent();
    }
  }

  void _breakShield() {
    if (!_isBlocking) return;
    _removeShieldBarrier();
    _isBlocking = false;
    world.stamina.setBlocking(false);
    AudioService.instance.playSfx(SfxEvent.parry);
    if (isMounted && parent != null) {
      spawnParryParticles(parent!, position - Vector2(0, size.y * 0.4));
    }
    _refreshStateLabel();
  }

  void _refreshStateLabel() {
    if (!_fsmListenerAdded) return;
    final s = world.fsm.current;
    _stateText.text = _playerLabel(s);
    _stateText.textRenderer = _getLabelPaint(s);
  }

  void startDodge() {
    _isDodging = true;
  }

  void setDodgeDirection({required bool isLeft}) {
    _isDodging = true;
    _dodgeIsLeft = isLeft;
    _originalX = position.x;
    _dodgeTimer = _dodgeDuration;
    position.x += isLeft ? -_dodgeDistance : _dodgeDistance;
  }

  void revive() {
    _currentHp = _maxHp;
    _isBlocking = false;
    _isDodging = false;
    _dodgeIsLeft = null;
    _dodgeTimer = 0;
    _removeShieldBarrier();
    hpNotifier.value = _currentHp;
    if (_fsmListenerAdded) {
      _stateText.text = _playerLabel(BattleState.idle);
      _stateText.textRenderer = _getLabelPaint(BattleState.idle);
    }
  }

  void reset() {
    _currentHp = _maxHp;
    _isBlocking = false;
    _isDodging = false;
    _dodgeIsLeft = null;
    _originalX = PlayerConstants.startX;
    _dodgeTimer = 0;
    position.x = PlayerConstants.startX;
    _removeShieldBarrier();
    hpNotifier.value = _currentHp;
    _animCtrl.play(CombatAnimation.idle);
    if (_fsmListenerAdded) {
      _stateText.text = _playerLabel(BattleState.idle);
      _stateText.textRenderer = _getLabelPaint(BattleState.idle);
    }
  }

  @override
  void onRemove() {
    if (_fsmListenerAdded) world.fsm.removeListener(_onFsmChanged);
    hpNotifier.dispose();
    _animCtrl.dispose();
    _labelPaints.clear();
    super.onRemove();
  }
}

class _GroundShadow extends PositionComponent {
  final double parentWidth;
  late final Rect _shadowRect;

  _GroundShadow({required this.parentWidth}) : super(priority: -1) {
    _shadowRect = Rect.fromCenter(
      center: Offset(parentWidth / 2, 4),
      width: parentWidth * 1.1,
      height: 22,
    );
  }

  final Paint _shadowPaint = Paint()
    ..color = const Color(0x66000000)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

  @override
  void render(Canvas canvas) {
    canvas.drawOval(
      _shadowRect,
      _shadowPaint,
    );
  }
}

class PlayerShieldBarrierComponent extends PositionComponent
    with HasGameReference<BattleWorld> {
  PlayerShieldBarrierComponent({
    required Vector2 parentSize,
  }) : super(
          size: Vector2(parentSize.x * 1.5, parentSize.y * 0.95),
          position: Vector2(parentSize.x / 2, parentSize.y * 0.42),
          anchor: Anchor.center,
          priority: 25,
        );

  double _timer = 0.0;
  SpriteAnimationComponent? _vfxAnim;

  final Paint _fillPaint = Paint()
    ..color = const Color(0x3300E5FF)
    ..style = PaintingStyle.fill;

  final Paint _strokePaint = Paint()
    ..color = const Color(0xFF00E5FF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.0;

  final Paint _glowPaint = Paint()
    ..color = const Color(0x6600E5FF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 8.0
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

  final Paint _gridPaint = Paint()
    ..color = const Color(0x44FFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    try {
      final image = await Flame.images.load(SpriteRepository.blockEffect);
      _vfxAnim = SpriteAnimationComponent(
        animation: SpriteAnimation.fromFrameData(
          image,
          SpriteAnimationData.sequenced(
            amount: 16,
            amountPerRow: 4,
            stepTime: 0.04,
            textureSize: Vector2(128, 128),
            loop: true,
          ),
        ),
        size: Vector2.all(size.x * 0.95),
        position: Vector2(size.x / 2, size.y / 2),
        anchor: Anchor.center,
        priority: 1,
      );
      add(_vfxAnim!);
    } catch (_) {}
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt * 4.5;
  }

  @override
  void render(Canvas canvas) {
    final pulse = 0.97 + 0.03 * math.sin(_timer);
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

    for (double y = h * 0.15; y <= h * 0.85; y += 16.0) {
      final lineW = (1.0 - ((y - cy).abs() / cy)) * (w * 0.75);
      if (lineW > 0) {
        canvas.drawLine(
          Offset(cx - lineW / 2, y),
          Offset(cx + lineW / 2, y),
          _gridPaint,
        );
      }
    }

    canvas.restore();
    super.render(canvas);
  }
}
