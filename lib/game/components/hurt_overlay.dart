import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class HurtOverlay extends PositionComponent with HasGameReference {
  static const double _duration = 0.4;
  double _elapsed = 0.0;

  final Paint _borderPaint = Paint()..style = PaintingStyle.stroke;
  final Paint _overlayPaint = Paint();

  HurtOverlay() : super(priority: 200);

  @override
  void update(double dt) {
    _elapsed += dt;
    if (_elapsed >= _duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final size = game.size;
    final t = (_elapsed / _duration).clamp(0.0, 1.0);
    final alpha = (1.0 - t) * 0.6;
    
    _overlayPaint.shader = RadialGradient(
      colors: [
        Colors.red.withValues(alpha: 0.0),
        Colors.red.withValues(alpha: alpha * 0.5),
        Colors.red.withValues(alpha: alpha),
      ],
      stops: const [0.75, 0.92, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), _overlayPaint);
    
    _borderPaint
      ..color = Colors.red.withValues(alpha: alpha * 0.8)
      ..strokeWidth = 10 * (1.0 - t);
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), _borderPaint);
  }
}
