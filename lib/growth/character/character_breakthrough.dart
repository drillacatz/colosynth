class CharacterBreakthrough {
  static bool canBreakthrough(int currentLevel, int currentStars) {
    if (currentStars >= 5) return false;
    if (currentStars == 3 && currentLevel >= 40) return true;
    if (currentStars == 4 && currentLevel >= 60) return true;
    return false;
  }

  static int breakthroughCost(int currentStars) {
    if (currentStars == 3) return 1000;
    if (currentStars == 4) return 2500;
    return 0;
  }

  static int synthSlotsForStars(int stars, int accountLevel) {
    int slots = 2;
    if (stars >= 4) slots++;
    if (stars >= 5) slots++;

    return slots.clamp(2, 4);
  }
}
