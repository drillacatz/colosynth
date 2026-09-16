class CharacterProgression {
  static const int maxLevel = 99;
  static const int maxXp = 99999;


  static int calculateHp(int level) {
    final safeLevel = level.clamp(1, maxLevel);
    final x = (safeLevel - 1).toDouble();
    return (3.0358 * x * x + 109.63 * x + 100).round();
  }


  static int calculateAtk(int level) {
    final safeLevel = level.clamp(1, maxLevel);
    final x = (safeLevel - 1).toDouble();
    return (0.3806 * x * x + 3.3099 * x + 20).round();
  }


  static int calcLevel(int xp) =>
      (xp * 98 ~/ maxXp + 1).clamp(1, maxLevel);


  static int calcXpRequired(int level) =>
      (maxXp * (level - 1) ~/ 98);
}
