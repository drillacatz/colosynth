import 'package:colosynth/database/equipment/equipment_instance.dart';
import 'package:colosynth/database/equipment/equipment_stat_block.dart';
import 'package:colosynth/growth/equipment/equipment_progression.dart';

class EquipmentModule {
  static EquipmentInstance upgrade(EquipmentInstance i) {
    if (i.level >= i.maxLevel) return i;
    return i.copyWith(level: i.level + 1);
  }

  static EquipmentInstance breakthrough(EquipmentInstance i) {
    if (i.breakthroughCount >= 2) return i;
    return i.copyWith(breakthroughCount: i.breakthroughCount + 1);
  }

  static EquipmentStatBlock resolveStats(EquipmentInstance i) {
    return EquipmentStatBlock(
      atk: EquipmentProgression.equipStatAtLevel(
          i.slot, 'atk', i.level,
          breakthroughCount: i.breakthroughCount),
      hp: EquipmentProgression.equipStatAtLevel(
          i.slot, 'hp', i.level,
          breakthroughCount: i.breakthroughCount),
      shield: EquipmentProgression.equipStatAtLevel(
          i.slot, 'shield', i.level,
          breakthroughCount: i.breakthroughCount),
    );
  }

  static EquipmentStatBlock resolveGearSet(Map<String, EquipmentInstance> gear) =>
      gear.values.map(resolveStats).fold(EquipmentStatBlock.zero, (a, b) => a + b);
}
