import 'package:flame/components.dart';
import 'package:flutter/material.dart';



void spawnPerfectNotification(Component parent, Vector2 worldPosition) {
  parent.add(PerfectNotification(position: worldPosition));
}

class PerfectNotification extends PositionComponent {
  static const double _duration = 1.2;
  double _elapsed = 0.0;
  late final TextPaint _textPaint;

  PerfectNotification({required Vector2 position})
      : super(
          position: position,
          anchor: Anchor.center,
          priority: 150,
        );

  @override
  void update(double dt) {
    _elapsed += dt;
    if (_elapsed >= _duration) {
      removeFromParent();
      return;
    }


    position.y -= 40 * dt;
  }

  @override
  void render(Canvas canvas) {
    final t = (_elapsed / _duration).clamp(0.0, 1.0);


    final alpha = t < 0.2
        ? (t / 0.2).clamp(0.0, 1.0)
        : t > 0.8
            ? (1.0 - (t - 0.8) / 0.2).clamp(0.0, 1.0)
            : 1.0;

    final aInt = (alpha * 255).round().clamp(0, 255);


    final double s;
    if (t < 0.15) {
      s = 1.0 + (t / 0.15) * 0.6;
    } else if (t < 0.3) {
      s = 1.6 - ((t - 0.15) / 0.15) * 0.4;
    } else {
      s = 1.2;
    }

    canvas.save();
    canvas.scale(s, s);


    final glowPaint = Paint()
      ..color = const Color(0xFF00E5FF).withAlpha((aInt * 0.18).round().clamp(0, 255))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 180, height: 48),
      glowPaint,
    );


    _textPaint = TextPaint(
      style: TextStyle(
        fontFamily: 'Bangers',
        fontSize: 34,
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
        color: const Color(0xFF00E5FF).withAlpha(aInt),
        letterSpacing: 2,
        shadows: [
          Shadow(
            color: Colors.black.withAlpha(aInt),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
          Shadow(
            color: const Color(0xFF7C4DFF).withAlpha(aInt),
            blurRadius: 10,
            offset: const Offset(0, 0),
          ),
        ],
      ),
    );

    _textPaint.render(
      canvas,
      'PERFECT!',
      Vector2.zero(),
      anchor: Anchor.center,
    );

    canvas.restore();
  }
}
