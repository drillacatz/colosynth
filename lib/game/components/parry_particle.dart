import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/particles.dart';

import 'package:colosynth/game/components/particle_utils.dart';

final math.Random _parryRng = math.Random();

void spawnParryParticles(Component parent, Vector2 origin) {
  parent
    ..add(_ParryFlash(position: origin.clone()))
    ..add(_ParryRing(position: origin.clone()))
    ..add(AutoRemovingParticleComponent(
      position: origin.clone(),
      priority: 36,
      particle: _buildMainSparks(_parryRng),
    ))
    ..add(AutoRemovingParticleComponent(
      position: origin.clone(),
      priority: 35,
      particle: _buildFastSparks(_parryRng),
    ));
}

final List<Paint> _mainPaints = [
  const Color(0xFFFFFFFF),
  const Color(0xFFFFFFA0),
  const Color(0xFFFFEC60),
  const Color(0xFF00E5FF),
  const Color(0xFFFFA500),
  const Color(0xFFFF8C00),
].map((c) => Paint()..color = c.withValues(alpha: 0.95)).toList();

final Paint _fastPaint = Paint()
  ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.92);

Particle _buildMainSparks(math.Random rng) {
  return Particle.generate(
    count: 72,
    lifespan: 0.52,
    generator: (i) {
      final biased = i < 42;
      final baseAngle = biased
          ? (rng.nextBool() ? 0.0 : math.pi) +
              (rng.nextDouble() - 0.5) * (math.pi * 0.45)
          : rng.nextDouble() * math.pi * 2;
      final speed = biased
          ? 170.0 + rng.nextDouble() * 310.0
          : 55.0 + rng.nextDouble() * 140.0;
      return AcceleratedParticle(
        speed: Vector2(
          math.cos(baseAngle) * speed,
          math.sin(baseAngle) * speed - 35.0,
        ),
        acceleration: Vector2(0, 420),
        child: CircleParticle(
          radius: 0.9 + rng.nextDouble() * 2.0,
          paint: _mainPaints[rng.nextInt(_mainPaints.length)],
        ),
      );
    },
  );
}

Particle _buildFastSparks(math.Random rng) {
  return Particle.generate(
    count: 34,
    lifespan: 0.26,
    generator: (i) {
      final angle = rng.nextDouble() * math.pi * 2;
      final speed = 330.0 + rng.nextDouble() * 380.0;
      return AcceleratedParticle(
        speed: Vector2(math.cos(angle) * speed, math.sin(angle) * speed),
        acceleration: Vector2(0, 230),
        child: CircleParticle(
          radius: 0.5 + rng.nextDouble() * 1.0,
          paint: _fastPaint,
        ),
      );
    },
  );
}

class _ParryFlash extends PositionComponent {
  static const double _duration = 0.20;
  static const double _peakFrac = 0.24;

  double _elapsed = 0.0;

  final Paint _bloomPaint = Paint();
  final Paint _streakPaint = Paint()
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  static final Shader _staticRadialShader = Gradient.radial(
    Offset.zero,
    1.0,
    [
      const Color(0xFFFFFFFF),
      const Color(0xFF00E5FF).withValues(alpha: 210 / 255),
      const Color(0xFFFFA000).withValues(alpha: 90 / 255),
      const Color(0x00FF6000),
    ],
    const [0.0, 0.22, 0.55, 1.0],
  );

  _ParryFlash({required Vector2 position})
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

    final bloomR = 58.0 + t * 28.0;
    _bloomPaint.shader = _staticRadialShader;
    _bloomPaint.color = const Color(0xFFFFFFFF).withValues(alpha: a);

    canvas.save();
    canvas.scale(bloomR);
    canvas.drawCircle(Offset.zero, 1.0, _bloomPaint);
    canvas.restore();

    final streakLen = 96.0 + t * 44.0;
    final sw = (3.5 * (1.0 - t * 0.65)).clamp(0.4, 3.5);
    final streakA = (a * 245 * 0.88).round().clamp(0, 255);

    _streakPaint
      ..strokeWidth = sw
      ..color = Color.fromARGB(streakA, 0xFF, 0xFF, 0xFF);
    canvas.drawLine(Offset(-streakLen, 0), Offset(streakLen, 0), _streakPaint);

    _streakPaint
      ..strokeWidth = sw * 0.55
      ..color = Color.fromARGB(
          (streakA * 0.62).round().clamp(0, 255), 0xFF, 0xFF, 0xFF);
    canvas.drawLine(Offset(0, -streakLen * 0.46), Offset(0, streakLen * 0.46),
        _streakPaint);

    final diagLen = streakLen * 0.52 / math.sqrt2;
    _streakPaint
      ..strokeWidth = sw * 0.40
      ..color = Color.fromARGB(
          (streakA * 0.42).round().clamp(0, 255), 0xFF, 0xD7, 0x00);
    canvas.drawLine(
        Offset(-diagLen, -diagLen), Offset(diagLen, diagLen), _streakPaint);
    canvas.drawLine(
        Offset(-diagLen, diagLen), Offset(diagLen, -diagLen), _streakPaint);
  }
}

class _ParryRing extends PositionComponent {
  static const double _duration = 0.52;
  static const double _startRadius = 5.0;
  static const double _maxRadius = 90.0;

  double _elapsed = 0.0;

  final Paint _ringPaint = Paint()..style = PaintingStyle.stroke;

  _ParryRing({required Vector2 position})
      : super(position: position, anchor: Anchor.center, priority: 60);

  @override
  void update(double dt) {
    _elapsed += dt;
    if (_elapsed >= _duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = (_elapsed / _duration).clamp(0.0, 1.0);
    final eased = 1.0 - math.pow(1.0 - t, 2.8).toDouble();
    final radius = _startRadius + (_maxRadius - _startRadius) * eased;
    final alpha = (1.0 - t) * (1.0 - t);
    final strokeW = (4.5 - 3.2 * t).clamp(0.4, 4.5);

    _ringPaint
      ..strokeWidth = strokeW
      ..color =
          Color.fromARGB((alpha * 225).round().clamp(0, 255), 0xFF, 0xD7, 0x00);
    canvas.drawCircle(Offset.zero, radius, _ringPaint);

    _ringPaint
      ..strokeWidth = strokeW * 0.34
      ..color =
          Color.fromARGB((alpha * 130).round().clamp(0, 255), 0xFF, 0xFF, 0xFF);
    canvas.drawCircle(Offset.zero, radius * 0.80, _ringPaint);
  }
}
