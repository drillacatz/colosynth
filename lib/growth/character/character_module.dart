import 'package:colosynth/database/character/character_save.dart';
import 'package:colosynth/growth/character/character_progression.dart';

class CharStatBlock {
  final int atk;
  final int hp;

  const CharStatBlock({required this.atk, required this.hp});
}

class CharacterModule {

  /// Breakthrough multiplier per spec §14.4:
  /// 3★ default → ×1.00, 4★ (1 breakthrough) → ×1.10, 5★ (2 breakthroughs) → ×1.20
  static double breakthroughMult(int stars) =>
      stars >= 2 ? 1.20 : stars == 1 ? 1.10 : 1.0;

  static CharStatBlock resolveStats(CharacterSave save) {
    final mult = breakthroughMult(save.breakthroughCount);
    return CharStatBlock(
      atk: (CharacterProgression.calculateAtk(save.level) * mult).round(),
      hp:  (CharacterProgression.calculateHp(save.level) * mult).round(),
    );
  }

  static ({CharacterSave save, bool leveledUp}) applyExpBook(
      CharacterSave save, int expGain) {
    final newXp = (save.xp + expGain).clamp(0, CharacterProgression.maxXp);
    final newLevel = CharacterProgression.calcLevel(newXp);
    final leveledUp = newLevel > save.level;
    return (
      save: save.copyWith(xp: newXp, level: newLevel),
      leveledUp: leveledUp,
    );
  }

  static CharacterSave applyBreakthrough(CharacterSave save) {
    if (save.breakthroughCount >= 2) return save;
    return save.copyWith(breakthroughCount: save.breakthroughCount + 1);
  }
}
