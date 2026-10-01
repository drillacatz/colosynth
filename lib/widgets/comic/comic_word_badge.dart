import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:colosynth/screens/theme/tokens.dart';

/// Available backdrop shapes for [ComicWordBadge].
enum ComicBackdropType {
  /// Pillowy comic sleep cloud with rounded lobes and trailing bubbles.
  cloud,

  /// Explosive jagged comic action burst star.
  burst,

  /// Rounded speech / shout bubble.
  bubble,

  /// Transparent backdrop, rendering only the 3D extruded text and halftone.
  none,
}

/// Color and typography styling configuration for [ComicWordBadge].
class ComicBadgeStyle {
  const ComicBadgeStyle({
    required this.faceColor,
    required this.extrusionColor,
    required this.halftoneColor,
    this.outlineColor = AppColors.ink,
    this.backdropFill = AppColors.paperWhite,
    this.backdropShadow = AppColors.shadow,
    this.outlineWidth = 2.4,
    this.extrusionDepth = 5.0,
    this.extrusionAngle = 0.85, // in radians (~49 degrees, pointing down-right)
    this.halftoneSpacing = 3.5,
    this.halftoneDotRadius = 0.95,
  });

  final Color faceColor;
  final Color extrusionColor;
  final Color halftoneColor;
  final Color outlineColor;
  final Color backdropFill;
  final Color backdropShadow;
  final double outlineWidth;
  final double extrusionDepth;
  final double extrusionAngle;
  final double halftoneSpacing;
  final double halftoneDotRadius;

  /// Signature Manga Flame Orange preset (#FF701A).
  static const flameOrange = ComicBadgeStyle(
    faceColor: AppColors.primaryAccent,
    extrusionColor: Color(0xFF8A2E00),
    halftoneColor: Color(0xFFFFD200),
    outlineColor: AppColors.ink,
    backdropFill: AppColors.paperWhite,
    backdropShadow: AppColors.ink,
    outlineWidth: 2.6,
    extrusionDepth: 5.5,
  );

  /// Deep Energy Electric Violet preset (#671FCF).
  static const electricViolet = ComicBadgeStyle(
    faceColor: AppColors.secondaryAccent,
    extrusionColor: Color(0xFF2B0A66),
    halftoneColor: Color(0xFFB388FF),
    outlineColor: AppColors.ink,
    backdropFill: AppColors.paperWhite,
    backdropShadow: AppColors.ink,
    outlineWidth: 2.6,
    extrusionDepth: 5.5,
  );

  /// Pure Monochrome Manga screentone preset (Paper White & Mechanical Ink Dots).
  static const screentoneMonochrome = ComicBadgeStyle(
    faceColor: AppColors.paperWhite,
    extrusionColor: AppColors.charcoal,
    halftoneColor: AppColors.ink,
    outlineColor: AppColors.ink,
    backdropFill: AppColors.paperWhite,
    backdropShadow: AppColors.shadow,
    outlineWidth: 2.4,
    extrusionDepth: 5.0,
    halftoneDotRadius: 0.85,
    halftoneSpacing: 3.2,
  );

  /// Classic Pop-Art Canary Yellow preset.
  static const goldenYellow = ComicBadgeStyle(
    faceColor: Color(0xFFFFD200),
    extrusionColor: Color(0xFFC47D00),
    halftoneColor: AppColors.primaryAccent,
    outlineColor: AppColors.ink,
    backdropFill: AppColors.paperWhite,
    backdropShadow: AppColors.ink,
    outlineWidth: 2.6,
    extrusionDepth: 5.5,
  );
}

/// A high-impact pop-art comic word badge replicating the StudioStoks retro
/// aesthetic: angled 3D extruded typography, Ben-Day halftone dot screentones,
/// heavy ink borders, and organic comic cloud / burst backdrops.
class ComicWordBadge extends StatefulWidget {
  const ComicWordBadge({
    super.key,
    required this.text,
    this.style = ComicBadgeStyle.flameOrange,
    this.backdropType = ComicBackdropType.cloud,
    this.fontSize = 26.0,
    this.tiltAngle = -0.15, // ~ -8.6 degrees ascending comic angle
    this.isAnimated = false,
    this.showTrailingBubbles = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    this.onTap,
  });

  /// The text to display (e.g. `'LV.1'`, `'ZZZ'`, `'POW'`, `'BAM'`).
  final String text;

  /// Visual styling palette.
  final ComicBadgeStyle style;

  /// Shape of the backdrop container.
  final ComicBackdropType backdropType;

  /// Font size for the Bangers comic lettering.
  final double fontSize;

  /// Angle of comic diagonal tilt in radians.
  final double tiltAngle;

  /// Whether to run subtle idle hover bobbing and pop-in physics.
  final bool isAnimated;

  /// Whether to render trailing sleep bubbles for the cloud backdrop.
  final bool showTrailingBubbles;

  /// Interior padding around the text within the backdrop.
  final EdgeInsets padding;

  /// Optional tap handler.
  final VoidCallback? onTap;

  @override
  State<ComicWordBadge> createState() => _ComicWordBadgeState();
}

class _ComicWordBadgeState extends State<ComicWordBadge>
    with SingleTickerProviderStateMixin {
  AnimationController? _animController;
  Animation<double>? _floatAnim;

  @override
  void initState() {
    super.initState();
    _initAnimationIfNeeded();
  }

  @override
  void didUpdateWidget(covariant ComicWordBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimated != oldWidget.isAnimated) {
      _initAnimationIfNeeded();
    }
  }

  void _initAnimationIfNeeded() {
    if (widget.isAnimated) {
      _animController ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2200),
      )..repeat(reverse: true);

      _floatAnim = Tween<double>(begin: -2.5, end: 2.5).animate(
        CurvedAnimation(
          parent: _animController!,
          curve: Curves.easeInOutSine,
        ),
      );
    } else {
      _animController?.dispose();
      _animController = null;
      _floatAnim = null;
    }
  }

  @override
  void dispose() {
    _animController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = CustomPaint(
      painter: _ComicBadgePainter(
        text: widget.text,
        style: widget.style,
        backdropType: widget.backdropType,
        fontSize: widget.fontSize,
        tiltAngle: widget.tiltAngle,
        showTrailingBubbles: widget.showTrailingBubbles,
        padding: widget.padding,
      ),
      child: _SizingProxy(
        text: widget.text,
        fontSize: widget.fontSize,
        padding: widget.padding,
        backdropType: widget.backdropType,
      ),
    );

    if (widget.isAnimated && _floatAnim != null) {
      content = AnimatedBuilder(
        animation: _floatAnim!,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _floatAnim!.value),
            child: child,
          );
        },
        child: content,
      );
    }

    if (widget.onTap != null) {
      content = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: content,
      );
    }

    return Semantics(
      label: widget.text,
      textDirection: TextDirection.ltr,
      child: content,
    );
  }
}

/// Helper widget to measure size for CustomPaint.
class _SizingProxy extends StatelessWidget {
  const _SizingProxy({
    required this.text,
    required this.fontSize,
    required this.padding,
    required this.backdropType,
  });

  final String text;
  final double fontSize;
  final EdgeInsets padding;
  final ComicBackdropType backdropType;

  @override
  Widget build(BuildContext context) {
    // Measure text bounds using Bangers
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Bangers',
          fontSize: fontSize,
          letterSpacing: 2.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Extra margin for 3D extrusion and cloud lobes
    final extraWidth = backdropType == ComicBackdropType.cloud ? 42.0 : 28.0;
    final extraHeight = backdropType == ComicBackdropType.cloud ? 34.0 : 22.0;

    return SizedBox(
      width: textPainter.width + padding.horizontal + extraWidth,
      height: textPainter.height + padding.vertical + extraHeight,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.transparent,
            fontSize: 1,
          ),
        ),
      ),
    );
  }
}

/// Painter that renders the 5 pop-art layers:
/// 1. Backdrop contour (cloud/burst/bubble) + hard drop shadow
/// 2. Trailing sleep bubbles (if cloud)
/// 3. 3D isometric extruded depth
/// 4. Ben-Day halftone dot screentone
/// 5. Ink outlines
class _ComicBadgePainter extends CustomPainter {
  _ComicBadgePainter({
    required this.text,
    required this.style,
    required this.backdropType,
    required this.fontSize,
    required this.tiltAngle,
    required this.showTrailingBubbles,
    required this.padding,
  });

  final String text;
  final ComicBadgeStyle style;
  final ComicBackdropType backdropType;
  final double fontSize;
  final double tiltAngle;
  final bool showTrailingBubbles;
  final EdgeInsets padding;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.48, size.height * 0.48);

    // 1. Draw Backdrop Container
    if (backdropType != ComicBackdropType.none) {
      _paintBackdrop(canvas, size, center);
    }

    // 2. Prepare Angled Canvas for 3D Extruded Text
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(tiltAngle);

    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: 'Bangers',
        fontSize: fontSize,
        letterSpacing: 2.2,
        height: 1.0,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final textOffset = Offset(-textPainter.width / 2, -textPainter.height / 2);

    // 3. Draw 3D Isometric Extrusion (Angled Steps)
    _paint3DExtrusion(canvas, textPainter, textOffset);

    // 4. Draw Letter Face + Halftone Screentone Mask
    _paintFaceWithHalftone(canvas, textPainter, textOffset);

    // 5. Draw Top Crisp Ink Outline
    _paintTopOutline(canvas, textPainter, textOffset);

    canvas.restore();
  }

  void _paintBackdrop(Canvas canvas, Size size, Offset center) {
    switch (backdropType) {
      case ComicBackdropType.cloud:
        _paintCloudBackdrop(canvas, size, center);
        break;
      case ComicBackdropType.burst:
        _paintBurstBackdrop(canvas, size, center);
        break;
      case ComicBackdropType.bubble:
        _paintBubbleBackdrop(canvas, size, center);
        break;
      case ComicBackdropType.none:
        break;
    }
  }

  void _paintCloudBackdrop(Canvas canvas, Size size, Offset center) {
    // Generate pillowy cloud path with overlapping bezier lobes
    final cloudWidth = size.width * 0.82;
    final cloudHeight = size.height * 0.74;
    final cloudRect = Rect.fromCenter(
      center: center,
      width: cloudWidth,
      height: cloudHeight,
    );

    final path = _createCloudPath(cloudRect);
    const shadowOffset = Offset(3.5, 4.0);

    // Drop Shadow
    final shadowPath = path.shift(shadowOffset);
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = style.backdropShadow
        ..style = PaintingStyle.fill,
    );

    // Fill
    canvas.drawPath(
      path,
      Paint()
        ..color = style.backdropFill
        ..style = PaintingStyle.fill,
    );

    // Outline
    canvas.drawPath(
      path,
      Paint()
        ..color = style.outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = style.outlineWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Trailing Sleep Bubbles (Iconic StudioStoks / comic thought detail)
    if (showTrailingBubbles) {
      _paintTrailingBubbles(canvas, cloudRect);
    }
  }

  void _paintTrailingBubbles(Canvas canvas, Rect cloudRect) {
    final bubble1 = Offset(cloudRect.left + 8, cloudRect.bottom + 2);
    final bubble2 = Offset(cloudRect.left - 2, cloudRect.bottom + 10);
    final bubble3 = Offset(cloudRect.left - 8, cloudRect.bottom + 16);

    final bubbles = [
      (center: bubble1, radius: 5.5),
      (center: bubble2, radius: 3.8),
      (center: bubble3, radius: 2.2),
    ];

    const shadowOffset = Offset(2.0, 2.5);

    for (final b in bubbles) {
      // Shadow
      canvas.drawCircle(
        b.center + shadowOffset,
        b.radius,
        Paint()
          ..color = style.backdropShadow
          ..style = PaintingStyle.fill,
      );
      // Fill
      canvas.drawCircle(
        b.center,
        b.radius,
        Paint()
          ..color = style.backdropFill
          ..style = PaintingStyle.fill,
      );
      // Outline
      canvas.drawCircle(
        b.center,
        b.radius,
        Paint()
          ..color = style.outlineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = style.outlineWidth * 0.75,
      );
    }
  }

  Path _createCloudPath(Rect rect) {
    final path = Path();
    final left = rect.left;
    final top = rect.top;
    final right = rect.right;
    final bottom = rect.bottom;
    final w = rect.width;
    final h = rect.height;

    // Build organic multi-lobed cloud contour
    path.moveTo(left + w * 0.20, top);

    // Top lobes
    path.arcToPoint(Offset(left + w * 0.50, top - h * 0.08),
        radius: Radius.circular(w * 0.22), clockwise: true);
    path.arcToPoint(Offset(left + w * 0.80, top),
        radius: Radius.circular(w * 0.22), clockwise: true);

    // Right lobes
    path.arcToPoint(Offset(right + w * 0.05, top + h * 0.40),
        radius: Radius.circular(h * 0.25), clockwise: true);
    path.arcToPoint(Offset(right, bottom - h * 0.15),
        radius: Radius.circular(h * 0.26), clockwise: true);

    // Bottom lobes
    path.arcToPoint(Offset(left + w * 0.65, bottom + h * 0.06),
        radius: Radius.circular(w * 0.22), clockwise: true);
    path.arcToPoint(Offset(left + w * 0.30, bottom + h * 0.04),
        radius: Radius.circular(w * 0.24), clockwise: true);
    path.arcToPoint(Offset(left, bottom - h * 0.15),
        radius: Radius.circular(w * 0.20), clockwise: true);

    // Left lobes
    path.arcToPoint(Offset(left - w * 0.05, top + h * 0.45),
        radius: Radius.circular(h * 0.26), clockwise: true);
    path.arcToPoint(Offset(left + w * 0.20, top),
        radius: Radius.circular(h * 0.25), clockwise: true);

    path.close();
    return path;
  }

  void _paintBurstBackdrop(Canvas canvas, Size size, Offset center) {
    final burstRect = Rect.fromCenter(
      center: center,
      width: size.width * 0.86,
      height: size.height * 0.78,
    );

    final path = Path();
    const points = 14;
    final rx = burstRect.width / 2;
    final ry = burstRect.height / 2;

    for (int i = 0; i < points * 2; i++) {
      final angle = (i * math.pi / points) - math.pi / 2;
      final isTip = i % 2 == 0;
      final factor = isTip ? 1.0 : 0.65;
      final x = center.dx + math.cos(angle) * rx * factor;
      final y = center.dy + math.sin(angle) * ry * factor;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    const shadowOffset = Offset(4.0, 4.0);

    // Shadow
    canvas.drawPath(
      path.shift(shadowOffset),
      Paint()
        ..color = style.backdropShadow
        ..style = PaintingStyle.fill,
    );

    // Fill
    canvas.drawPath(
      path,
      Paint()
        ..color = style.backdropFill
        ..style = PaintingStyle.fill,
    );

    // Outline
    canvas.drawPath(
      path,
      Paint()
        ..color = style.outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = style.outlineWidth
        ..strokeJoin = StrokeJoin.miter,
    );
  }

  void _paintBubbleBackdrop(Canvas canvas, Size size, Offset center) {
    final bubbleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.84,
        height: size.height * 0.72,
      ),
      const Radius.circular(16),
    );

    final path = Path()..addRRect(bubbleRect);
    const shadowOffset = Offset(3.5, 3.5);

    canvas.drawPath(
      path.shift(shadowOffset),
      Paint()
        ..color = style.backdropShadow
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = style.backdropFill
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = style.outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = style.outlineWidth,
    );
  }

  void _paint3DExtrusion(
    Canvas canvas,
    TextPainter textPainter,
    Offset origin,
  ) {
    final depth = style.extrusionDepth;
    final angle = style.extrusionAngle;
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);

    const int steps = 12;
    final stepDistance = depth / steps;

    // Draw stepped passes from farthest back to nearest
    for (int i = steps; i >= 1; i--) {
      final curDist = i * stepDistance;
      final stepOffset = origin + Offset(curDist * cosA, curDist * sinA);

      // Black outline pass for solid edges
      textPainter.text = TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Bangers',
          fontSize: fontSize,
          letterSpacing: 2.2,
          height: 1.0,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = style.outlineWidth + 1.2
            ..strokeJoin = StrokeJoin.round
            ..color = style.outlineColor,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, stepOffset);

      // Extrusion color fill pass
      textPainter.text = TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Bangers',
          fontSize: fontSize,
          letterSpacing: 2.2,
          height: 1.0,
          foreground: Paint()
            ..style = PaintingStyle.fill
            ..color = style.extrusionColor,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, stepOffset);
    }
  }

  void _paintFaceWithHalftone(
    Canvas canvas,
    TextPainter textPainter,
    Offset origin,
  ) {
    final textBounds = Rect.fromLTWH(
      origin.dx - 4,
      origin.dy - 4,
      textPainter.width + 8,
      textPainter.height + 8,
    );

    // Use saveLayer to mask the halftone dots precisely to the text glyphs
    canvas.saveLayer(textBounds, Paint());

    // Step A: Fill text face in solid faceColor
    textPainter.text = TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: 'Bangers',
        fontSize: fontSize,
        letterSpacing: 2.2,
        height: 1.0,
        foreground: Paint()
          ..style = PaintingStyle.fill
          ..color = style.faceColor,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, origin);

    // Step B: Draw Ben-Day Halftone Dot Grid on the lower 50% of the text
    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = style.halftoneColor
      ..blendMode = BlendMode.srcATop; // Only renders inside the text fill!

    final spacing = style.halftoneSpacing;
    final dotRadius = style.halftoneDotRadius;
    final halfY = origin.dy + textPainter.height * 0.42;

    for (double y = halfY; y <= origin.dy + textPainter.height + 2; y += spacing) {
      // Row offset for authentic hexagonal Ben-Day screentone alignment
      final isOdd = ((y - halfY) / spacing).round() % 2 == 1;
      final startX = origin.dx + (isOdd ? spacing * 0.5 : 0.0);

      // Progressively increase dot size toward the bottom for gradient screentone
      final progress = ((y - halfY) / (textPainter.height * 0.58)).clamp(0.0, 1.0);
      final dynamicRadius = dotRadius * (0.7 + progress * 0.6);

      for (double x = startX; x <= origin.dx + textPainter.width + 2; x += spacing) {
        canvas.drawCircle(Offset(x, y), dynamicRadius, dotPaint);
      }
    }

    canvas.restore();
  }

  void _paintTopOutline(
    Canvas canvas,
    TextPainter textPainter,
    Offset origin,
  ) {
    // Crisp ink stroke around top face
    textPainter.text = TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: 'Bangers',
        fontSize: fontSize,
        letterSpacing: 2.2,
        height: 1.0,
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = style.outlineWidth
          ..strokeJoin = StrokeJoin.round
          ..color = style.outlineColor,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, origin);
  }

  @override
  bool shouldRepaint(covariant _ComicBadgePainter oldDelegate) {
    return oldDelegate.text != text ||
        oldDelegate.style != style ||
        oldDelegate.backdropType != backdropType ||
        oldDelegate.fontSize != fontSize ||
        oldDelegate.tiltAngle != tiltAngle;
  }
}
