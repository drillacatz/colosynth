import 'package:flutter/material.dart';

/// Slope for the diagonal slicing cutlines across the screen (negative = slant/tilt left like '/').
const double _kCutlineSlope = -0.40;

/// Reusable PageRouteBuilder that animates the pushed screen as 3 diagonal
/// pieces sliding in from the top-right corner, converging seamlessly into
/// the complete screen with comic ink border accents.
///
/// When exiting, pieces slide away towards the bottom-left corner continuing
/// forward momentum.
class DiagonalSlicePageRoute<T> extends PageRouteBuilder<T> {
  final WidgetBuilder builder;

  DiagonalSlicePageRoute({
    required this.builder,
    super.settings,
    super.transitionDuration = const Duration(milliseconds: 380),
    super.reverseTransitionDuration = const Duration(milliseconds: 300),
  }) : super(
          pageBuilder: (context, anim, secAnim) => builder(context),
          transitionsBuilder: (context, anim, secAnim, child) {
            return DiagonalSliceTransition(
              animation: anim,
              secondaryAnimation: secAnim,
              child: child,
            );
          },
        );
}

/// Widget that splits its [child] into three non-overlapping diagonal pieces
/// that slide in from the top-right corner and snap together seamlessly.
class DiagonalSliceTransition extends StatelessWidget {
  const DiagonalSliceTransition({
    super.key,
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([animation, secondaryAnimation]),
      builder: (context, _) {
        // Fast-path: When transition is fully complete and not covered by another
        // route, render a single clean child without clipping or duplicate trees.
        if (animation.isCompleted && secondaryAnimation.isDismissed) {
          return child;
        }

        final size = MediaQuery.sizeOf(context);
        final animVal = animation.value;
        final isPopping = animation.status == AnimationStatus.reverse;

        // Base entrance progress with ease-out cubic
        final t = animVal.clamp(0.0, 1.0);

        // Piece 1: Top-Right (Interval 0.00..0.72)
        final p1Progress = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.00, 0.72, curve: Curves.easeOutCubic),
        ).value;

        // Piece 2: Middle (Interval 0.14..0.86)
        final p2Progress = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.14, 0.86, curve: Curves.easeOutCubic),
        ).value;

        // Piece 3: Bottom-Left (Interval 0.28..1.00)
        final p3Progress = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.28, 1.00, curve: Curves.easeOutCubic),
        ).value;

        // Entrance slide vectors (from top-right towards 0,0)
        // Exit slide vectors (when popping, continue momentum towards bottom-left)
        Offset offset1;
        Offset offset2;
        Offset offset3;

        if (isPopping) {
          // Slide away towards bottom-left (-x, +y)
          final exitCurve = Curves.easeInCubic.transform((1.0 - t).clamp(0.0, 1.0));
          offset1 = Offset(-size.width * 0.70 * exitCurve, size.height * 0.70 * exitCurve);
          offset2 = Offset(-size.width * 0.90 * exitCurve, size.height * 0.90 * exitCurve);
          offset3 = Offset(-size.width * 1.10 * exitCurve, size.height * 1.10 * exitCurve);
        } else {
          // Slide in from top-right (+x, -y) down to 0,0
          offset1 = Offset(size.width * 0.70 * (1.0 - p1Progress), -size.height * 0.70 * (1.0 - p1Progress));
          offset2 = Offset(size.width * 0.90 * (1.0 - p2Progress), -size.height * 0.90 * (1.0 - p2Progress));
          offset3 = Offset(size.width * 1.10 * (1.0 - p3Progress), -size.height * 1.10 * (1.0 - p3Progress));
        }

        // Secondary animation: when a new route pushes on top of this one
        // Background remains static without translation offset to eliminate screen misalignment
        final secVal = secondaryAnimation.value;

        // Border line opacity (fades out as animation approaches 1.0)
        final borderOpacity = (1.0 - t * 1.2).clamp(0.0, 1.0);

        return Stack(
          fit: StackFit.expand,
          children: [
            // Underlying dark backdrop
            Container(color: Colors.black.withValues(alpha: 0.45 * t)),

            // Comic diagonal shard backgrounds sliding with pieces
            if (!animation.isCompleted)
              CustomPaint(
                size: size,
                painter: _DiagonalShardBackgroundPainter(
                  slope: _kCutlineSlope,
                  offset1: offset1,
                  offset2: offset2,
                  offset3: offset3,
                  opacity: t.clamp(0.2, 1.0),
                ),
              ),

            // Unified Single-Child 3-Diagonal Slices with physical translation
            Transform.translate(
              offset: offset2,
              child: ClipPath(
                clipper: _ThreeDiagonalSlicesClipper(
                  slope: _kCutlineSlope,
                  offset1: offset1 - offset2,
                  offset2: Offset.zero,
                  offset3: offset3 - offset2,
                ),
                child: child,
              ),
            ),

            // Comic ink slash boundary lines during motion
            if (borderOpacity > 0.01)
              CustomPaint(
                size: size,
                painter: _DiagonalSeamPainter(
                  slope: _kCutlineSlope,
                  offset1: offset1,
                  offset2: offset2,
                  offset3: offset3,
                  opacity: borderOpacity,
                ),
              ),

            // Secondary dimming overlay when covered by a new route
            if (secVal > 0)
              Container(
                color: Colors.black.withValues(alpha: 0.35 * secVal),
              ),
          ],
        );
      },
    );
  }
}

/// Unified clipper that constructs the combined visible Path from three
/// staggered diagonal slices sliding along cutlines across the viewport.
class _ThreeDiagonalSlicesClipper extends CustomClipper<Path> {
  const _ThreeDiagonalSlicesClipper({
    required this.slope,
    required this.offset1,
    required this.offset2,
    required this.offset3,
  });

  final double slope;
  final Offset offset1;
  final Offset offset2;
  final Offset offset3;

  @override
  Path getClip(Size size) {
    final m1 = size.height * 0.32;
    final y1Left = m1 - slope * (size.width / 2);
    final y1Right = m1 + slope * (size.width / 2);

    final m2 = size.height * 0.68;
    final y2Left = m2 - slope * (size.width / 2);
    final y2Right = m2 + slope * (size.width / 2);

    // Piece 1: Top Slice (slanting left like '/')
    final p1 = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, y1Right)
      ..lineTo(0, y1Left)
      ..close();

    // Piece 2: Middle Ribbon Slice
    final p2 = Path()
      ..moveTo(0, y1Left)
      ..lineTo(size.width, y1Right)
      ..lineTo(size.width, y2Right)
      ..lineTo(0, y2Left)
      ..close();

    // Piece 3: Bottom Slice
    final p3 = Path()
      ..moveTo(0, y2Left)
      ..lineTo(size.width, y2Right)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final combined = Path();
    combined.addPath(p1, offset1);
    combined.addPath(p2, offset2);
    combined.addPath(p3, offset3);
    return combined;
  }

  @override
  bool shouldReclip(_ThreeDiagonalSlicesClipper oldClipper) =>
      oldClipper.slope != slope ||
      oldClipper.offset1 != offset1 ||
      oldClipper.offset2 != offset2 ||
      oldClipper.offset3 != offset3;
}

/// Painter that renders stylized comic panel shards behind the incoming content.
class _DiagonalShardBackgroundPainter extends CustomPainter {
  const _DiagonalShardBackgroundPainter({
    required this.slope,
    required this.offset1,
    required this.offset2,
    required this.offset3,
    required this.opacity,
  });

  final double slope;
  final Offset offset1;
  final Offset offset2;
  final Offset offset3;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final m1 = size.height * 0.32;
    final y1Left = m1 - slope * (size.width / 2);
    final y1Right = m1 + slope * (size.width / 2);

    final m2 = size.height * 0.68;
    final y2Left = m2 - slope * (size.width / 2);
    final y2Right = m2 + slope * (size.width / 2);

    final bgPaint = Paint()
      ..color = const Color(0xFFFBFBFA).withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    // Piece 1
    final p1 = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, y1Right)
      ..lineTo(0, y1Left)
      ..close();
    canvas.drawPath(p1.shift(offset1), bgPaint);

    // Piece 2
    final p2 = Path()
      ..moveTo(0, y1Left)
      ..lineTo(size.width, y1Right)
      ..lineTo(size.width, y2Right)
      ..lineTo(0, y2Left)
      ..close();
    canvas.drawPath(p2.shift(offset2), bgPaint);

    // Piece 3
    final p3 = Path()
      ..moveTo(0, y2Left)
      ..lineTo(size.width, y2Right)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(p3.shift(offset3), bgPaint);
  }

  @override
  bool shouldRepaint(_DiagonalShardBackgroundPainter oldDelegate) =>
      oldDelegate.slope != slope ||
      oldDelegate.offset1 != offset1 ||
      oldDelegate.offset2 != offset2 ||
      oldDelegate.offset3 != offset3 ||
      oldDelegate.opacity != opacity;
}

/// Custom painter for comic ink slash lines along the diagonal cut seams.
class _DiagonalSeamPainter extends CustomPainter {
  const _DiagonalSeamPainter({
    required this.slope,
    required this.offset1,
    required this.offset2,
    required this.offset3,
    required this.opacity,
  });

  final double slope;
  final Offset offset1;
  final Offset offset2;
  final Offset offset3;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final m1 = size.height * 0.32;
    final y1Left = m1 - slope * (size.width / 2);
    final y1Right = m1 + slope * (size.width / 2);

    final m2 = size.height * 0.68;
    final y2Left = m2 - slope * (size.width / 2);
    final y2Right = m2 + slope * (size.width / 2);

    // Ink dark edge
    final inkPaint = Paint()
      ..color = const Color(0xFF1A1A1A).withValues(alpha: opacity)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // Glowing accent hairline (cyan highlight)
    final glowPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: opacity * 0.8)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Seam 1 (between Piece 1 & 2): interpolate offsets
    final seam1Offset = (offset1 + offset2) / 2;
    final p1Start = Offset(0, y1Left) + seam1Offset;
    final p1End = Offset(size.width, y1Right) + seam1Offset;
    canvas.drawLine(p1Start, p1End, inkPaint);
    canvas.drawLine(Offset(p1Start.dx, p1Start.dy - 1), Offset(p1End.dx, p1End.dy - 1), glowPaint);

    // Seam 2 (between Piece 2 & 3): interpolate offsets
    final seam2Offset = (offset2 + offset3) / 2;
    final p2Start = Offset(0, y2Left) + seam2Offset;
    final p2End = Offset(size.width, y2Right) + seam2Offset;
    canvas.drawLine(p2Start, p2End, inkPaint);
    canvas.drawLine(Offset(p2Start.dx, p2Start.dy - 1), Offset(p2End.dx, p2End.dy - 1), glowPaint);
  }

  @override
  bool shouldRepaint(covariant _DiagonalSeamPainter oldDelegate) =>
      oldDelegate.slope != slope ||
      oldDelegate.offset1 != offset1 ||
      oldDelegate.offset2 != offset2 ||
      oldDelegate.offset3 != offset3 ||
      oldDelegate.opacity != opacity;
}
