import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import 'package:colosynth/screens/ready/battle_ready_widgets.dart';

class LightningDivisor extends StatefulWidget {
  const LightningDivisor({
    super.key,
    required this.segments,
    this.color = const Color(0xFFFF3B30),
    this.thickness = 4.0,
    this.entranceDuration = const Duration(milliseconds: 600),
    this.onEntranceFinished,
    this.skipEntrance = false,
  });

  final List<(Offset, Offset)> segments;
  final Color color;
  final double thickness;
  final Duration entranceDuration;
  final VoidCallback? onEntranceFinished;
  final bool skipEntrance;

  @override
  State<LightningDivisor> createState() => _LightningDivisorState();
}

class _LightningDivisorState extends State<LightningDivisor>
    with TickerProviderStateMixin {
  late AnimationController _wiggleController;
  late AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _entranceController = AnimationController(
      vsync: this,
      duration: widget.entranceDuration,
      value: widget.skipEntrance ? 1.0 : 0.0,
    );

    _entranceController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onEntranceFinished?.call();
      }
    });

    if (!widget.skipEntrance) {
      _entranceController.forward();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onEntranceFinished?.call();
      });
    }
  }

  @override
  void didUpdateWidget(covariant LightningDivisor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.skipEntrance && _entranceController.value < 1.0) {
      _entranceController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _wiggleController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_wiggleController, _entranceController]),
        builder: (context, child) {
          return CustomPaint(
            painter: _LightningPainter(
              segments: widget.segments,
              color: widget.color,
              thickness: widget.thickness,
              animationValue: _wiggleController.value,
              drawProgress: _entranceController.value,
            ),
          );
        },
      ),
    );
  }
}

class _LightningPainter extends CustomPainter {
  _LightningPainter({
    required this.segments,
    required this.color,
    required this.thickness,
    required this.animationValue,
    required this.drawProgress,
  });

  final List<(Offset, Offset)> segments;
  final Color color;
  final double thickness;
  final double animationValue;
  final double drawProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    final corePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = thickness * 0.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double time = animationValue * 6.28;


    final totalSegments = segments.length;

    for (int s = 0; s < totalSegments; s++) {
      final segmentProgress =
          (drawProgress * totalSegments - s).clamp(0.0, 1.0);
      if (segmentProgress <= 0) continue;

      final segment = segments[s];
      final start = segment.$1;
      final end = segment.$2;

      final path = Path();
      path.moveTo(start.dx, start.dy);

      const int subSegmentCount = 12;
      final Offset vector = end - start;
      final currentVector = vector * segmentProgress;

      for (int i = 1; i < subSegmentCount; i++) {
        final double t = i / subSegmentCount;
        if (t > segmentProgress) break;

        final Offset point = start + vector * t;
        final double wiggle = (math.sin(time + i * 1.5) * 4.0) +
            (math.sin(time * 0.5 + i * 2.5) * 2.0);
        final Offset normal =
            Offset(-vector.dy, vector.dx).normalize() * wiggle;

        path.lineTo(point.dx + normal.dx, point.dy + normal.dy);
      }

      final Offset actualEnd = start + currentVector;
      path.lineTo(actualEnd.dx, actualEnd.dy);

      canvas.drawPath(path, paint);
      canvas.drawPath(path, corePaint);
    }
  }

  @override
  bool shouldRepaint(_LightningPainter oldDelegate) => true;
}

extension _OffsetExtension on Offset {
  Offset normalize() {
    final double len = distance;
    if (len == 0) return Offset.zero;
    return this / len;
  }
}

class ZigzagEnterOverlay extends StatefulWidget {
  const ZigzagEnterOverlay({super.key, this.onFinished});
  final VoidCallback? onFinished;

  @override
  State<ZigzagEnterOverlay> createState() => _ZigzagEnterOverlayState();
}

class _ZigzagEnterOverlayState extends State<ZigzagEnterOverlay>
    with SingleTickerProviderStateMixin {
  bool _lightningFinished = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final double yDiv = size.height - 370;
    final double xTop = size.width * 0.44;
    final double xBot = size.width * 0.48;
    const double sw = 40.0;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          if (_lightningFinished)
            Stack(
              children: [
                for (int i = 1; i <= 4; i++)
                  ClipPath(
                    clipper: ReadyQuadrantClipper(
                      quadrant: i,
                      yDivisor: yDiv,
                      xTopBase: xTop,
                      xBottomBase: xBot,
                      slantedWidth: sw,
                    ),
                    child: Container(color: Colors.black),
                  )
                      .animate()
                      .fadeIn(duration: 100.ms)
                      .slideX(
                        begin: (i == 1 || i == 3) ? -1.0 : 1.0,
                        end: 0,
                        duration: 450.ms,
                        curve: Curves.easeOutCubic,
                      ),
              ],
            ),

          Positioned.fill(
            child: LightningDivisor(
              segments: [
                (Offset(xTop + sw, 0), Offset(xTop, yDiv)),
                (Offset(xTop, yDiv), Offset(xBot + sw, yDiv)),
                (Offset(xBot + sw, yDiv), Offset(xBot, size.height)),
              ],
              thickness: 5.0,
              entranceDuration: const Duration(milliseconds: 380),
              onEntranceFinished: () {
                if (!_lightningFinished) {
                  setState(() => _lightningFinished = true);
                  widget.onFinished?.call();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

