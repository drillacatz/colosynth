import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/particles.dart';

import 'package:colosynth/game/logic/direction.dart';
import 'package:colosynth/game_settings.dart';
import 'package:colosynth/services/audio_service.dart';

import 'package:colosynth/game/components/particle_utils.dart';

class SlashEffect extends PositionComponent {
  final AttackDirection direction;
  final bool isPlayerAttack;
  final bool isFullDamage;

  static const double _totalDuration = 0.42;
  static const double _fadeInEnd = 0.14;

  late final double _baseAngle;

  final Paint _bladePaint = Paint()..style = PaintingStyle.fill;
  final Paint _edgePaint  = Paint()..style = PaintingStyle.fill;
  final Paint _glowPaint  = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.butt
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
  final Paint _corePaint  = Paint()..style = PaintingStyle.fill;

  final Path _cachedBladePath = Path();
  final Path _cachedEdgePath = Path();

  double _elapsed = 0.0;
  bool _burstSpawned = false;
  static final math.Random _rng = math.Random();

  SlashEffect({
    required Vector2 worldPosition,
    required this.direction,
    this.isPlayerAttack = true,
    this.isFullDamage = true,
    int renderPriority = 25,
  }) : super(
          position: worldPosition,
          anchor: Anchor.center,
          priority: renderPriority,
        );

  @override
  Future<void> onLoad() async {
    _baseAngle = _dirToAngle(direction);
    AudioService.instance.playSfx(SfxEvent.slash);
  }

  @override
  void update(double dt) {
    _elapsed += dt;

    if (!_burstSpawned && _elapsed > 0.016) {
      if (isFullDamage) _spawnBurst();
      _burstSpawned = true;
    }

    if (_elapsed >= _totalDuration) removeFromParent();
  }

  void _buildBladePathRotatedTo(Path path, double halfLen, double halfWidth) {
    path.reset();
    final ax = -halfLen; final ay = 0.0;
    final bx = halfLen; final by = 0.0;
    final px = 0.0; final py = -halfWidth;

    final ctrlFrac = 0.28;
    final cx = (bx - ax) * ctrlFrac; final cy = 0.0;

    path.moveTo(ax, ay);
    path.cubicTo(
      ax + cx + px, ay + cy + py,
      bx - cx + px, by - cy + py,
      bx, by,
    );
    path.cubicTo(
      bx - cx - px, by - cy - py,
      ax + cx - px, ay + cy - py,
      ax, ay,
    );
    path.close();
  }

  @override
  void render(Canvas canvas) {
    final t = (_elapsed / _totalDuration).clamp(0.0, 1.0);

    final double alpha;
    if (t < _fadeInEnd) {
      alpha = t / _fadeInEnd;
    } else {
      alpha = 1.0 - (t - _fadeInEnd) / (1.0 - _fadeInEnd);
    }
    final a = alpha.clamp(0.0, 1.0);


    final double maxHalf = isFullDamage ? 13.0 : 5.5;
    final double minHalf = isFullDamage ? 1.5 : 0.6;
    final halfW = (maxHalf * (1.0 - t * 0.78)).clamp(minHalf, maxHalf);

    final alphaMult = isFullDamage ? 1.0 : 0.55;
    final baseA = (a * alphaMult).clamp(0.0, 1.0);

    canvas.save();
    canvas.rotate(_baseAngle);

    final halfLen = isFullDamage ? 130.0 : 72.0;
    final startOffset = Offset(-halfLen, 0);
    final endOffset = Offset(halfLen, 0);


    if (isFullDamage) {
      final glowC = isPlayerAttack
          ? Color.fromARGB((baseA * 70).round(), 0xFF, 0x00, 0x00)
          : Color.fromARGB((baseA * 70).round(), 0xFF, 0x00, 0x55);
      _glowPaint
        ..strokeWidth = halfW * 4.5
        ..color = glowC;
      canvas.drawLine(startOffset, endOffset, _glowPaint);
    }


    _buildBladePathRotatedTo(_cachedBladePath, halfLen, halfW);


    _bladePaint.shader = Gradient.linear(
      startOffset,
      endOffset,
      isPlayerAttack
          ? [
              Color.fromARGB((baseA * 180).round(), 0xAA, 0x00, 0x00),
              Color.fromARGB((baseA * 255).round(), 0xFF, 0x22, 0x22),
              Color.fromARGB((baseA * 255).round(), 0xFF, 0x44, 0x22),
              Color.fromARGB((baseA * 255).round(), 0xFF, 0x22, 0x22),
              Color.fromARGB((baseA * 180).round(), 0xAA, 0x00, 0x00),
            ]
          : [
              Color.fromARGB((baseA * 180).round(), 0x88, 0x00, 0x22),
              Color.fromARGB((baseA * 255).round(), 0xFF, 0x00, 0x44),
              Color.fromARGB((baseA * 255).round(), 0xFF, 0x00, 0x66),
              Color.fromARGB((baseA * 255).round(), 0xFF, 0x00, 0x44),
              Color.fromARGB((baseA * 180).round(), 0x88, 0x00, 0x22),
            ],
      const [0.0, 0.2, 0.5, 0.8, 1.0],
    );
    canvas.drawPath(_cachedBladePath, _bladePaint);


    _buildBladePathRotatedTo(_cachedEdgePath, halfLen, halfW * (isFullDamage ? 0.18 : 0.22));
    _edgePaint.shader = Gradient.linear(
      startOffset,
      endOffset,
      [
        Color.fromARGB((baseA * 0).round(), 0xFF, 0xFF, 0xFF),
        Color.fromARGB((baseA * 220).round(), 0xFF, 0xFF, 0xFF),
        Color.fromARGB((baseA * 255).round(), 0xFF, 0xEE, 0xCC),
        Color.fromARGB((baseA * 220).round(), 0xFF, 0xFF, 0xFF),
        Color.fromARGB((baseA * 0).round(), 0xFF, 0xFF, 0xFF),
      ],
      const [0.0, 0.12, 0.5, 0.88, 1.0],
    );

    canvas.save();
    canvas.translate(0, -halfW * 0.45);
    canvas.drawPath(_cachedEdgePath, _edgePaint);
    canvas.restore();


    if (isFullDamage && t < 0.35) {
      final progress = 1.0 - t / 0.35;
      final outerA = (baseA * 130 * progress).round().clamp(0, 255);
      final coreA  = (baseA * 255 * progress).round().clamp(0, 255);

      _corePaint.color = isPlayerAttack
          ? Color.fromARGB(outerA, 0xFF, 0x40, 0x00)
          : Color.fromARGB(outerA, 0xFF, 0x00, 0x66);
      canvas.drawCircle(Offset.zero, halfW * 1.8 * progress, _corePaint);

      _corePaint.color = Color.fromARGB(coreA, 0xFF, 0xFF, 0xFF);
      canvas.drawCircle(Offset.zero, halfW * 0.7 * progress, _corePaint);
    }

    canvas.restore();
  }


  void _spawnBurst() {
    if (parent == null) return;

    final baseAngle = _dirToAngle(direction);



    parent!.add(
      AutoRemovingParticleComponent(
        position: position.clone(),
        priority: priority - 1,
        particle: _buildStreakParticles(baseAngle),
      ),
    );


    parent!.add(
      AutoRemovingParticleComponent(
        position: position.clone(),
        priority: priority - 2,
        particle: _buildEmbers(baseAngle),
      ),
    );


    parent!.add(
      AutoRemovingParticleComponent(
        position: position.clone(),
        priority: priority - 3,
        particle: _buildHaze(baseAngle),
      ),
    );
  }


  Particle _buildStreakParticles(double baseAngle) {
    final colors = isPlayerAttack
        ? const [
            Color(0xFFFF2222),
            Color(0xFFFF4444),
            Color(0xFFFF6633),
            Color(0xFFFFAA44),
            Color(0xFFFFFFCC),
          ]
        : const [
            Color(0xFFCC0033),
            Color(0xFFFF0044),
            Color(0xFFFF2266),
            Color(0xFFFF44AA),
            Color(0xFFFFCCEE),
          ];

    return Particle.generate(
      count: 28,
      lifespan: 0.38,
      generator: (i) {

        final spread = math.pi * 35 / 180;
        final pAngle = baseAngle + (_rng.nextDouble() * 2 - 1) * spread;
        final speed = 160.0 + _rng.nextDouble() * 280.0;
        final length = 4.0 + _rng.nextDouble() * 10.0;
        final color = colors[_rng.nextInt(colors.length)];

        return AcceleratedParticle(
          speed: Vector2(math.cos(pAngle) * speed, math.sin(pAngle) * speed),
          acceleration: Vector2(0, 80),
          child: _StreakParticle(
            angle: pAngle,
            length: length,
            color: color,
          ),
        );
      },
    );
  }


  Particle _buildEmbers(double baseAngle) {
    final coreColor = isPlayerAttack
        ? const Color(0xFFFFFF88)
        : const Color(0xFFFFCCFF);
    final paint = Paint()..color = coreColor;

    return Particle.generate(
      count: 18,
      lifespan: 0.28,
      generator: (i) {
        final pAngle = baseAngle + (_rng.nextDouble() * 2 - 1) * (math.pi * 0.5);
        final speed = 80.0 + _rng.nextDouble() * 160.0;
        return AcceleratedParticle(
          speed: Vector2(math.cos(pAngle) * speed, math.sin(pAngle) * speed),
          acceleration: Vector2(0, 120),
          child: CircleParticle(
            radius: 1.0 + _rng.nextDouble() * 2.0,
            paint: paint,
          ),
        );
      },
    );
  }


  Particle _buildHaze(double baseAngle) {
    final hazeColor = Paint()
      ..color = isPlayerAttack ? const Color(0x44FF0000) : const Color(0x44FF0044);

    return Particle.generate(
      count: 14,
      lifespan: 0.50,
      generator: (i) {
        final pAngle = baseAngle + (_rng.nextDouble() * 2 - 1) * math.pi;
        final speed = 25.0 + _rng.nextDouble() * 60.0;
        return AcceleratedParticle(
          speed: Vector2(math.cos(pAngle) * speed, math.sin(pAngle) * speed),
          acceleration: Vector2(0, 40),
          child: CircleParticle(
            radius: 6.0 + _rng.nextDouble() * 9.0,
            paint: hazeColor,
          ),
        );
      },
    );
  }

  static double _dirToAngle(AttackDirection dir) => switch (dir) {
        AttackDirection.e  => 0.0,
        AttackDirection.se => math.pi / 4,
        AttackDirection.s  => math.pi / 2,
        AttackDirection.sw => math.pi * 3 / 4,
        AttackDirection.w  => math.pi,
        AttackDirection.nw => -(math.pi * 3 / 4),
        AttackDirection.n  => -(math.pi / 2),
        AttackDirection.ne => -(math.pi / 4),
      };
}





class _StreakParticle extends Particle {
  final double angle;
  final double length;
  final Color color;

  _StreakParticle({
    required this.angle,
    required this.length,
    required this.color,
  });

  static final Paint _streakPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.butt;

  @override
  void render(Canvas canvas) {
    final life = 1.0 - progress;
    final a = (life * 255).round().clamp(0, 255);
    if (a == 0) return;

    _streakPaint
      ..color = color.withAlpha(a)
      ..strokeWidth = (0.5 + life * 2.5).clamp(0.5, 3.0);

    final halfLen = length * 0.5 * (0.4 + life * 0.6);
    canvas.save();
    canvas.rotate(angle);
    canvas.drawLine(Offset(-halfLen, 0), Offset(halfLen, 0), _streakPaint);
    canvas.restore();
  }
}
