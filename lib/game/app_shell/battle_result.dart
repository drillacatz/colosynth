enum BattleOutcome { victory, defeat, quit }

class BattleResult {
  final BattleOutcome outcome;
  final double finalHpPercent;
  final int parryCount;
  final int dodgeCount;
  final int brokenCount;
  final int skillUseCount;
  final int score;
  final int inkEarned;
  final int paintEarned;
  final int xpEarned;

  const BattleResult({
    required this.outcome,
    required this.finalHpPercent,
    required this.parryCount,
    required this.dodgeCount,
    required this.brokenCount,
    required this.skillUseCount,
    required this.score,
    required this.inkEarned,
    required this.paintEarned,
    required this.xpEarned,
  });

  factory BattleResult.empty(BattleOutcome outcome) => BattleResult(
        outcome: outcome,
        finalHpPercent: 0,
        parryCount: 0,
        dodgeCount: 0,
        brokenCount: 0,
        skillUseCount: 0,
        score: 0,
        inkEarned: 0,
        paintEarned: 0,
        xpEarned: 0,
      );

  BattleResult copyWith({
    BattleOutcome? outcome,
    double? finalHpPercent,
    int? parryCount,
    int? dodgeCount,
    int? brokenCount,
    int? skillUseCount,
    int? score,
    int? inkEarned,
    int? paintEarned,
    int? xpEarned,
  }) =>
      BattleResult(
        outcome: outcome ?? this.outcome,
        finalHpPercent: finalHpPercent ?? this.finalHpPercent,
        parryCount: parryCount ?? this.parryCount,
        dodgeCount: dodgeCount ?? this.dodgeCount,
        brokenCount: brokenCount ?? this.brokenCount,
        skillUseCount: skillUseCount ?? this.skillUseCount,
        score: score ?? this.score,
        inkEarned: inkEarned ?? this.inkEarned,
        paintEarned: paintEarned ?? this.paintEarned,
        xpEarned: xpEarned ?? this.xpEarned,
      );
}
