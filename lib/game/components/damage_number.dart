import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class DamageNumber extends PositionComponent {
  int amount = 0;
  bool isPlayerDamage = false;
  void Function(DamageNumber)? onRecycle;

  static const double _duration = 0.8;
  double _elapsed = 0.0;
  late Vector2 _velocity;
  late TextPaint _textPaint;

  static final TextPaint _playerDamageTextPaint = TextPaint(
    style: const TextStyle(
      color: Colors.redAccent,
      fontSize: 28,
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      fontFamily: 'Bangers',
      shadows: [
        Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2, 2)),
        Shadow(color: Colors.red, blurRadius: 10, offset: Offset(0, 0)),
      ],
    ),
  );

  static final TextPaint _enemyDamageTextPaint = TextPaint(
    style: const TextStyle(
      color: Colors.white,
      fontSize: 24,
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      fontFamily: 'Bangers',
      shadows: [
        Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2, 2)),
      ],
    ),
  );

  static final math.Random _rng = math.Random();

  DamageNumber() : super(priority: 100);

  void reinit({
    required int amount,
    required Vector2 position,
    required bool isPlayerDamage,
    required void Function(DamageNumber) onRecycle,
  }) {
    this.amount = amount;
    this.isPlayerDamage = isPlayerDamage;
    this.position.setFrom(position);
    this.onRecycle = onRecycle;
    _elapsed = 0.0;
    scale.setAll(1.0);

    _velocity = Vector2((_rng.nextDouble() - 0.5) * 60, -180);
    
    _textPaint = isPlayerDamage ? _playerDamageTextPaint : _enemyDamageTextPaint;
  }

  @override
  void update(double dt) {
    _elapsed += dt;
    if (_elapsed >= _duration) {
      removeFromParent();
      return;
    }


    position += _velocity * dt;

    _velocity.y += 450 * dt;


    if (_elapsed < 0.1) {
      scale.setAll(1.0 + (_elapsed / 0.1) * 0.5);
    } else if (_elapsed < 0.2) {
      scale.setAll(1.5 - ((_elapsed - 0.1) / 0.1) * 0.5);
    } else {
      scale.setAll(1.0);
    }
  }

  @override
  void render(Canvas canvas) {
    _textPaint.render(
      canvas,
      amount.toString(),
      Vector2.zero(),
      anchor: Anchor.center,
    );
  }

  @override
  void onRemove() {
    final recycleFn = onRecycle;
    if (recycleFn != null) {
      onRecycle = null;
      recycleFn(this);
    }
    super.onRemove();
  }
}
