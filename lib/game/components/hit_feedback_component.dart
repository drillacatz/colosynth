import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class HitFeedbackComponent extends PositionComponent {
  static const double _duration = 0.8;
  double _elapsed = 0.0;
  final String text;
  final Color textColor;
  final Color shadowColor;

  HitFeedbackComponent({
    required Vector2 position,
    required this.text,
    required this.textColor,
    required this.shadowColor,
  }) : super(
          position: position,
          anchor: Anchor.center,
          priority: 200,
        );

  @override
  void update(double dt) {
    _elapsed += dt;
    if (_elapsed >= _duration) {
      removeFromParent();
      return;
    }
    position.y -= 50 * dt;
  }

  @override
  void render(Canvas canvas) {
    final t = (_elapsed / _duration).clamp(0.0, 1.0);
    final alpha = t < 0.15
        ? (t / 0.15).clamp(0.0, 1.0)
        : t > 0.7
            ? (1.0 - (t - 0.7) / 0.3).clamp(0.0, 1.0)
            : 1.0;

    final aInt = (alpha * 255).round().clamp(0, 255);

    final double s;
    if (t < 0.1) {
      s = 0.8 + (t / 0.1) * 0.4;
    } else if (t < 0.2) {
      s = 1.2 - ((t - 0.1) / 0.1) * 0.2;
    } else {
      s = 1.0;
    }

    canvas.save();
    canvas.scale(s, s);

    final glowPaint = Paint()
      ..color = shadowColor.withAlpha((aInt * 0.15).round())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 140, height: 35),
      glowPaint,
    );

    final textPaint = TextPaint(
      style: TextStyle(
        fontFamily: 'Bangers',
        fontSize: 28,
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
        color: textColor.withAlpha(aInt),
        letterSpacing: 2,
        shadows: [
          Shadow(
            color: Colors.black.withAlpha((aInt * 0.85).round()),
            blurRadius: 4,
            offset: const Offset(1.5, 1.5),
          ),
          Shadow(
            color: shadowColor.withAlpha(aInt),
            blurRadius: 8,
            offset: Offset.zero,
          ),
        ],
      ),
    );

    textPaint.render(
      canvas,
      text,
      Vector2.zero(),
      anchor: Anchor.center,
    );

    canvas.restore();
  }
}
