import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:colosynth/game_data/level_data.dart';

class TournamentArenaCardPainter extends CustomPainter {
  TournamentArenaCardPainter({
    required this.style,
    required this.locked,
    required this.allDone,
  }) {
    final rng42 = math.Random(42);
    _notebookDots = List.generate(
      30,
      (_) => Offset(rng42.nextDouble(), rng42.nextDouble()),
    );

    final rng99 = math.Random(99);
    _darkDots = List.generate(
      40,
      (_) => Offset(rng99.nextDouble(), rng99.nextDouble()),
    );
    _darkStreaks = List.generate(
      6,
      (_) => (
        y: rng99.nextDouble(),
        x0: rng99.nextDouble(),
        x1: rng99.nextDouble(),
      ),
    );
  }

  final ArenaStyle style;
  final bool locked;
  final bool allDone;

  late final List<Offset> _notebookDots;
  late final List<Offset> _darkDots;
  late final List<({double y, double x0, double x1})> _darkStreaks;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(16));

    final shadowRRect = RRect.fromRectAndRadius(
        rect.translate(4, 5), const Radius.circular(16));
    canvas.drawRRect(shadowRRect, Paint()..color = const Color(0xFFD0C8C0));

    if (locked) {
      canvas.drawRRect(rrect, Paint()..color = const Color(0xFFEEEEEE));
    } else {
      switch (style) {
        case ArenaStyle.notebook:
          _paintNotebook(canvas, rect, rrect);
        case ArenaStyle.comicBurst:
          _paintComicBurst(canvas, rect, rrect);
        case ArenaStyle.darkComic:
          _paintDarkComic(canvas, rect, rrect);
      }
    }

    const inkColor = Color(0xFF1A1A1A);
    final borderColor = locked
        ? inkColor.withValues(alpha: 0.15)
        : allDone
            ? const Color(0xFF4CAF50).withValues(alpha: 0.6)
            : inkColor.withValues(alpha: 0.65);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = locked ? 1.5 : 2.5,
    );
  }

  void _paintNotebook(Canvas canvas, Rect rect, RRect rrect) {
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFFFDFDFB));
    canvas.save();
    canvas.clipRRect(rrect);
    final linePaint = Paint()
      ..color = const Color(0xFFB8D4F0).withValues(alpha: 0.45)
      ..strokeWidth = 0.8;
    double y = 28.0;
    while (y < rect.height) {
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), linePaint);
      y += 24.0;
    }
    canvas.drawLine(
      Offset(rect.left + 36, rect.top),
      Offset(rect.left + 36, rect.bottom),
      Paint()
        ..color = const Color(0xFFFFB3BA).withValues(alpha: 0.35)
        ..strokeWidth = 1.0,
    );
    final dotPaint = Paint()
      ..color = const Color(0xFF000000).withValues(alpha: 0.015);
    for (final pt in _notebookDots) {
      canvas.drawCircle(
        Offset(rect.left + pt.dx * rect.width, rect.top + pt.dy * rect.height),
        pt.dx * 1.5 + 0.3,
        dotPaint,
      );
    }
    canvas.restore();
  }

  void _paintComicBurst(Canvas canvas, Rect rect, RRect rrect) {
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFFFFF5E0));
    canvas.save();
    canvas.clipRRect(rrect);
    final dotPaint = Paint()
      ..color = const Color(0xFF000000).withValues(alpha: 0.06);
    const spacing = 12.0;
    for (double x = rect.left; x < rect.right; x += spacing) {
      for (double y = rect.top; y < rect.bottom; y += spacing) {
        canvas.drawCircle(Offset(x, y), 2.0, dotPaint);
      }
    }
    final center = Offset(rect.center.dx, rect.center.dy - 20);
    final linePaint = Paint()
      ..color = const Color(0xFF000000).withValues(alpha: 0.04)
      ..strokeWidth = 1.0;
    for (int i = 0; i < 16; i++) {
      final angle = (i / 16) * math.pi * 2;
      final len = rect.width * 0.7;
      canvas.drawLine(
        center,
        Offset(center.dx + math.cos(angle) * len,
            center.dy + math.sin(angle) * len),
        linePaint,
      );
    }
    canvas.restore();
  }

  void _paintDarkComic(Canvas canvas, Rect rect, RRect rrect) {
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF1A1416));
    canvas.save();
    canvas.clipRRect(rrect);
    final vignetteGradient = RadialGradient(
      center: const Alignment(0, -0.3),
      radius: 0.9,
      colors: [
        const Color(0xFF2D1A22).withValues(alpha: 0.6),
        const Color(0xFF0A0406),
      ],
    );
    canvas.drawRect(
        rect, Paint()..shader = vignetteGradient.createShader(rect));
    final splatPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.02);
    for (final pt in _darkDots) {
      canvas.drawCircle(
        Offset(rect.left + pt.dx * rect.width, rect.top + pt.dy * rect.height),
        pt.dx * 2.0 + 0.4,
        splatPaint,
      );
    }
    final streakPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.015)
      ..strokeWidth = 0.6;
    for (final s in _darkStreaks) {
      final sy = rect.top + s.y * rect.height;
      final sx0 = rect.left + s.x0 * rect.width * 0.3;
      final sx1 = rect.right - s.x1 * rect.width * 0.3;
      canvas.drawLine(Offset(sx0, sy), Offset(sx1, sy), streakPaint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(TournamentArenaCardPainter old) =>
      old.style != style || old.locked != locked || old.allDone != allDone;
}
