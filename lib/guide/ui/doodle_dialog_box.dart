import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:colosynth/screens/theme/tokens.dart';

/// A premium hand-drawn dialog box widget designed to look like a torn sheet
/// of lined notebook paper.
///
/// Migrated from `database/story/ui/doodle_dialog_box.dart` — no functional
/// changes. This is a pure presentational widget used by [GuideOverlay] for
/// dialogue-type guide steps.
class DoodleDialogBox extends StatelessWidget {
  /// The contents inside the dialog box (usually the typewriter text).
  final Widget child;

  /// Name of the speaking character.
  final String speakerName;

  /// Accent color of the character for styling their name banner.
  final Color speakerAccentColor;

  const DoodleDialogBox({
    super.key,
    required this.child,
    required this.speakerName,
    required this.speakerAccentColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DoodleDialogBoxPainter(
        faceColor: const Color(0xFFFDFDFB),
        shadowColor: const Color(0xFFD0C8C0),
        inkColor: const Color(0xFF111111),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -18,
            left: 28,
            child: ComicButton(
              label: speakerName.toUpperCase(),
              style: PBStyle.dark,
              fontSize: 14,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: speakerAccentColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
              ),
              onTap: null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 56.0,
              right: 28.0,
              top: 28.0,
              bottom: 24.0,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _DoodleDialogBoxPainter extends CustomPainter {
  final Color faceColor;
  final Color shadowColor;
  final Color inkColor;
  final math.Random _rng;

  _DoodleDialogBoxPainter({
    required this.faceColor,
    required this.shadowColor,
    required this.inkColor,
  }) : _rng = math.Random(1337);

  static const double _bw = 3.0;
  static const double _j = 1.6;
  static const double _r = 8.0;
  static const int _segsPerEdge = 12;
  static const double _lineSpacing = 24.0;
  static const double _marginX = 44.0;

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

    final shadowRect = rect.translate(6, 6);
    final shadowPath = _doodlePath(shadowRect);
    canvas.drawPath(shadowPath, Paint()..color = shadowColor);

    final facePath = _doodlePath(rect);
    canvas.drawPath(facePath, Paint()..color = faceColor);

    canvas.save();
    canvas.clipPath(facePath);
    _paintNotebookLines(canvas, rect);
    _paintRedMargin(canvas, rect);
    canvas.restore();

    final inkPaint = Paint()
      ..color = inkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _bw
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(facePath, inkPaint);
  }

  void _paintNotebookLines(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = const Color(0xFFB8D4F0).withValues(alpha: 0.70)
      ..strokeWidth = 1.0;

    double y = rect.top + _lineSpacing + 12.0;
    while (y < rect.bottom) {
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), paint);
      y += _lineSpacing;
    }
  }

  void _paintRedMargin(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = const Color(0xFFFFB3BA).withValues(alpha: 0.85)
      ..strokeWidth = 1.2;

    final x = rect.left + _marginX;
    canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), paint);
  }

  @override
  bool shouldRepaint(_DoodleDialogBoxPainter old) => false;
}
