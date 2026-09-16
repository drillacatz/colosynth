import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/services.dart';

import 'package:colosynth/game/logic/battle_state_machine.dart';

class BattleCamera extends Component with HasGameReference {
  final BattleStateMachine _fsm;
  final PositionComponent _player;
  final PositionComponent _enemy;

  static const double _shakeDecay = 8.0;
  static const double _shakeFreqX = 28.0;
  static const double _shakeFreqY = 19.88;
  static const double _shakeEpsilon = 0.05;

  static const double _zoomNormal = 1.00;
  static const double _zoomLerpIn = 8.0;
  static const double _zoomLerpOut = 3.5;
  static const double _zoomEpsilon = 0.001;

  static const double _followLerp = 4.0;
  static const double _boundMinX = 180.0;
  static const double _boundMaxX = 300.0;
  static const double _boundMinY = 340.0;
  static const double _boundMaxY = 700.0;

  double _shakeAmplitude = 0.0;
  double _shakePhase = 0.0;
  double _targetZoom = _zoomNormal;

  final Vector2 _followTarget = Vector2.zero();
  final Vector2 _smoothedCenter = Vector2.zero();
  final Vector2 _shakeOffset = Vector2.zero();
  final Vector2 _composedPosition = Vector2.zero();

  bool _initialized = false;

  BattleCamera({
    required BattleStateMachine fsm,
    required PositionComponent player,
    required PositionComponent enemy,
  })  : _fsm = fsm,
        _player = player,
        _enemy = enemy;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _fsm.addListener(_onStateChanged);

    _computeFollowTarget();
    _smoothedCenter.setFrom(_followTarget);

    final vf = game.camera.viewfinder;
    vf.anchor = Anchor.center;
    vf.position = Vector2.copy(_smoothedCenter);
    vf.zoom = _zoomNormal;

    _initialized = true;
  }

  @override
  void onRemove() {
    if (_initialized) {
      _fsm.removeListener(_onStateChanged);
    }
    super.onRemove();
  }

  @override
  void update(double dt) {
    if (!_initialized) return;

    _updateFollow(dt);
    _updateShake(dt);
    _updateZoom(dt);
    _flushToViewfinder();
  }

  void _computeFollowTarget() {
    final cx = (_player.position.x + _enemy.position.x) * 0.5;
    final cy = (_player.position.y + _enemy.position.y) * 0.5 - 60.0;
    _followTarget.x = cx.clamp(_boundMinX, _boundMaxX);
    _followTarget.y = cy.clamp(_boundMinY, _boundMaxY);
  }

  void _updateFollow(double dt) {
    _computeFollowTarget();
    final t = (_followLerp * dt).clamp(0.0, 1.0);
    _smoothedCenter.x += (_followTarget.x - _smoothedCenter.x) * t;
    _smoothedCenter.y += (_followTarget.y - _smoothedCenter.y) * t;
  }

  void _updateShake(double dt) {
    if (_shakeAmplitude <= _shakeEpsilon) {
      if (_shakeOffset.x != 0 || _shakeOffset.y != 0) {
        _shakeOffset.setZero();
      }
      _shakeAmplitude = 0;
      return;
    }

    _shakePhase += dt;
    _shakeAmplitude *= math.exp(-_shakeDecay * dt);
    if (_shakeAmplitude < _shakeEpsilon) {
      _shakeAmplitude = 0;
      _shakeOffset.setZero();
      return;
    }

    _shakeOffset.x = _shakeAmplitude * math.sin(_shakePhase * _shakeFreqX);
    _shakeOffset.y = _shakeAmplitude * math.cos(_shakePhase * _shakeFreqY);
  }

  void _updateZoom(double dt) {
    final vf = game.camera.viewfinder;
    final current = vf.zoom;
    final delta = _targetZoom - current;

    if (delta.abs() < _zoomEpsilon) {
      if (vf.zoom != _targetZoom) vf.zoom = _targetZoom;
      return;
    }

    final speed = delta > 0 ? _zoomLerpIn : _zoomLerpOut;
    vf.zoom += (delta * speed * dt).clamp(-0.05, 0.05);
  }

  void _flushToViewfinder() {
    _composedPosition.x = _smoothedCenter.x + _shakeOffset.x;
    _composedPosition.y = _smoothedCenter.y + _shakeOffset.y;
    game.camera.viewfinder.position = _composedPosition;
  }

  void _onStateChanged(BattleState prev, BattleState next) {
    switch (next) {
      case BattleState.playerHurt:
        shake(22.0);
        HapticFeedback.mediumImpact();
      case BattleState.enemyHit:
        shake(7.0);
      case BattleState.dodgeFail:
        shake(7.0);
      case BattleState.blockedRecoil:
        shake(8.0);
      case BattleState.enemyHurt:
        shake(5.0);
      case BattleState.parrySuccess:
        shake(10.0);
      case BattleState.blockSuccess:
        shake(3.5);
      case BattleState.dodgeSuccess:
        shake(2.0);
      case BattleState.activeSkill:
        shake(25.0);
      case BattleState.idle:
        _targetZoom = _zoomNormal;
      case BattleState.victory:
        _targetZoom = _zoomNormal;
      case BattleState.defeat:
        shake(32.0);
        HapticFeedback.heavyImpact();
        _targetZoom = _zoomNormal;
      default:
        break;
    }
  }

  void shake(double amplitude) {
    assert(amplitude >= 0, 'shake amplitude must be non-negative');
    if (amplitude > _shakeAmplitude) {
      _shakeAmplitude = amplitude;
    }
  }
}
