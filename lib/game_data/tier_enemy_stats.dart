class TierEnemyStats {
  final int hp;
  final int atk;
  final int def;
  final double damageReduction;
  final int shield;
  final int stamina;

  const TierEnemyStats({
    required this.hp,
    required this.atk,
    this.def = 0,
    this.damageReduction = 0.0,
    required this.shield,
    this.stamina = 100,
  });

  static TierEnemyStats forTier(int tier) {
    switch (tier) {
      case 1:
        return const TierEnemyStats(hp: 60, atk: 10, def: 0, damageReduction: 0.0, shield: 0, stamina: 60);
      case 2:
        return const TierEnemyStats(hp: 300, atk: 40, def: 10, damageReduction: 0.02, shield: 10, stamina: 80);
      case 3:
        return const TierEnemyStats(hp: 800, atk: 80, def: 20, damageReduction: 0.04, shield: 20, stamina: 100);
      case 4:
        return const TierEnemyStats(hp: 2000, atk: 200, def: 50, damageReduction: 0.07, shield: 50, stamina: 120);
      case 5:
        return const TierEnemyStats(hp: 5000, atk: 450, def: 100, damageReduction: 0.10, shield: 100, stamina: 140);
      case 6:
        return const TierEnemyStats(hp: 10000, atk: 900, def: 200, damageReduction: 0.13, shield: 200, stamina: 160);
      case 7:
        return const TierEnemyStats(hp: 18000, atk: 1600, def: 350, damageReduction: 0.16, shield: 350, stamina: 180);
      case 8:
        return const TierEnemyStats(hp: 30000, atk: 2800, def: 500, damageReduction: 0.19, shield: 500, stamina: 200);
      case 9:
        return const TierEnemyStats(hp: 45000, atk: 4200, def: 700, damageReduction: 0.22, shield: 700, stamina: 220);
      case 10:
        return const TierEnemyStats(hp: 60000, atk: 6000, def: 900, damageReduction: 0.25, shield: 900, stamina: 250);
      case 11:
        return const TierEnemyStats(hp: 90000, atk: 9000, def: 1500, damageReduction: 0.30, shield: 1500, stamina: 300);
      default:
        return const TierEnemyStats(hp: 60, atk: 10, def: 0, damageReduction: 0.0, shield: 0, stamina: 60);
    }
  }

  /// Returns scaled stats based on the exact stage position within a tier.
  /// [stageWithinTier] is 1–12; boss (12) gets a 20% HP/ATK bonus.
  static TierEnemyStats forStage({required int tier, required int stageWithinTier}) {
    final base = forTier(tier);
    final isBoss = stageWithinTier == 12;
    final isElite = stageWithinTier >= 10;
    final hpMult = isBoss ? 1.2 : isElite ? 1.1 : 1.0;
    final atkMult = isBoss ? 1.15 : isElite ? 1.08 : 1.0;
    return TierEnemyStats(
      hp: (base.hp * hpMult).round(),
      atk: (base.atk * atkMult).round(),
      def: base.def,
      damageReduction: base.damageReduction,
      shield: base.shield,
      stamina: isBoss ? (base.stamina * 1.3).round() : base.stamina,
    );
  }
}

