class CharacterEquipmentSlot {
  final int level;
  final int xp;
  final int breakthroughCount;

  const CharacterEquipmentSlot({
    required this.level,
    required this.xp,
    required this.breakthroughCount,
  });

  factory CharacterEquipmentSlot.fromJson(Map<String, dynamic> json) {
    return CharacterEquipmentSlot(
      level: json['level'] as int? ?? 1,
      xp: json['xp'] as int? ?? 0,
      breakthroughCount: json['breakthroughCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'level': level,
    'xp': xp,
    'breakthroughCount': breakthroughCount,
  };

  CharacterEquipmentSlot copyWith({
    int? level,
    int? xp,
    int? breakthroughCount,
  }) {
    return CharacterEquipmentSlot(
      level: level ?? this.level,
      xp: xp ?? this.xp,
      breakthroughCount: breakthroughCount ?? this.breakthroughCount,
    );
  }

  int get maxLevel => 99;
  double get breakthroughStatMult => 1.0 + breakthroughCount * 0.1;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CharacterEquipmentSlot &&
          runtimeType == other.runtimeType &&
          level == other.level &&
          xp == other.xp &&
          breakthroughCount == other.breakthroughCount;

  @override
  int get hashCode => Object.hash(level, xp, breakthroughCount);
}
