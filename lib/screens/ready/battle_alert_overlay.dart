import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;



class BattleAlertOverlay extends StatefulWidget {
  const BattleAlertOverlay({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<BattleAlertOverlay> createState() => _BattleAlertOverlayState();
}

class _BattleAlertOverlayState extends State<BattleAlertOverlay> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        widget.onFinished();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: AbsorbPointer(
        child: Stack(
          children: [

            Positioned.fill(
              child: Container(color: Colors.black.withValues(alpha: 0.6))
                  .animate()
                  .fadeIn(duration: 250.ms)
                  .then(delay: 1000.ms)
                  .fadeOut(duration: 250.ms),
            ),


            const Positioned.fill(child: _SpeedLines()),
          ],
        ),
      ),
    );
  }
}

class _SpeedLines extends StatefulWidget {
  const _SpeedLines();

  @override
  State<_SpeedLines> createState() => _SpeedLinesState();
}

class _SpeedLinesState extends State<_SpeedLines> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Line> _lines = [];
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..addListener(_updateLines)
      ..repeat();
  }

  void _updateLines() {
    if (!mounted) return;
    setState(() {

      if (_lines.length < 15 && _controller.value % 0.1 < 0.02) {
        _lines.add(_Line(
          start: Offset(500 + _random.nextDouble() * 500, -100),
          length: 200 + _random.nextDouble() * 400,
          speed: 15 + _random.nextDouble() * 20,
          opacity: 0.1 + _random.nextDouble() * 0.3,
        ));
      }
      

      for (int i = _lines.length - 1; i >= 0; i--) {
        _lines[i].offset += const Offset(-1, 0.8) * _lines[i].speed;
        if (_lines[i].offset.dx < -1000 || _lines[i].offset.dy > 1000) {
          _lines.removeAt(i);
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SpeedLinePainter(_lines),
    );
  }
}

class _Line {
  _Line({required this.start, required this.length, required this.speed, required this.opacity});
  final Offset start;
  Offset offset = Offset.zero;
  final double length;
  final double speed;
  final double opacity;
}

class _SpeedLinePainter extends CustomPainter {
  _SpeedLinePainter(this.lines);
  final List<_Line> lines;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (final line in lines) {
      paint.color = Colors.white.withValues(alpha: line.opacity);
      final p1 = line.start + line.offset;
      final p2 = p1 + const Offset(1, -0.8) * -line.length;
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
