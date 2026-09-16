import 'package:flame/components.dart';
import 'package:colosynth/game/logic/direction.dart';
import 'package:colosynth/services/sprite_repository.dart';

enum DamageType {
  empty,
  normal,
  activeSkill,
}

enum CombatAnimation {
  idle,
  attack,
  block,
  dodge,
  hurt,
  parry,
  activeSkill,
  victory,
  defeat;
}

abstract interface class Combatant {
  int get currentHp;
  int get maxHp;
  int get currentStamina;
  int get maxStamina;
  int get def;
  bool get isGuarding;
  double get damageReduction;
  int get shield;
  bool get isDead;
  double get hpRatio;

  void takeDamage(int amount, DamageType type, {AttackDirection? direction});
  void heal(int amount);

  void restoreStamina(int amount);
  void drainStamina(int amount);

  void playAnimation(CombatAnimation anim);
}

class StateAnimationController {
  final String characterId;
  final Map<CombatAnimation, SpriteAnimation> _cache = {};
  SpriteAnimationComponent? _animComponent;
  CombatAnimation _current = CombatAnimation.idle;

  static const double _fps = 12.0;
  static const int _maxFrames = 24;

  StateAnimationController({required this.characterId});

  bool get hasAnimations => _cache.isNotEmpty;

  Future<SpriteAnimationComponent> load(Vector2 componentSize) async {
    for (final anim in CombatAnimation.values) {
      final frames = <Sprite>[];
      for (int i = 0; i < _maxFrames; i++) {
        try {
          final s = await Sprite.load(
            SpriteRepository.characterFrame(characterId, anim.name, i),
          );
          frames.add(s);
        } catch (_) {
          break;
        }
      }
      if (frames.isNotEmpty) {
        _cache[anim] = SpriteAnimation.spriteList(
          frames,
          stepTime: 1.0 / _fps,
          loop: _isLooping(anim),
        );
      }
    }

    _animComponent = SpriteAnimationComponent(
      animation: _cache[CombatAnimation.idle],
      size: componentSize,
      priority: 1,
    );
    return _animComponent!;
  }

  void play(CombatAnimation anim) {
    if (_current == anim) return;
    _current = anim;
    final animation = _cache[anim] ?? _cache[CombatAnimation.idle];
    if (animation != null && _animComponent != null) {
      _animComponent!.animation = animation;
    }
  }

  void dispose() {
    _cache.clear();
    _animComponent = null;
  }

  static bool _isLooping(CombatAnimation anim) => switch (anim) {
        CombatAnimation.idle || CombatAnimation.block => true,
        _ => false,
      };
}
