import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:colosynth/game_settings.dart';
import 'package:colosynth/services/audio_service.dart';
import 'package:colosynth/screens/home/home_screen.dart';
import 'package:colosynth/screens/theme/background.dart';

class TitleScreen extends StatefulWidget {
  const TitleScreen({super.key});

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> {
  double _progress = 0.0;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _startLoading();
  }

  Future<void> _startLoading() async {
    setState(() => _progress = 0.88);

    unawaited(AudioService.instance.playBgm(BgmTrack.title));

    unawaited(_waitForInit());
  }

  Future<void> _waitForInit() async {
    if (!mounted) return;

    setState(() {
      _ready = true;
      _progress = 1.0;
    });

    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;
    unawaited(Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 600),
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
          child: child,
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFB),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _ComicStripesBackground(),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 5),
                const _GameTitle().animate().fadeIn(duration: 800.ms).scale(
                      begin: const Offset(0.85, 0.85),
                      duration: 1000.ms,
                      curve: Curves.easeOutBack,
                    ),
                const Spacer(flex: 6),
                _ProgressSection(progress: _progress, ready: _ready)
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 400.ms),
                const SizedBox(height: 52),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComicStripesBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: NotebookBackground()),
        Positioned(
          top: -100,
          left: -100,
          child: IgnorePointer(
            child: SizedBox(
              width: 360,
              height: 360,
              child: CustomPaint(
                painter: _GearPainter(
                  color: const Color(0xFF1A1A1A).withValues(alpha: 0.02),
                  teeth: 16,
                ),
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .rotate(begin: 0, end: 1, duration: 60.seconds),
        ),
        Positioned(
          bottom: -150,
          right: -150,
          child: IgnorePointer(
            child: SizedBox(
              width: 480,
              height: 480,
              child: CustomPaint(
                painter: _GearPainter(
                  color: const Color(0xFF1A1A1A).withValues(alpha: 0.015),
                  teeth: 22,
                ),
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .rotate(begin: 1, end: 0, duration: 80.seconds),
        ),
        const _SpeedLineParticles(),
      ],
    );
  }
}

class _SpeedLineParticles extends StatefulWidget {
  const _SpeedLineParticles();

  @override
  State<_SpeedLineParticles> createState() => _SpeedLineParticlesState();
}

class _SpeedLineParticlesState extends State<_SpeedLineParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final _random = math.Random();
  late final List<_LineParticle> _particles;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _particles = List.generate(16, (index) {
      return _LineParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        length: 50 + _random.nextDouble() * 90,
        speed: 0.012 + _random.nextDouble() * 0.02,
        opacity: 0.04 + _random.nextDouble() * 0.06,
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final size = MediaQuery.of(context).size;
        return CustomPaint(
          size: size,
          painter: _ParticlesPainter(_particles, _ctrl.value),
        );
      },
    );
  }
}

class _LineParticle {
  _LineParticle({
    required this.x,
    required this.y,
    required this.length,
    required this.speed,
    required this.opacity,
  });

  double x;
  double y;
  double length;
  double speed;
  double opacity;
}

class _ParticlesPainter extends CustomPainter {
  _ParticlesPainter(this.particles, this.progress);
  final List<_LineParticle> particles;
  final double progress;

  static final Paint _paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final double cx = (p.x - progress * p.speed * 100) % 1.2;
      final double cy = (p.y + progress * p.speed * 100) % 1.2;

      final double startX = cx * size.width;
      final double startY = cy * size.height;

      final double endX = startX - p.length * 0.86;
      final double endY = startY + p.length * 0.5;

      _paint.color = const Color(0xFF1A1A1A).withValues(alpha: p.opacity);
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), _paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _GameTitle extends StatelessWidget {
  const _GameTitle();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          'COLOSYNTH',
          style: TextStyle(
            color: const Color(0xFFFF3366).withValues(alpha: 0.9),
            fontSize: 60,
            fontWeight: FontWeight.w900,
            fontFamily: 'Bangers',
            letterSpacing: 9,
            height: 1.0,
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).slide(
              begin: const Offset(0.04, 0.04),
              end: const Offset(0.06, 0.06),
              duration: 1.8.seconds,
              curve: Curves.easeInOut,
            ),
        const Text(
          'COLOSYNTH',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 60,
            fontWeight: FontWeight.w900,
            fontFamily: 'Bangers',
            letterSpacing: 9,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({
    required this.progress,
    required this.ready,
  });

  final double progress;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 14,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF1A1A1A), width: 1.5),
            ),
            padding: const EdgeInsets.all(2),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                width: (MediaQuery.of(context).size.width - 100) * progress,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              ready ? 'ENTER THE ARENA' : 'INITIALIZING SUBSYSTEMS...',
              key: ValueKey(ready),
              style: const TextStyle(
                color: Color(0xFF888888),
                fontSize: 10,
                letterSpacing: 3,
                fontFamily: 'Bangers',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GearPainter extends CustomPainter {
  _GearPainter({required this.color, this.teeth = 12})
      : _fillPaint = Paint()
          ..color = color
          ..style = PaintingStyle.fill,
        _strokePaint = Paint()
          ..color = color.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

  final Color color;
  final int teeth;
  final Paint _fillPaint;
  final Paint _strokePaint;

  Size? _cachedSize;
  Path? _cachedPath;

  Path _getPath(Size size) {
    if (_cachedSize != size || _cachedPath == null) {
      _cachedSize = size;
      final cx = size.width / 2;
      final cy = size.height / 2;
      final outerR = math.min(size.width, size.height) / 2;
      final innerR = outerR * 0.70;
      final holeR = outerR * 0.26;
      final halfTooth = math.pi / teeth * 0.44;
      final gap = math.pi / teeth * 0.13;

      final path = Path()..fillType = PathFillType.evenOdd;
      for (int i = 0; i < teeth; i++) {
        final base = (math.pi * 2 * i) / teeth;
        final a1 = base - halfTooth;
        final a2 = base + halfTooth;
        final a3 = base + halfTooth + gap;
        final a4 = base + math.pi * 2 / teeth - halfTooth - gap;

        if (i == 0) {
          path.moveTo(
            cx + innerR * math.cos(a1),
            cy + innerR * math.sin(a1),
          );
        } else {
          path.lineTo(
            cx + innerR * math.cos(a1),
            cy + innerR * math.sin(a1),
          );
        }
        path.lineTo(cx + outerR * math.cos(a1), cy + outerR * math.sin(a1));
        path.lineTo(cx + outerR * math.cos(a2), cy + outerR * math.sin(a2));
        path.lineTo(cx + innerR * math.cos(a3), cy + innerR * math.sin(a3));
        path.lineTo(cx + innerR * math.cos(a4), cy + innerR * math.sin(a4));
      }
      path.close();

      path.addOval(
        Rect.fromCircle(center: Offset(cx, cy), radius: holeR),
      );
      _cachedPath = path;
    }
    return _cachedPath!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _getPath(size);
    canvas.drawPath(path, _fillPaint);
    canvas.drawPath(path, _strokePaint);
  }

  @override
  bool shouldRepaint(_GearPainter old) =>
      old.color != color || old.teeth != teeth;
}
