import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:colosynth/screens/theme/tokens.dart';

class NotebookBackground extends StatelessWidget {
  const NotebookBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      painter: _NotebookPainter(),
      size: Size.infinite,
    );
  }
}

class _NotebookPainter extends CustomPainter {
  const _NotebookPainter();

  static const _lineSpacing = 28.0;
  static const _marginX = 52.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = AppColors.paperWhite,
    );

    _paintWrinkle(canvas, size);
    _paintLines(canvas, size);
    _paintMargin(canvas, size);
  }

  void _paintWrinkle(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final paint = Paint()
      ..color = const Color(0xFF000000).withValues(alpha: 0.018)
      ..strokeWidth = 0.6
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 55; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final len = 18.0 + rng.nextDouble() * 55.0;
      final angle = (rng.nextDouble() - 0.5) * 0.4;
      canvas.drawLine(
        Offset(x, y),
        Offset(x + math.cos(angle) * len, y + math.sin(angle) * len),
        paint,
      );
    }

    final dotPaint = Paint()
      ..color = const Color(0xFF000000).withValues(alpha: 0.022);
    for (int i = 0; i < 30; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        rng.nextDouble() * 1.2 + 0.3,
        dotPaint,
      );
    }
  }

  void _paintLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.notebookLine.withValues(alpha: 0.60)
      ..strokeWidth = 0.9;

    double y = _lineSpacing;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      y += _lineSpacing;
    }
  }

  void _paintMargin(Canvas canvas, Size size) {
    canvas.drawLine(
      const Offset(_marginX, 0),
      Offset(_marginX, size.height),
      Paint()
        ..color = AppColors.notebookMargin
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(_NotebookPainter old) => true;
}
