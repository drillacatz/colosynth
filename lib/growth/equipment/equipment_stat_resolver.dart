import 'package:colosynth/database/equipment/equipment_instance.dart';
import 'package:colosynth/database/equipment/equipment_stat_block.dart';
import 'package:colosynth/growth/equipment/equipment_module.dart';

class EquipmentStatResolver {
  static EquipmentStatBlock resolveGearSet(Map<String, EquipmentInstance> gear) {
    return EquipmentModule.resolveGearSet(gear);
  }
}
