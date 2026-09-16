import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:colosynth/game_data/level_data.dart';
import 'package:colosynth/screens/theme/tokens.dart';

class CrinkledBoxPainter extends CustomPainter {
  CrinkledBoxPainter({
    required this.faceColor,
    required this.shadowColor,
    required this.borderColor,
    this.borderWidth = 2.0,
    this.cornerRadius = 6.0,
    this.jitterAmount = 1.8,
    this.segments = 5,
    this.shadowOffset = const Offset(3, 3),
    this.seed = 42,
    this.showTexture = false,
  });

  final Color faceColor;
  final Color shadowColor;
  final Color borderColor;
  final double borderWidth;
  final double cornerRadius;
  final double jitterAmount;
  final int segments;
  final Offset shadowOffset;
  final int seed;
  final bool showTexture;



  final Paint _shadowPaint = Paint();
  final Paint _facePaint = Paint();
  final Paint _borderPaint = Paint();

  Size? _cachedSize;
  Path? _cachedFacePath;






  Path buildPath(Rect rect, [math.Random? rng]) {
    final r = rng ?? math.Random(seed);

    Offset jitter(Offset p) =>
        p +
        Offset(
          (r.nextDouble() - 0.5) * jitterAmount,
          (r.nextDouble() - 0.5) * jitterAmount,
        );

    final cr = cornerRadius;
    final c = [
      Offset(rect.left + cr, rect.top),
      Offset(rect.right - cr, rect.top),
      Offset(rect.right, rect.top + cr),
      Offset(rect.right, rect.bottom - cr),
      Offset(rect.right - cr, rect.bottom),
      Offset(rect.left + cr, rect.bottom),
      Offset(rect.left, rect.bottom - cr),
      Offset(rect.left, rect.top + cr),
    ];
    final path = Path()..moveTo(c[0].dx, c[0].dy);

    void wobbly(Offset from, Offset to) {
      for (int i = 1; i <= segments; i++) {
        final p = jitter(Offset.lerp(from, to, i / segments)!);
        path.lineTo(p.dx, p.dy);
      }
    }

    wobbly(c[0], c[1]);
    path.quadraticBezierTo(jitter(Offset(rect.right, rect.top)).dx,
        jitter(Offset(rect.right, rect.top)).dy, c[2].dx, c[2].dy);
    wobbly(c[2], c[3]);
    path.quadraticBezierTo(jitter(Offset(rect.right, rect.bottom)).dx,
        jitter(Offset(rect.right, rect.bottom)).dy, c[4].dx, c[4].dy);
    wobbly(c[4], c[5]);
    path.quadraticBezierTo(jitter(Offset(rect.left, rect.bottom)).dx,
        jitter(Offset(rect.left, rect.bottom)).dy, c[6].dx, c[6].dy);
    wobbly(c[6], c[7]);
    path.quadraticBezierTo(jitter(Offset(rect.left, rect.top)).dx,
        jitter(Offset(rect.left, rect.top)).dy, c[0].dx, c[0].dy);
    path.close();
    return path;
  }


  Path _facePath(Size size) {
    if (_cachedSize != size || _cachedFacePath == null) {
      _cachedSize = size;
      _cachedFacePath = buildPath(
        Rect.fromLTWH(0, 0, size.width, size.height),
        math.Random(seed),
      );
    }
    return _cachedFacePath!;
  }

  void _paintTexture(Canvas canvas, Rect rect) {
    final rng = math.Random(seed ^ 0xABCD);
    final lp = Paint()
      ..color = const Color(0xFF000000).withValues(alpha: 0.04)
      ..strokeWidth = 0.6
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 5; i++) {
      final y = rect.top + rng.nextDouble() * rect.height;
      canvas.drawLine(
        Offset(rect.left + rng.nextDouble() * rect.width * 0.25,
            y + (rng.nextDouble() - 0.5) * 3),
        Offset(rect.right - rng.nextDouble() * rect.width * 0.25,
            y + (rng.nextDouble() - 0.5) * 3),
        lp,
      );
    }
    final dp = Paint()..color = const Color(0xFF000000).withValues(alpha: 0.05);
    for (int i = 0; i < 4; i++) {
      canvas.drawCircle(
        Offset(rect.left + rng.nextDouble() * rect.width,
            rect.top + rng.nextDouble() * rect.height),
        rng.nextDouble() * 1.2 + 0.4,
        dp,
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final face = _facePath(size);

    if (shadowColor.a > 0 && shadowOffset != Offset.zero) {
      _shadowPaint.color = shadowColor;
      canvas.drawPath(face.shift(shadowOffset), _shadowPaint);
    }

    _facePaint.color = faceColor;
    canvas.drawPath(face, _facePaint);
    if (showTexture) _paintTexture(canvas, rect);
    _borderPaint
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(face, _borderPaint);
  }

  @override
  bool shouldRepaint(CrinkledBoxPainter old) =>
      old.seed != seed ||
      old.faceColor != faceColor ||
      old.shadowColor != shadowColor ||
      old.borderColor != borderColor ||
      old.borderWidth != borderWidth ||
      old.shadowOffset != shadowOffset ||
      old.cornerRadius != cornerRadius ||
      old.jitterAmount != jitterAmount ||
      old.showTexture != showTexture;
}

class BurstBackgroundPainter extends CustomPainter {
  const BurstBackgroundPainter({
    required this.color,
    this.alpha = 0.20,
    this.innerRatio = 0.82,
    this.spikes = 32,
  });

  final Color color;
  final double alpha;
  final double innerRatio;
  final int spikes;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final path = Path();
    for (int i = 0; i < spikes; i++) {
      final angle = (math.pi * 2 * i) / spikes - math.pi / 2;
      final r = (i % 2 == 0) ? 1.0 : innerRatio;
      final x = cx + (size.width / 2) * r * math.cos(angle);
      final y = cy + (size.height / 2) * r * math.sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: alpha));
  }

  @override
  bool shouldRepaint(BurstBackgroundPainter old) =>
      old.color != color || old.alpha != alpha || old.spikes != spikes;
}

class StarBurstPainter extends CustomPainter {
  const StarBurstPainter(
      {required this.color, this.spikes = 16, this.innerRatio = 0.86});
  final Color color;
  final int spikes;
  final double innerRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final path = Path();
    for (int i = 0; i < spikes * 2; i++) {
      final angle = (math.pi * 2 * i) / (spikes * 2) - math.pi / 2;
      final r = i.isEven ? 1.0 : innerRatio;
      final x = cx + (size.width / 2) * r * math.cos(angle);
      final y = cy + (size.height / 2) * r * math.sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.16));
  }

  @override
  bool shouldRepaint(StarBurstPainter old) => old.color != color;
}

class BurstPainter extends CustomPainter {
  const BurstPainter({
    required this.color,
    this.alpha = 0.18,
    this.spikes = 32,
    this.innerRatio = 0.82,
  });

  final Color color;
  final double alpha;
  final int spikes;
  final double innerRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final path = Path();
    for (int i = 0; i < spikes; i++) {
      final angle = (math.pi * 2 * i) / spikes - math.pi / 2;
      final r = (i % 2 == 0) ? 1.0 : innerRatio;
      final x = cx + (size.width / 2) * r * math.cos(angle);
      final y = cy + (size.height / 2) * r * math.sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: alpha));
  }

  @override
  bool shouldRepaint(BurstPainter old) =>
      old.color != color || old.alpha != alpha || old.spikes != spikes;
}

class NotebookCardPainter extends CustomPainter {
  NotebookCardPainter({
    required this.seed,
    this.faceColor = const Color(0xFFFDFDFB),
    this.shadowColor = const Color(0xFFD0C8C0),
    this.borderColor = const Color(0xFF1A1A1A),
    this.borderOpacity = 1.0,
    this.shadowOffset = const Offset(3, 3),
    this.showShadow = true,
    this.showTexture = false,
    this.jitter = 1.8,
    this.borderWidth = 2.0,
    this.cornerRadius = 6.0,
    this.segments = 5,
  }) : _rng = math.Random(seed);

  final int seed;
  final Color faceColor;
  final Color shadowColor;
  final Color borderColor;
  final double borderOpacity;
  final Offset shadowOffset;
  final bool showShadow;
  final bool showTexture;
  final double jitter;
  final double borderWidth;
  final double cornerRadius;
  final int segments;
  final math.Random _rng;

  Size? _cachedSize;
  Path? _cachedFacePath;
  Path? _cachedShadowPath;

  Path _facePath(Size size) {
    if (_cachedSize != size || _cachedFacePath == null) {
      _cachedSize = size;
      _cachedFacePath = _buildPath(Rect.fromLTWH(0, 0, size.width, size.height));
      if (showShadow) {
        _cachedShadowPath = _buildPath(Rect.fromLTWH(shadowOffset.dx, shadowOffset.dy, size.width, size.height));
      }
    }
    return _cachedFacePath!;
  }

  Offset _j(Offset p) =>
      p +
      Offset(
        (_rng.nextDouble() - 0.5) * jitter,
        (_rng.nextDouble() - 0.5) * jitter,
      );

  Path _buildPath(Rect rect) {
    final r = cornerRadius;
    final c = [
      Offset(rect.left + r, rect.top),
      Offset(rect.right - r, rect.top),
      Offset(rect.right, rect.top + r),
      Offset(rect.right, rect.bottom - r),
      Offset(rect.right - r, rect.bottom),
      Offset(rect.left + r, rect.bottom),
      Offset(rect.left, rect.bottom - r),
      Offset(rect.left, rect.top + r),
    ];
    final path = Path()..moveTo(c[0].dx, c[0].dy);
    void wobbly(Offset from, Offset to) {
      for (int i = 1; i <= segments; i++) {
        final p = _j(Offset.lerp(from, to, i / segments)!);
        path.lineTo(p.dx, p.dy);
      }
    }

    wobbly(c[0], c[1]);
    path.quadraticBezierTo(_j(Offset(rect.right, rect.top)).dx,
        _j(Offset(rect.right, rect.top)).dy, c[2].dx, c[2].dy);
    wobbly(c[2], c[3]);
    path.quadraticBezierTo(_j(Offset(rect.right, rect.bottom)).dx,
        _j(Offset(rect.right, rect.bottom)).dy, c[4].dx, c[4].dy);
    wobbly(c[4], c[5]);
    path.quadraticBezierTo(_j(Offset(rect.left, rect.bottom)).dx,
        _j(Offset(rect.left, rect.bottom)).dy, c[6].dx, c[6].dy);
    wobbly(c[6], c[7]);
    path.quadraticBezierTo(_j(Offset(rect.left, rect.top)).dx,
        _j(Offset(rect.left, rect.top)).dy, c[0].dx, c[0].dy);
    path.close();
    return path;
  }

  void _paintTexture(Canvas canvas, Rect rect) {
    final rng = math.Random(seed ^ 0xABCD);
    final lp = Paint()
      ..color = const Color(0xFF000000).withValues(alpha: 0.04)
      ..strokeWidth = 0.6
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 6; i++) {
      final y = rect.top + rng.nextDouble() * rect.height;
      canvas.drawLine(
        Offset(rect.left + rng.nextDouble() * rect.width * 0.25,
            y + (rng.nextDouble() - 0.5) * 3),
        Offset(rect.right - rng.nextDouble() * rect.width * 0.25,
            y + (rng.nextDouble() - 0.5) * 3),
        lp,
      );
    }
    final dp = Paint()..color = const Color(0xFF000000).withValues(alpha: 0.05);
    for (int i = 0; i < 5; i++) {
      canvas.drawCircle(
        Offset(rect.left + rng.nextDouble() * rect.width,
            rect.top + rng.nextDouble() * rect.height),
        rng.nextDouble() * 1.2 + 0.4,
        dp,
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final face = _facePath(size);
    if (showShadow && _cachedShadowPath != null) {
      canvas.drawPath(
        _cachedShadowPath!,
        Paint()..color = shadowColor,
      );
    }
    canvas.drawPath(face, Paint()..color = faceColor);
    if (showTexture) _paintTexture(canvas, rect);
    canvas.drawPath(
      face,
      Paint()
        ..color = borderColor.withValues(alpha: borderOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(NotebookCardPainter old) =>
      old.seed != seed ||
      old.faceColor != faceColor ||
      old.borderColor != borderColor ||
      old.borderOpacity != borderOpacity;
}

class TournamentArenaCardPainter extends CustomPainter {
  TournamentArenaCardPainter({
    required this.style,
    required this.locked,
    required this.allDone,
  });

  final ArenaStyle style;
  final bool locked;
  final bool allDone;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(16));

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.translate(4, 5), const Radius.circular(16)),
      Paint()..color = AppColors.shadow,
    );

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

    final borderColor = locked
        ? AppColors.ink.withValues(alpha: 0.15)
        : allDone
            ? AppColors.comicGreen.withValues(alpha: 0.6)
            : AppColors.ink.withValues(alpha: 0.65);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = locked ? 1.5 : 2.5,
    );
  }

  void _paintNotebook(Canvas canvas, Rect rect, RRect rrect) {
    canvas.drawRRect(rrect, Paint()..color = AppColors.paperWhite);
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
    final rng = math.Random(42);
    final dotPaint = Paint()
      ..color = const Color(0xFF000000).withValues(alpha: 0.015);
    for (int i = 0; i < 30; i++) {
      canvas.drawCircle(
        Offset(rect.left + rng.nextDouble() * rect.width,
            rect.top + rng.nextDouble() * rect.height),
        rng.nextDouble() * 1.5 + 0.3,
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
          linePaint);
    }
    canvas.restore();
  }

  void _paintDarkComic(Canvas canvas, Rect rect, RRect rrect) {
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF1A1416));
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.3),
          radius: 0.9,
          colors: [
            const Color(0xFF2D1A22).withValues(alpha: 0.6),
            const Color(0xFF0A0406)
          ],
        ).createShader(rect),
    );
    final rng = math.Random(99);
    final splatPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.02);
    for (int i = 0; i < 40; i++) {
      canvas.drawCircle(
        Offset(rect.left + rng.nextDouble() * rect.width,
            rect.top + rng.nextDouble() * rect.height),
        rng.nextDouble() * 2.0 + 0.4,
        splatPaint,
      );
    }
    final streakPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.015)
      ..strokeWidth = 0.6;
    for (int i = 0; i < 6; i++) {
      final y = rect.top + rng.nextDouble() * rect.height;
      canvas.drawLine(
        Offset(rect.left + rng.nextDouble() * rect.width * 0.3, y),
        Offset(rect.right - rng.nextDouble() * rect.width * 0.3, y),
        streakPaint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(TournamentArenaCardPainter old) =>
      old.style != style || old.locked != locked || old.allDone != allDone;
}

class CharacterPopArtBgPainter extends CustomPainter {
  const CharacterPopArtBgPainter({required this.accent});
  final Color accent;

  static const Color _kDarkBg = Color(0xFF0D0600);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = _kDarkBg,
    );

    final dotPaint = Paint()..color = accent.withValues(alpha: 0.055);
    const spacing = 13.0;
    const dotR = 2.2;
    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotR, dotPaint);
      }
    }

    final linePaint = Paint()
      ..color = accent.withValues(alpha: 0.035)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    final maxX = size.width * 0.66;
    const step = 28.0;
    for (double d = -size.height; d < size.width + size.height; d += step) {
      final x0 = d.clamp(0.0, maxX);
      final y0 = (d < 0) ? -d : 0.0;
      final x1 = (d + size.height).clamp(0.0, maxX);
      final y1 = (d + size.height < maxX) ? 0.0 : size.height;
      canvas.drawLine(Offset(x0, y0), Offset(x1, y1), linePaint);
    }
  }

  @override
  bool shouldRepaint(CharacterPopArtBgPainter old) => old.accent != accent;
}

class CharacterWheelRailPainter extends CustomPainter {
  const CharacterWheelRailPainter({
    required this.cx,
    required this.cy,
    required this.radius,
  });

  final double cx;
  final double cy;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..color = AppColors.comicYellow.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
    canvas.drawArc(rect, -math.pi / 2, math.pi, false, glowPaint);

    final railPaint = Paint()
      ..color = AppColors.comicYellow.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawArc(rect, -math.pi / 2, math.pi, false, railPaint);

    final tickPaint = Paint()
      ..color = AppColors.comicYellow.withValues(alpha: 0.10)
      ..strokeWidth = 1.0;
    for (int t = -4; t <= 4; t++) {
      final a = t * 0.22;
      final outerX = cx - (radius + 4) * math.cos(a);
      final outerY = cy + (radius + 4) * math.sin(a);
      final innerX = cx - (radius - 4) * math.cos(a);
      final innerY = cy + (radius - 4) * math.sin(a);
      canvas.drawLine(
          Offset(outerX, outerY), Offset(innerX, innerY), tickPaint);
    }
  }

  @override
  bool shouldRepaint(CharacterWheelRailPainter old) =>
      old.cx != cx || old.cy != cy || old.radius != radius;
}

class ZigzagClipper extends CustomClipper<Path> {
  final bool isLeft;
  final bool isTop;
  final double topHeight;
  final double slope;
  final double topBaseX;
  final double bottomBaseX;

  ZigzagClipper({
    required this.isLeft,
    required this.isTop,
    required this.topHeight,
    required this.slope,
    required this.topBaseX,
    required this.bottomBaseX,
  });

  @override
  Path getClip(Size size) {
    final Path path = Path();
    if (isTop) {
      if (isLeft) {
        path.lineTo(topBaseX, 0);
        path.lineTo(topBaseX + topHeight * slope, topHeight);
        path.lineTo(0, topHeight);
        path.close();
      } else {
        path.moveTo(topBaseX, 0);
        path.lineTo(size.width, 0);
        path.lineTo(size.width, topHeight);
        path.lineTo(topBaseX + topHeight * slope, topHeight);
        path.close();
      }
    } else {
      final double startY = topHeight;
      final double h = size.height - topHeight;
      if (isLeft) {
        path.moveTo(0, startY);
        path.lineTo(bottomBaseX, startY);
        path.lineTo(bottomBaseX + h * slope, size.height);
        path.lineTo(0, size.height);
        path.close();
      } else {
        path.moveTo(bottomBaseX, startY);
        path.lineTo(size.width, startY);
        path.lineTo(size.width, size.height);
        path.lineTo(bottomBaseX + h * slope, size.height);
        path.close();
      }
    }
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

class ZigzagStrokePainter extends CustomPainter {
  final double topHeight;
  final double slope;
  final double topBaseX;
  final double bottomBaseX;
  final Color color;

  ZigzagStrokePainter({
    required this.topHeight,
    required this.slope,
    required this.topBaseX,
    required this.bottomBaseX,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.miter;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 10.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);

    final path = Path();
    path.moveTo(topBaseX, 0);
    path.lineTo(topBaseX + topHeight * slope, topHeight);
    path.lineTo(bottomBaseX, topHeight);
    final double h = size.height - topHeight;
    path.lineTo(bottomBaseX + h * slope, size.height);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ZigzagStrokePainter oldDelegate) =>
      oldDelegate.topHeight != topHeight ||
      oldDelegate.slope != slope ||
      oldDelegate.topBaseX != topBaseX ||
      oldDelegate.bottomBaseX != bottomBaseX ||
      oldDelegate.color != color;
}

class SketchyHighlightPainter extends CustomPainter {
  SketchyHighlightPainter({
    required this.color,
    this.seed = 42,
    this.jitter = 1.2,
    this.strokeWidth = 1.5,
  }) : _rng = math.Random(seed);

  final Color color;
  final int seed;
  final double jitter;
  final double strokeWidth;
  final math.Random _rng;

  Size? _cachedSize;
  Path? _cachedPath;

  Path _getPath(Size size) {
    if (_cachedSize != size || _cachedPath == null) {
      _cachedSize = size;
      final rect = Rect.fromLTWH(0, 0, size.width, size.height);
      final path = Path();
      final r = 6.0;
      final c = [
        Offset(rect.left + r, rect.top),
        Offset(rect.right - r, rect.top),
        Offset(rect.right, rect.top + r),
        Offset(rect.right, rect.bottom - r),
        Offset(rect.right - r, rect.bottom),
        Offset(rect.left + r, rect.bottom),
        Offset(rect.left, rect.bottom - r),
        Offset(rect.left, rect.top + r),
      ];

      path.moveTo(c[0].dx, c[0].dy);
      void wobbly(Offset from, Offset to) {
        const segs = 4;
        for (int i = 1; i <= segs; i++) {
          final p = _j(Offset.lerp(from, to, i / segs)!);
          path.lineTo(p.dx, p.dy);
        }
      }

      wobbly(c[0], c[1]);
      path.quadraticBezierTo(_j(Offset(rect.right, rect.top)).dx,
          _j(Offset(rect.right, rect.top)).dy, c[2].dx, c[2].dy);
      wobbly(c[2], c[3]);
      path.quadraticBezierTo(_j(Offset(rect.right, rect.bottom)).dx,
          _j(Offset(rect.right, rect.bottom)).dy, c[4].dx, c[4].dy);
      wobbly(c[4], c[5]);
      path.quadraticBezierTo(_j(Offset(rect.left, rect.bottom)).dx,
          _j(Offset(rect.left, rect.bottom)).dy, c[6].dx, c[6].dy);
      wobbly(c[6], c[7]);
      path.quadraticBezierTo(_j(Offset(rect.left, rect.top)).dx,
          _j(Offset(rect.left, rect.top)).dy, c[0].dx, c[0].dy);
      path.close();
      _cachedPath = path;
    }
    return _cachedPath!;
  }

  Offset _j(Offset p) =>
      p +
      Offset(
        (_rng.nextDouble() - 0.5) * jitter,
        (_rng.nextDouble() - 0.5) * jitter,
      );

  @override
  void paint(Canvas canvas, Size size) {
    final path = _getPath(size);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.15));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(SketchyHighlightPainter old) =>
      old.seed != seed || old.color != color || old.strokeWidth != strokeWidth;
}
