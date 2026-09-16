import 'package:colosynth/database/character/character_equipment_slot.dart';

class CharacterSave {
  final String charId;
  final int level;
  final int xp;
  final int breakthroughCount;
  final Map<String, CharacterEquipmentSlot> equipment;
  final List<String?> synthSlots;

  const CharacterSave({
    required this.charId,
    required this.level,
    required this.xp,
    required this.breakthroughCount,
    required this.equipment,
    required this.synthSlots,
  });

  CharacterSave copyWith({
    int? level,
    int? xp,
    int? breakthroughCount,
    Map<String, CharacterEquipmentSlot>? equipment,
    List<String?>? synthSlots,
  }) => CharacterSave(
    charId:             charId,
    level:              level             ?? this.level,
    xp:                 xp                ?? this.xp,
    breakthroughCount:  breakthroughCount  ?? this.breakthroughCount,
    equipment:          equipment         ?? this.equipment,
    synthSlots:         synthSlots        ?? this.synthSlots,
  );

  Map<String, dynamic> toProgressionFields() => {
    'char_${charId}_level': level,
    'char_${charId}_xp':    xp,
  };

  static CharacterSave empty(String charId) => CharacterSave(
    charId: charId,
    level: 1,
    xp: 0,
    breakthroughCount: 0,
    equipment: {
      'weapon': const CharacterEquipmentSlot(level: 1, xp: 0, breakthroughCount: 0),
      'shield': const CharacterEquipmentSlot(level: 1, xp: 0, breakthroughCount: 0),
      'armor': const CharacterEquipmentSlot(level: 1, xp: 0, breakthroughCount: 0),
      'helmet': const CharacterEquipmentSlot(level: 1, xp: 0, breakthroughCount: 0),
    },
    synthSlots: List<String?>.filled(4, null, growable: false),
  );
}
