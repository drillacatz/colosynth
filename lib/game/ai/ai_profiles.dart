

class AiProfile {
  final String id;
  final double telegraphDuration;
  final double attackInterval;
  final double blockProbability;
  final double dodgeProbability;
  final double comboProbability;
  final double unblockableRate;
  final bool activeSkillEnabled;

  final double bpm;

  final int staminaMax;

  const AiProfile({
    required this.id,
    required this.telegraphDuration,
    required this.attackInterval,
    required this.blockProbability,
    required this.dodgeProbability,
    required this.comboProbability,
    this.unblockableRate = 0.0,
    required this.activeSkillEnabled,
    required this.bpm,
    required this.staminaMax,
  });

  String get name => id;

  static AiProfile easy() => const AiProfile(
        id: 'easy',
        telegraphDuration: 1.2,
        attackInterval: 2.0,
        blockProbability: 0.20,
        dodgeProbability: 0.00,
        comboProbability: 0.00,
        unblockableRate: 0.00,
        activeSkillEnabled: false,
        bpm: 120,
        staminaMax: 100,
      );

  static AiProfile medium() => const AiProfile(
        id: 'medium',
        telegraphDuration: 0.9,
        attackInterval: 1.5,
        blockProbability: 0.45,
        dodgeProbability: 0.15,
        comboProbability: 0.20,
        unblockableRate: 0.00,
        activeSkillEnabled: false,
        bpm: 130,
        staminaMax: 150,
      );

  static AiProfile hard() => const AiProfile(
        id: 'hard',
        telegraphDuration: 0.65,
        attackInterval: 1.1,
        blockProbability: 0.65,
        dodgeProbability: 0.35,
        comboProbability: 0.50,
        unblockableRate: 0.15,
        activeSkillEnabled: true,
        bpm: 140,
        staminaMax: 200,
      );

  static AiProfile extreme() => const AiProfile(
        id: 'extreme',
        telegraphDuration: 0.5,
        attackInterval: 0.8,
        blockProbability: 0.80,
        dodgeProbability: 0.50,
        comboProbability: 0.70,
        unblockableRate: 0.35,
        activeSkillEnabled: true,
        bpm: 140,
        staminaMax: 250,
      );



  static AiProfile forTier(int tier) {
    if (tier <= 3) return easy();
    if (tier <= 6) return medium();
    if (tier <= 10) return hard();
    return extreme();
  }

  static AiProfile fromId(String id) => switch (id) {
        'easy'    => easy(),
        'medium'  => medium(),
        'hard'    => hard(),
        'extreme' => extreme(),
        _         => easy(),
      };
}
