import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:colosynth/game_settings.dart';
import 'package:colosynth/services/audio_service.dart';

enum PBStyle { dark, white }

@immutable
class PBColorSet {
  const PBColorSet({
    required this.face,
    required this.shadow,
    required this.text,
    required this.ink,
  });

  final Color face;
  final Color shadow;
  final Color text;
  final Color ink;
}

@immutable
class HalftoneVariant {
  const HalftoneVariant({
    required this.dotR,
    required this.spacing,
    required this.white,
    required this.opacity,
  });

  final double dotR;
  final double spacing;
  final bool white;
  final double opacity;
}

@immutable
class PBHighlightSpec {
  const PBHighlightSpec({
    required this.top,
    required this.mid,
    required this.left,
  });

  final double top;
  final double mid;
  final double left;
}

abstract final class PBTokens {
  static const double chamfer = 8.0;
  static const double borderWidth = 2.5;
  static const double hpNotchW = 14.0;
  static const double hpNotchH = 6.0;
  static const double hpBorderW = 3.0;
  static const Offset shadowOffset = Offset(5, 5);
  static const Offset circleShadowOffset = Offset(3, 3);
  static const double hl1 = 0.90;
  static const double hl2 = 0.42;
  static const double hl3 = 0.65;
  static const Duration squeezeDuration = Duration(milliseconds: 80);
  static const Duration pressDuration = Duration(milliseconds: 80);
  static const double pressScale = 0.90;
  static const double halftoneStart = 0.35;

  static const double doodleBorderWidth = 3.2;
  static const double doodleJitter = 0.0;

  static Map<PBStyle, PBColorSet> get colors {
    return const {
      PBStyle.dark: PBColorSet(
        face: Color(0xFFF5F2EE),
        shadow: Color(0xFFD0C8C0),
        text: Color(0xFF1A0E00),
        ink: Color(0xFF1A0E00),
      ),
      PBStyle.white: PBColorSet(
        face: Color(0xFFFFFFFF),
        shadow: Color(0xFFDDDDDD),
        text: Color(0xFF1A0A00),
        ink: Color(0xFF333333),
      ),
    };
  }

  static Map<PBStyle, HalftoneVariant> get halftone {
    return const {
      PBStyle.dark: HalftoneVariant(
          dotR: 0.9, spacing: 3.0, white: true, opacity: 0.28),
      PBStyle.white: HalftoneVariant(
          dotR: 1.4, spacing: 5.0, white: false, opacity: 0.15),
    };
  }

  static Map<PBStyle, PBHighlightSpec> get highlights {
    return const {
      PBStyle.dark: PBHighlightSpec(top: 0.35, mid: 0.18, left: 0.28),
      PBStyle.white: PBHighlightSpec(top: 0.95, mid: 0.55, left: 0.72),
    };
  }
}

class ComicButton extends StatefulWidget {
  const ComicButton({
    super.key,
    required this.label,
    required this.style,
    required this.onTap,
    this.fontSize = 15,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    this.leading,
  });

  final String label;
  final PBStyle style;
  final VoidCallback? onTap;
  final double fontSize;
  final EdgeInsets padding;
  final Widget? leading;

  static void playButtonSfx() {
    AudioService.instance.playSfx(SfxEvent.button);
  }

  @override
  State<ComicButton> createState() => _ComicButtonState();
}

class _ComicButtonState extends State<ComicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;

  static const _spring = SpringDescription(
    mass: 1.0,
    stiffness: 700.0,
    damping: 38.0,
  );

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      lowerBound: 0.0,
      upperBound: 1.0,
      duration: PBTokens.squeezeDuration,
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: PBTokens.pressScale,
    ).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _isDisabled => widget.onTap == null;

  void _onTapDown(TapDownDetails _) {
    if (_isDisabled) return;
    HapticFeedback.lightImpact();
    ComicButton.playButtonSfx();
    _ctrl.animateTo(1.0,
        duration: PBTokens.squeezeDuration, curve: Curves.easeIn);
  }

  void _onTapUp(TapUpDetails _) {
    if (_isDisabled) return;
    widget.onTap?.call();
    _springBack();
  }

  void _onTapCancel() => _springBack();

  void _springBack() {
    _ctrl.animateWith(SpringSimulation(_spring, _ctrl.value, 0.0, -3.0));
  }

  @override
  Widget build(BuildContext context) {
    final colors = PBTokens.colors[widget.style]!;

    return AnimatedOpacity(
      opacity: _isDisabled ? 0.46 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: GestureDetector(
        onTapDown: _isDisabled ? null : _onTapDown,
        onTapUp: _isDisabled ? null : _onTapUp,
        onTapCancel: _isDisabled ? null : _onTapCancel,
        child: AnimatedBuilder(
          animation: _scaleAnim,
          builder: (_, child) => Transform.scale(
            scale: _scaleAnim.value,
            child: child,
          ),
          child: _DoodleButtonBody(
            label: widget.label,
            fontSize: widget.fontSize,
            padding: widget.padding,
            colors: colors,
            style: widget.style,
            leading: widget.leading,
          ),
        ),
      ),
    );
  }
}

class _DoodleButtonBody extends StatelessWidget {
  const _DoodleButtonBody({
    required this.label,
    required this.fontSize,
    required this.padding,
    required this.colors,
    required this.style,
    this.leading,
  });

  final String label;
  final double fontSize;
  final EdgeInsets padding;
  final PBColorSet colors;
  final PBStyle style;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DoodleBorderPainter(
        faceColor: colors.face,
        shadowColor: colors.shadow,
        inkColor: colors.ink,
        style: style,
      ),
      child: Padding(
        padding: padding + const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 10),
            ],
            Text(
              label,
              style: TextStyle(
                color: colors.text,
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                fontFamily: 'Bangers',
                letterSpacing: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DoodleBorderPainter extends CustomPainter {
  DoodleBorderPainter({
    required this.faceColor,
    required this.shadowColor,
    required this.inkColor,
    required this.style,
  }) : _rng = math.Random(style.index * 31 + 7);

  final Color faceColor;
  final Color shadowColor;
  final Color inkColor;
  final PBStyle style;
  final math.Random _rng;

  static const double _j = PBTokens.doodleJitter;
  static const double _bw = PBTokens.doodleBorderWidth;
  static const double _r = 6.0;
  static const int _segsPerEdge = 4;

  Offset _jitter(Offset p) =>
      p +
      Offset((_rng.nextDouble() - 0.5) * _j, (_rng.nextDouble() - 0.5) * _j);

  Path _doodlePath(Rect rect) {
    final corners = [
      Offset(rect.left + _r, rect.top),
      Offset(rect.right - _r, rect.top),
      Offset(rect.right, rect.top + _r),
      Offset(rect.right, rect.bottom - _r),
      Offset(rect.right - _r, rect.bottom),
      Offset(rect.left + _r, rect.bottom),
      Offset(rect.left, rect.bottom - _r),
      Offset(rect.left, rect.top + _r),
    ];

    final path = Path();
    path.moveTo(corners[0].dx, corners[0].dy);

    void wobblyLine(Offset from, Offset to) {
      for (int i = 1; i <= _segsPerEdge; i++) {
        final t = i / _segsPerEdge;
        final mid = Offset.lerp(from, to, t)!;
        final j = _jitter(mid);
        path.lineTo(j.dx, j.dy);
      }
    }

    wobblyLine(corners[0], corners[1]);
    path.quadraticBezierTo(
      _jitter(Offset(rect.right, rect.top)).dx,
      _jitter(Offset(rect.right, rect.top)).dy,
      corners[2].dx,
      corners[2].dy,
    );
    wobblyLine(corners[2], corners[3]);
    path.quadraticBezierTo(
      _jitter(Offset(rect.right, rect.bottom)).dx,
      _jitter(Offset(rect.right, rect.bottom)).dy,
      corners[4].dx,
      corners[4].dy,
    );
    wobblyLine(corners[4], corners[5]);
    path.quadraticBezierTo(
      _jitter(Offset(rect.left, rect.bottom)).dx,
      _jitter(Offset(rect.left, rect.bottom)).dy,
      corners[6].dx,
      corners[6].dy,
    );
    wobblyLine(corners[6], corners[7]);
    path.quadraticBezierTo(
      _jitter(Offset(rect.left, rect.top)).dx,
      _jitter(Offset(rect.left, rect.top)).dy,
      corners[0].dx,
      corners[0].dy,
    );
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final shadowRect = rect.translate(4, 4);
    final shadowPath = _doodlePath(shadowRect);
    canvas.drawPath(shadowPath, Paint()..color = shadowColor);

    final facePath = _doodlePath(rect);
    canvas.drawPath(facePath, Paint()..color = faceColor);

    _paintPaperTexture(canvas, rect);

    final inkPaint = Paint()
      ..color = const Color(0xFF111111)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _bw
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(facePath, inkPaint);

    final accentPaint = Paint()
      ..color = inkColor.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _bw * 0.5
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(facePath, accentPaint);
  }

  void _paintPaperTexture(Canvas canvas, Rect rect) {
    final rng = math.Random(style.index * 17 + 3);
    final linePaint = Paint()
      ..color = const Color(0xFF000000).withValues(alpha: 0.04)
      ..strokeWidth = 0.6
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 8; i++) {
      final y = rect.top + rng.nextDouble() * rect.height;
      final x0 = rect.left + rng.nextDouble() * rect.width * 0.3;
      final x1 = rect.right - rng.nextDouble() * rect.width * 0.3;
      canvas.drawLine(
        Offset(x0, y + (rng.nextDouble() - 0.5) * 3),
        Offset(x1, y + (rng.nextDouble() - 0.5) * 3),
        linePaint,
      );
    }

    final dotPaint = Paint()
      ..color = const Color(0xFF000000).withValues(alpha: 0.05);
    for (int i = 0; i < 6; i++) {
      canvas.drawCircle(
        Offset(
          rect.left + rng.nextDouble() * rect.width,
          rect.top + rng.nextDouble() * rect.height,
        ),
        rng.nextDouble() * 1.5 + 0.5,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(DoodleBorderPainter old) =>
      old.faceColor != faceColor ||
      old.inkColor != inkColor ||
      old.style != style;
}

class AppColors {
  AppColors._();

  // Core Monochrome Manga Tokens
  static const Color ink = Color(0xFF1A1A1A);
  static const Color charcoal = Color(0xFF2A2A2A);
  static const Color darkGray = Color(0xFF424242);
  static const Color sketchGray = Color(0xFF888888);
  static const Color lightGray = Color(0xFFE5E5E5);
  static const Color paperWhite = Color(0xFFFDFDFB);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color shadow = Color(0xFFD0C8C0);
  static const Color notebookLine = Color(0xFFE5E5E5);
  static const Color notebookMargin = Color(0xFFCCCCCC);

  // Monochrome Mappings (replacing legacy colored tokens)
  static const Color comicBlue = ink;
  static const Color electricCyan = ink;
  static const Color electricBlue = ink;
  static const Color neonViolet = darkGray;
  static const Color comicYellow = ink;
  static const Color comicRed = darkGray;
  static const Color comicGreen = sketchGray;
}
