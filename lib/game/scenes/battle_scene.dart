import 'package:colosynth/services/sprite_repository.dart';

abstract class BattleScene {
  String get imagePath;
  void update(double dt);
  void dispose();
}

class PngBattleScene implements BattleScene {
  PngBattleScene(this.imagePath);

  @override
  final String imagePath;

  @override
  void update(double dt) {}

  @override
  void dispose() {}
}

abstract final class BattleSceneFactory {
  static BattleScene forTier(int tier) {
    return PngBattleScene(SpriteRepository.battleBackgroundForTier(tier));
  }
}

