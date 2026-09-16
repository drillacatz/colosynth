import 'package:flame/components.dart';



class AutoRemovingParticleComponent extends ParticleSystemComponent {
  AutoRemovingParticleComponent({
    required super.particle,
    super.position,
    super.priority,
  });

  @override
  void update(double dt) {
    super.update(dt);
    if (particle?.progress == null || particle!.progress >= 1.0) {
      removeFromParent();
    }
  }
}
