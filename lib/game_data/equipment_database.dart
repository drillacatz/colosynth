import 'package:colosynth/services/sprite_repository.dart';

class BaseEquipmentStats {
  final int atk;
  final int def;
  final int hp;
  final double damageReduction;
  final int shield;

  const BaseEquipmentStats({
    this.atk = 0,
    this.def = 0,
    this.hp = 0,
    this.damageReduction = 0.0,
    this.shield = 0,
  });
}

class EquipmentDefinition {
  final String id;
  final String slot;
  final String name;

  const EquipmentDefinition({
    required this.id,
    required this.slot,
    required this.name,
  });
}

class EquipmentDatabase {
  static const List<EquipmentDefinition> starters = [
    EquipmentDefinition(id: 'starter_sword', slot: 'weapon', name: 'Starter Sword'),
    EquipmentDefinition(id: 'starter_shield', slot: 'shield', name: 'Starter Shield'),
    EquipmentDefinition(id: 'starter_armor', slot: 'armor', name: 'Starter Armor'),
    EquipmentDefinition(id: 'starter_helmet', slot: 'helmet', name: 'Starter Helmet'),
  ];

  static const List<EquipmentDefinition> all = [
    EquipmentDefinition(id: 'arthur_weapon', slot: 'weapon', name: 'arthur_weapon'),
    EquipmentDefinition(id: 'arthur_shield', slot: 'shield', name: 'arthur_shield'),
    EquipmentDefinition(id: 'arthur_armor', slot: 'armor', name: 'arthur_armor'),
    EquipmentDefinition(id: 'arthur_helmet', slot: 'helmet', name: 'arthur_helmet'),

    EquipmentDefinition(id: 'lilith_weapon', slot: 'weapon', name: 'lilith_weapon'),
    EquipmentDefinition(id: 'lilith_shield', slot: 'shield', name: 'lilith_shield'),
    EquipmentDefinition(id: 'lilith_armor', slot: 'armor', name: 'lilith_armor'),
    EquipmentDefinition(id: 'lilith_helmet', slot: 'helmet', name: 'lilith_helmet'),

    EquipmentDefinition(id: 'centrium_weapon', slot: 'weapon', name: 'centrium_weapon'),
    EquipmentDefinition(id: 'centrium_shield', slot: 'shield', name: 'centrium_shield'),
    EquipmentDefinition(id: 'centrium_armor', slot: 'armor', name: 'centrium_armor'),
    EquipmentDefinition(id: 'centrium_helmet', slot: 'helmet', name: 'centrium_helmet'),

    EquipmentDefinition(id: 'char_04_weapon', slot: 'weapon', name: 'char_04_weapon'),
    EquipmentDefinition(id: 'char_04_shield', slot: 'shield', name: 'char_04_shield'),
    EquipmentDefinition(id: 'char_04_armor', slot: 'armor', name: 'char_04_armor'),
    EquipmentDefinition(id: 'char_04_helmet', slot: 'helmet', name: 'char_04_helmet'),

    EquipmentDefinition(id: 'char_05_weapon', slot: 'weapon', name: 'char_05_weapon'),
    EquipmentDefinition(id: 'char_05_shield', slot: 'shield', name: 'char_05_shield'),
    EquipmentDefinition(id: 'char_05_armor', slot: 'armor', name: 'char_05_armor'),
    EquipmentDefinition(id: 'char_05_helmet', slot: 'helmet', name: 'char_05_helmet'),

    EquipmentDefinition(id: 'char_06_weapon', slot: 'weapon', name: 'char_06_weapon'),
    EquipmentDefinition(id: 'char_06_shield', slot: 'shield', name: 'char_06_shield'),
    EquipmentDefinition(id: 'char_06_armor', slot: 'armor', name: 'char_06_armor'),
    EquipmentDefinition(id: 'char_06_helmet', slot: 'helmet', name: 'char_06_helmet'),

    EquipmentDefinition(id: 'char_07_weapon', slot: 'weapon', name: 'char_07_weapon'),
    EquipmentDefinition(id: 'char_07_shield', slot: 'shield', name: 'char_07_shield'),
    EquipmentDefinition(id: 'char_07_armor', slot: 'armor', name: 'char_07_armor'),
    EquipmentDefinition(id: 'char_07_helmet', slot: 'helmet', name: 'char_07_helmet'),

    EquipmentDefinition(id: 'char_08_weapon', slot: 'weapon', name: 'char_08_weapon'),
    EquipmentDefinition(id: 'char_08_shield', slot: 'shield', name: 'char_08_shield'),
    EquipmentDefinition(id: 'char_08_armor', slot: 'armor', name: 'char_08_armor'),
    EquipmentDefinition(id: 'char_08_helmet', slot: 'helmet', name: 'char_08_helmet'),

    EquipmentDefinition(id: 'char_09_weapon', slot: 'weapon', name: 'char_09_weapon'),
    EquipmentDefinition(id: 'char_09_shield', slot: 'shield', name: 'char_09_shield'),
    EquipmentDefinition(id: 'char_09_armor', slot: 'armor', name: 'char_09_armor'),
    EquipmentDefinition(id: 'char_09_helmet', slot: 'helmet', name: 'char_09_helmet'),

    EquipmentDefinition(id: 'char_10_weapon', slot: 'weapon', name: 'char_10_weapon'),
    EquipmentDefinition(id: 'char_10_shield', slot: 'shield', name: 'char_10_shield'),
    EquipmentDefinition(id: 'char_10_armor', slot: 'armor', name: 'char_10_armor'),
    EquipmentDefinition(id: 'char_10_helmet', slot: 'helmet', name: 'char_10_helmet'),

    EquipmentDefinition(id: 'char_11_weapon', slot: 'weapon', name: 'char_11_weapon'),
    EquipmentDefinition(id: 'char_11_shield', slot: 'shield', name: 'char_11_shield'),
    EquipmentDefinition(id: 'char_11_armor', slot: 'armor', name: 'char_11_armor'),
    EquipmentDefinition(id: 'char_11_helmet', slot: 'helmet', name: 'char_11_helmet'),

    EquipmentDefinition(id: 'char_12_weapon', slot: 'weapon', name: 'char_12_weapon'),
    EquipmentDefinition(id: 'char_12_shield', slot: 'shield', name: 'char_12_shield'),
    EquipmentDefinition(id: 'char_12_armor', slot: 'armor', name: 'char_12_armor'),
    EquipmentDefinition(id: 'char_12_helmet', slot: 'helmet', name: 'char_12_helmet'),
  ];

  static String imagePathFor(String equipId) => SpriteRepository.equipmentImage(equipId);

  static BaseEquipmentStats baseStatsFor(String equipId) {
    if (equipId.endsWith('_weapon') || equipId.endsWith('_sword') || equipId.startsWith('weapon_') || equipId == 'starter_sword') {
      return const BaseEquipmentStats(atk: 15);
    } else if (equipId.endsWith('_armor') || equipId.startsWith('armor_') || equipId == 'starter_armor') {
      return const BaseEquipmentStats(hp: 100, def: 25, damageReduction: 0.05);
    } else if (equipId.endsWith('_shield') || equipId.startsWith('shield_') || equipId == 'starter_shield') {
      return const BaseEquipmentStats(def: 30, shield: 8);
    } else if (equipId.endsWith('_helmet') || equipId.startsWith('helmet_') || equipId == 'starter_helmet') {
      return const BaseEquipmentStats(hp: 50, def: 15, damageReduction: 0.02);
    }
    return const BaseEquipmentStats();
  }
}
