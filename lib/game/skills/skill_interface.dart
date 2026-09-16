import 'package:flame/game.dart' show Game;

abstract class CharacterSkillImpl {
  String get id;
  bool get isPassive;

  void onActivate(covariant Game game);
  void onPassiveTick(covariant Game game, double dt);
  void onParry(covariant Game game) {}
  void onHit(covariant Game game) {}
  void onHurt(covariant Game game) {}
  void onVictory(covariant Game game) {}
  void reset() {}
}
