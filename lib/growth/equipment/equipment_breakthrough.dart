class EquipmentBreakthrough {
  static int maxLevelFor(int breakthroughCount) {
    return 99;
  }

  static bool canBreakthrough(int currentLevel, int currentBreakthroughCount) {
    if (currentBreakthroughCount >= 2) return false;
    return currentLevel >= 99;
  }

  static int paintCost(int currentBreakthroughCount) {
    return (currentBreakthroughCount + 1) * 10;
  }

  static int newMaxLevel(int currentBreakthroughCount) {
    return 99;
  }
}
