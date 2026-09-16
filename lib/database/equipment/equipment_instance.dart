import 'package:colosynth/growth/equipment/equipment_breakthrough.dart';

class EquipmentInstance {
  final String instanceId;
  final String equipId;
  final String slot;
  final int level;
  final int xp;
  final int breakthroughCount;

  int get maxLevel =>
      EquipmentBreakthrough.maxLevelFor(breakthroughCount);

  const EquipmentInstance({
    required this.instanceId,
    required this.equipId,
    required this.slot,
    required this.level,
    required this.xp,
    required this.breakthroughCount,
  });

  EquipmentInstance copyWith({
    String? instanceId,
    String? equipId,
    String? slot,
    int? level,
    int? xp,
    int? breakthroughCount,
  }) {
    return EquipmentInstance(
      instanceId: instanceId ?? this.instanceId,
      equipId: equipId ?? this.equipId,
      slot: slot ?? this.slot,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      breakthroughCount: breakthroughCount ?? this.breakthroughCount,
    );
  }

  factory EquipmentInstance.fromJson(Map<String, dynamic> json) {
    return EquipmentInstance(
      instanceId: json['instanceId'] as String,
      equipId: json['equipId'] as String,
      slot: json['slot'] as String,
      level: json['level'] as int? ?? 1,
      xp: json['xp'] as int? ?? 0,
      breakthroughCount: json['breakthroughCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'instanceId': instanceId,
      'equipId': equipId,
      'slot': slot,
      'level': level,
      'xp': xp,
      'breakthroughCount': breakthroughCount,
    };
  }
}
