class EquipmentProgression {
  static const int maxLevel = 99;

  static const Map<String, Map<String, int>> slotMaxStat = {
    'weapon': {'atk': 2145, 'hp': 0, 'def': 0, 'shield': 0},
    'shield': {'atk': 0, 'hp': 8570, 'def': 0, 'shield': 0},
    'armor': {'atk': 430, 'hp': 12000, 'def': 0, 'shield': 0},
    'helmet': {'atk': 425, 'hp': 9430, 'def': 0, 'shield': 0},
  };

  static double calculateMultiplier(int breakthroughCount, int level) {
    return (1.0 + breakthroughCount * 0.1) * (level - 1) / 98;
  }

  static int equipStatAtLevel(
    String slot,
    String statKey,
    int level, {
    int breakthroughCount = 0,
  }) {
    final baseMax = slotMaxStat[slot]?[statKey] ?? 0;
    if (baseMax == 0) return 0;
    final breakthroughMult = 1.0 + breakthroughCount * 0.1;
    return (baseMax * (level - 1) / 98 * breakthroughMult).round();
  }

  static int upgradeCost(int currentLevel) {
    return (currentLevel * 13).round();
  }

  static int breakthroughPaintCost(int nextBreakthroughCount) {
    if (nextBreakthroughCount == 1) return 20;
    if (nextBreakthroughCount == 2) return 30;
    return 9999;
  }

  static int breakthroughCost(int currentBreakthroughCount) {
    return breakthroughPaintCost(currentBreakthroughCount + 1);
  }

  static int requiredInkForLevel(int level) {
    int total = 0;
    for (int i = 1; i < level; i++) {
      total += upgradeCost(i);
    }
    return total;
  }

  static int levelCapForBreakthrough(int breakthroughCount) {
    if (breakthroughCount == 0) return 30;
    if (breakthroughCount == 1) return 60;
    return 99;
  }
}
