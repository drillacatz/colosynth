import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:colosynth/game/app_shell/battle_models.dart';
import 'package:colosynth/game/logic/battle_constants.dart';
import 'package:colosynth/game/logic/direction.dart';
import 'package:colosynth/game/components/particle_utils.dart';

class CombatInputHandler extends PositionComponent
    with DragCallbacks, HasGameReference<BattleWorld> {
  final BattleWorld world;

  bool get isCounterWindowActive => world.fsm.isInCounterWindow;

  static const double _swipeVelocityThreshold = InputConstants.swipeVelocityThreshold;
  static const double _minSwipeDistance = InputConstants.minSwipeDistance;

  double _dragStartX = 0;
  double _dragStartY = 0;
  double _dragEndX = 0;
  double _dragEndY = 0;
  bool _dragActive = false;

  final math.Random _random = math.Random();

  static final _trailPaint = Paint()
    ..color = const Color(0xFF4A90D9).withValues(alpha: 0.6);

  static final _swipePaint = Paint()
    ..color = const Color(0xFF4A90D9).withValues(alpha: 0.9);

  CombatInputHandler({required this.world})
      : super(
          size: Vector2(480, 854),
          position: Vector2.zero(),
          priority: 100,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = game.size;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (world.fsm.isBattleOver) return;
    _dragStartX = event.localPosition.x;
    _dragStartY = event.localPosition.y;
    _dragEndX = _dragStartX;
    _dragEndY = _dragStartY;
    _dragActive = true;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (!_dragActive) return;
    _spawnTrailParticles(Vector2(_dragEndX, _dragEndY), event.localEndPosition);
    _dragEndX = event.localEndPosition.x;
    _dragEndY = event.localEndPosition.y;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (!_dragActive) return;
    _dragActive = false;

    final vx = event.velocity.x;
    final vy = event.velocity.y;
    final speed = vx.abs() > vy.abs() ? vx.abs() : vy.abs();

    final totalDx = _dragEndX - _dragStartX;
    final totalDy = _dragEndY - _dragStartY;
    final dragDist = math.sqrt(totalDx * totalDx + totalDy * totalDy);

    if (speed >= _swipeVelocityThreshold && dragDist >= _minSwipeDistance) {
      final dx = vx != 0 ? vx : totalDx;
      final dy = vy != 0 ? vy : totalDy;
      _onSwipe(dx, dy);
    }
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _dragActive = false;
  }

  void _spawnTrailParticles(Vector2 start, Vector2 end) {
    final distance = start.distanceTo(end);
    if (distance < 1) return;

    final int count = (distance / 5).clamp(1, 10).toInt();
    final dir = (end - start).normalized();

    world.add(
      AutoRemovingParticleComponent(
        particle: Particle.generate(
          count: count,
          lifespan: 0.25,
          generator: (i) {
            final progress = i / count;
            final pos = start + dir * (distance * progress);
            return TranslatedParticle(
              offset: pos,
              child: AcceleratedParticle(
                speed: Vector2(_random.nextDouble() * 20 - 10,
                    _random.nextDouble() * 20 - 10),
                child: CircleParticle(
                  radius: 1.5 + _random.nextDouble() * 2.0,
                  paint: _trailPaint,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _spawnSwipeParticles(Vector2 start, Vector2 end) {
    final distance = start.distanceTo(end);
    final int count = (distance / 4).clamp(10, 40).toInt();
    final dir = (end - start).normalized();

    world.add(
      AutoRemovingParticleComponent(
        particle: Particle.generate(
          count: count,
          lifespan: 0.35,
          generator: (i) {
            final progress = i / count;
            final pos = start + dir * (distance * progress);
            return TranslatedParticle(
              offset: pos,
              child: AcceleratedParticle(
                speed: Vector2(_random.nextDouble() * 60 - 30,
                    _random.nextDouble() * 60 - 30),
                child: CircleParticle(
                  radius: 2.0 + _random.nextDouble() * 3.0,
                  paint: _swipePaint,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _onSwipe(double dx, double dy) {
    final direction = swipeToDirection(dx, dy);
    _spawnSwipeParticles(
        Vector2(_dragStartX, _dragStartY), Vector2(_dragEndX, _dragEndY));
    world.onPlayerSwipe(direction);
  }
}
