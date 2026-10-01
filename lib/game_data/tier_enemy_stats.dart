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

  static const TierEnemyStats tutorial = TierEnemyStats(
    hp: 200,
    atk: 15,
    def: 0,
    damageReduction: 0.0,
    shield: 0,
    stamina: 30,
  );

  static TierEnemyStats forTier(int tier) {
    switch (tier) {
      case 0:
        return tutorial;
      case 1:
        return const TierEnemyStats(hp: 650, atk: 55, def: 10, damageReduction: 0.20, shield: 10, stamina: 60);
      case 2:
        return const TierEnemyStats(hp: 1500, atk: 180, def: 25, damageReduction: 0.25, shield: 25, stamina: 80);
      case 3:
        return const TierEnemyStats(hp: 3000, atk: 380, def: 50, damageReduction: 0.30, shield: 50, stamina: 100);
      case 4:
        return const TierEnemyStats(hp: 5200, atk: 700, def: 90, damageReduction: 0.35, shield: 90, stamina: 120);
      case 5:
        return const TierEnemyStats(hp: 8200, atk: 1150, def: 150, damageReduction: 0.40, shield: 150, stamina: 140);
      case 6:
        return const TierEnemyStats(hp: 12500, atk: 1800, def: 240, damageReduction: 0.42, shield: 240, stamina: 160);
      case 7:
        return const TierEnemyStats(hp: 18500, atk: 2800, def: 360, damageReduction: 0.45, shield: 360, stamina: 180);
      case 8:
        return const TierEnemyStats(hp: 27000, atk: 4200, def: 520, damageReduction: 0.48, shield: 520, stamina: 200);
      case 9:
        return const TierEnemyStats(hp: 39000, atk: 6000, def: 720, damageReduction: 0.50, shield: 720, stamina: 220);
      case 10:
        return const TierEnemyStats(hp: 54000, atk: 8200, def: 980, damageReduction: 0.52, shield: 980, stamina: 250);
      case 11:
        return const TierEnemyStats(hp: 75000, atk: 11000, def: 1400, damageReduction: 0.55, shield: 1400, stamina: 300);
      default:
        return const TierEnemyStats(hp: 650, atk: 55, def: 10, damageReduction: 0.20, shield: 10, stamina: 60);
    }
  }

  /// Returns scaled stats based on the exact stage position within a tier or boss flag.
  /// [stageWithinTier] is 1–12; boss (12 or isBoss) gets 50% HP bonus (requiring ~5 staggers),
  /// +15% ATK, and +30% stamina.
  static TierEnemyStats forStage({
    required int tier,
    required int stageWithinTier,
    bool isBoss = false,
  }) {
    final base = forTier(tier);
    final bossEncounter = isBoss || stageWithinTier == 12;
    final isElite = stageWithinTier >= 10 && !bossEncounter;
    final hpMult = bossEncounter ? 1.50 : isElite ? 1.15 : 1.0;
    final atkMult = bossEncounter ? 1.15 : isElite ? 1.08 : 1.0;
    return TierEnemyStats(
      hp: (base.hp * hpMult).round(),
      atk: (base.atk * atkMult).round(),
      def: base.def,
      damageReduction: base.damageReduction,
      shield: base.shield,
      stamina: bossEncounter ? (base.stamina * 1.3).round() : base.stamina,
    );
  }
}

