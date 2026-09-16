import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/particles.dart';

import 'package:colosynth/game/components/particle_utils.dart';



final math.Random _dodgeRng = math.Random();

void spawnDodgeEffect(Component parent, Vector2 origin) {
  parent
    ..add(_DodgeRing(position: origin.clone()))
    ..add(_DodgeCross(position: origin.clone()))
    ..add(AutoRemovingParticleComponent(
      position: origin.clone(),
      priority: 36,
      particle: _buildDodgeSparks(_dodgeRng),
    ));
}



class _DodgeRing extends PositionComponent {
  static const double _duration = 0.45;
  static const double _startRadius = 8.0;
  static const double _maxRadius = 72.0;

  double _elapsed = 0.0;

  final Paint _ringPaint = Paint()..style = PaintingStyle.stroke;
  final Paint _glowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

  _DodgeRing({required Vector2 position})
      : super(position: position, anchor: Anchor.center, priority: 60);

  @override
  void update(double dt) {
    _elapsed += dt;
    if (_elapsed >= _duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = (_elapsed / _duration).clamp(0.0, 1.0);
    final eased = 1.0 - math.pow(1.0 - t, 3.0).toDouble();
    final radius = _startRadius + (_maxRadius - _startRadius) * eased;
    final alpha = (1.0 - t) * (1.0 - t);
    final strokeW = (3.8 - 2.8 * t).clamp(0.4, 3.8);


    _glowPaint
      ..strokeWidth = strokeW * 2.2
      ..color =
          Color.fromARGB((alpha * 80).round().clamp(0, 255), 0xFF, 0xFF, 0xFF);
    canvas.drawCircle(Offset.zero, radius, _glowPaint);


    _ringPaint
      ..strokeWidth = strokeW
      ..color = Color.fromARGB(
          (alpha * 220).round().clamp(0, 255), 0xFF, 0xFF, 0xFF);
    canvas.drawCircle(Offset.zero, radius, _ringPaint);


    _ringPaint
      ..strokeWidth = strokeW * 0.3
      ..color = Color.fromARGB(
          (alpha * 100).round().clamp(0, 255), 0xCC, 0xDD, 0xFF);
    canvas.drawCircle(Offset.zero, radius * 0.75, _ringPaint);
  }
}



class _DodgeCross extends PositionComponent {
  static const double _duration = 0.35;
  static const double _peakFrac = 0.20;

  double _elapsed = 0.0;

  final Paint _strokePaint = Paint()
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  final Paint _glowPaint = Paint()
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

  _DodgeCross({required Vector2 position})
      : super(position: position, anchor: Anchor.center, priority: 62);

  @override
  void update(double dt) {
    _elapsed += dt;
    if (_elapsed >= _duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = (_elapsed / _duration).clamp(0.0, 1.0);


    final double alpha = t <= _peakFrac
        ? t / _peakFrac
        : 1.0 - (t - _peakFrac) / (1.0 - _peakFrac);
    final a = alpha.clamp(0.0, 1.0);


    final armLen = 38.0 + t * 30.0;
    final sw = (4.0 * (1.0 - t * 0.5)).clamp(0.5, 4.0);
    final aInt = (a * 240).round().clamp(0, 255);


    _glowPaint
      ..strokeWidth = sw * 2.4
      ..color = Color.fromARGB((aInt * 0.35).round().clamp(0, 255),
          0xFF, 0xFF, 0xFF);
    _drawCross(canvas, armLen, _glowPaint);


    _strokePaint
      ..strokeWidth = sw
      ..color = Color.fromARGB(aInt, 0xFF, 0xFF, 0xFF);
    _drawCross(canvas, armLen, _strokePaint);


    _strokePaint
      ..strokeWidth = sw * 0.45
      ..color = Color.fromARGB(
          (aInt * 0.5).round().clamp(0, 255), 0xBB, 0xDD, 0xFF);
    _drawCross(canvas, armLen * 0.65, _strokePaint);
  }

  void _drawCross(Canvas canvas, double armLen, Paint paint) {

    canvas.drawLine(
        Offset(-armLen, 0), Offset(armLen, 0), paint);

    canvas.drawLine(
        Offset(0, -armLen), Offset(0, armLen), paint);
  }
}



final List<Paint> _dodgePaints = [
  const Color(0xFFFFFFFF),
  const Color(0xFFDDEEFF),
  const Color(0xFFBBCCFF),
  const Color(0xFFAABBFF),
].map((c) => Paint()..color = c.withValues(alpha: 0.88)).toList();

Particle _buildDodgeSparks(math.Random rng) {
  return Particle.generate(
    count: 28,
    lifespan: 0.40,
    generator: (i) {
      final angle = rng.nextDouble() * math.pi * 2;
      final speed = 120.0 + rng.nextDouble() * 200.0;
      return AcceleratedParticle(
        speed: Vector2(
          math.cos(angle) * speed,
          math.sin(angle) * speed - 20.0,
        ),
        acceleration: Vector2(0, 280),
        child: CircleParticle(
          radius: 0.6 + rng.nextDouble() * 1.4,
          paint: _dodgePaints[rng.nextInt(_dodgePaints.length)],
        ),
      );
    },
  );
}
