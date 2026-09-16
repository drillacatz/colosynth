class SynthInstance {
  final String instanceId;
  final String definitionId;
  String? equippedCharacterId;
  int? slotIndex;
  final int unlockedAtMs;
  final int level;
  final int xp;

  SynthInstance({
    required this.instanceId,
    required this.definitionId,
    this.equippedCharacterId,
    this.slotIndex,
    required this.unlockedAtMs,
    this.level = 1,
    this.xp = 0,
  });

  Map<String, dynamic> toJson() => {
        'instanceId': instanceId,
        'definitionId': definitionId,
        'equippedCharacterId': equippedCharacterId,
        'slotIndex': slotIndex,
        'unlockedAtMs': unlockedAtMs,
        'level': level,
        'xp': xp,
      };

  factory SynthInstance.fromJson(Map<String, dynamic> json) {
    return SynthInstance(
      instanceId: json['instanceId'] as String,
      definitionId: json['definitionId'] as String,
      equippedCharacterId: json['equippedCharacterId'] as String?,
      slotIndex: json['slotIndex'] as int?,
      unlockedAtMs: json['unlockedAtMs'] as int,
      level: json['level'] as int? ?? 1,
      xp: json['xp'] as int? ?? 0,
    );
  }

  SynthInstance copyWith({
    String? instanceId,
    String? definitionId,
    String? Function()? equippedCharacterId,
    int? Function()? slotIndex,
    int? unlockedAtMs,
    int? level,
    int? xp,
  }) {
    return SynthInstance(
      instanceId: instanceId ?? this.instanceId,
      definitionId: definitionId ?? this.definitionId,
      equippedCharacterId: equippedCharacterId != null ? equippedCharacterId() : this.equippedCharacterId,
      slotIndex: slotIndex != null ? slotIndex() : this.slotIndex,
      unlockedAtMs: unlockedAtMs ?? this.unlockedAtMs,
      level: level ?? this.level,
      xp: xp ?? this.xp,
    );
  }
}
