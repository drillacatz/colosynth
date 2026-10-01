import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import 'package:colosynth/game/components/particle_utils.dart';
import 'package:colosynth/game_settings.dart';
import 'package:colosynth/services/audio_service.dart';
import 'package:colosynth/services/sprite_repository.dart';

/// A high-impact 16-frame elemental SpriteAnimation component for skill impact VFX.
class SkillVfxComponent extends SpriteAnimationComponent {
  SkillVfxComponent({
    required this.archetype,
    required Vector2 worldPosition,
    double targetSize = 210.0,
    int renderPriority = 35,
  }) : super(
          position: worldPosition,
          size: Vector2.all(targetSize),
          anchor: Anchor.center,
          priority: renderPriority,
          removeOnFinish: true,
        );

  final String archetype;
  static final math.Random _rng = math.Random();

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // 1. Load the 4x4 16-frame sprite sheet
    final image = await Flame.images.load(SpriteRepository.skillVfx(archetype));
    animation = SpriteAnimation.fromFrameData(
      image,
      SpriteAnimationData.sequenced(
        amount: 16,
        stepTime: 0.025, // 16 * 25ms = 400ms total duration
        textureSize: Vector2(128, 128),
        loop: false,
      ),
    );

    // 2. Play impact audio
    if (archetype == 'slash') {
      AudioService.instance.playSfx(SfxEvent.slash);
    } else {
      AudioService.instance.playSfx(SfxEvent.activeskillCharged);
    }

    // 3. Spawn matching comic particle burst
    _spawnParticles();
  }

  void _spawnParticles() {
    final parentComp = parent;
    if (parentComp == null) return;

    final colors = _getParticleColors(archetype);
    final count = archetype == 'arcane_nuke' || archetype == 'fire_blast' ? 48 : 32;

    parentComp.add(
      AutoRemovingParticleComponent(
        position: position.clone(),
        priority: priority + 1,
        particle: Particle.generate(
          count: count,
          lifespan: 0.45,
          generator: (i) {
            final angle = _rng.nextDouble() * 2 * math.pi;
            final speed = 60.0 + _rng.nextDouble() * 180.0;
            final color = colors[_rng.nextInt(colors.length)];
            final radius = 2.0 + _rng.nextDouble() * 3.5;

            return AcceleratedParticle(
              speed: Vector2(math.cos(angle) * speed, math.sin(angle) * speed),
              acceleration: Vector2(0, 120),
              child: CircleParticle(
                radius: radius,
                paint: Paint()..color = color,
              ),
            );
          },
        ),
      ),
    );
  }

  static List<Color> _getParticleColors(String archetype) {
    switch (archetype) {
      case 'lightning':
        return [
          const Color(0xFF00FFFF),
          const Color(0xFF80FFFF),
          const Color(0xFFFFFFFF),
          const Color(0xFFFFEE55),
        ];
      case 'arcane_nuke':
        return [
          const Color(0xFF9900FF),
          const Color(0xFFE040FB),
          const Color(0xFFFFFFFF),
          const Color(0xFFFF4081),
        ];
      case 'fire_blast':
        return [
          const Color(0xFFFF3D00),
          const Color(0xFFFF9100),
          const Color(0xFFFFEA00),
          const Color(0xFFFFFFFF),
        ];
      case 'shield_barrier':
        return [
          const Color(0xFF00E5FF),
          const Color(0xFF2979FF),
          const Color(0xFFFFFFFF),
          const Color(0xFF00B0FF),
        ];
      case 'holy_light':
        return [
          const Color(0xFFFFD700),
          const Color(0xFFFFEA00),
          const Color(0xFFFFF9C4),
          const Color(0xFFFFFFFF),
        ];
      case 'slash':
      default:
        return [
          const Color(0xFFFFD700),
          const Color(0xFFFFF176),
          const Color(0xFFFFFFFF),
          const Color(0xFFFF6D00),
        ];
    }
  }
}
