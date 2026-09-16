import 'package:flutter/material.dart';

import 'package:colosynth/growth/equipment/equipment_progression.dart';

enum SkillCategory { offense, defense, utility }

class SkillNode {
  const SkillNode({
    required this.id,
    required this.label,
    required this.bonus,
    required this.inkCost,
    required this.prerequisites,
    required this.category,
    required this.row,
    this.value = 0,
    this.statType = '',
  });

  final String id;
  final String label;
  final String bonus;
  final int inkCost;
  final Set<String> prerequisites;
  final SkillCategory category;
  final int row;
  final double value;
  final String statType;
}

class EquipmentSlotInfo {
  const EquipmentSlotInfo({
    required this.slotKey,
    required this.label,
    required this.icon,
    required this.description,
    this.breakthroughCount = 0,
  });

  final String slotKey;
  final String label;
  final IconData icon;
  final String description;
  final int breakthroughCount;

  EquipmentSlotInfo copyWithBreakthrough(int newBreakthrough) {
    return EquipmentSlotInfo(
      slotKey: slotKey,
      label: label,
      icon: icon,
      description: description,
      breakthroughCount: newBreakthrough,
    );
  }
}

const kEquipmentSlots = <EquipmentSlotInfo>[
  EquipmentSlotInfo(
    slotKey: 'weapon',
    label: 'WEAPON',
    icon: Icons.colorize,
    description: 'Boosts attack power and damage output',
  ),
  EquipmentSlotInfo(
    slotKey: 'shield',
    label: 'SHIELD',
    icon: Icons.security,
    description: 'Enhances block strength and guard stamina',
  ),
  EquipmentSlotInfo(
    slotKey: 'armor',
    label: 'ARMOR',
    icon: Icons.shield,
    description: 'Increases defence and damage reduction',
  ),
  EquipmentSlotInfo(
    slotKey: 'helmet',
    label: 'HELMET',
    icon: Icons.face,
    description: 'Improves HP capacity and status resistance',
  ),
];

const kAllSkillNodes = <SkillNode>[
  SkillNode(
      id: 'atk1',
      label: 'STRIKE I',
      bonus: 'ATK +8',
      inkCost: 600,
      prerequisites: {},
      category: SkillCategory.offense,
      row: 0,
      value: 8,
      statType: 'atk'),
  SkillNode(
      id: 'atk2',
      label: 'STRIKE II',
      bonus: 'ATK +12',
      inkCost: 900,
      prerequisites: {'atk1'},
      category: SkillCategory.offense,
      row: 1,
      value: 12,
      statType: 'atk'),
  SkillNode(
      id: 'atk3',
      label: 'STRIKE III',
      bonus: 'ATK +18',
      inkCost: 1400,
      prerequisites: {'atk2'},
      category: SkillCategory.offense,
      row: 2,
      value: 18,
      statType: 'atk'),
  SkillNode(
      id: 'counter1',
      label: 'COUNTER I',
      bonus: 'Counter +15%',
      inkCost: 1200,
      prerequisites: {'atk1'},
      category: SkillCategory.offense,
      row: 5,
      value: 0.15,
      statType: 'counter'),
  SkillNode(
      id: 'counter2',
      label: 'COUNTER II',
      bonus: 'Counter +25%',
      inkCost: 1800,
      prerequisites: {'counter1'},
      category: SkillCategory.offense,
      row: 6,
      value: 0.25,
      statType: 'counter'),
  SkillNode(
      id: 'combo1',
      label: 'COMBOIST',
      bonus: 'Window +0.15s',
      inkCost: 1000,
      prerequisites: {'atk1'},
      category: SkillCategory.offense,
      row: 7,
      value: 0.15,
      statType: 'combo_window'),
  SkillNode(
      id: 'finisher1',
      label: 'FINISHER I',
      bonus: 'Finisher ×30%',
      inkCost: 2000,
      prerequisites: {'atk3'},
      category: SkillCategory.offense,
      row: 8,
      value: 0.30,
      statType: 'finisher_mult'),
  SkillNode(
      id: 'finisher2',
      label: 'FINISHER II',
      bonus: 'Finisher ×50%',
      inkCost: 3500,
      prerequisites: {'finisher1'},
      category: SkillCategory.offense,
      row: 9,
      value: 0.50,
      statType: 'finisher_mult'),
  SkillNode(
      id: 'blade_master',
      label: 'BLADE MASTER',
      bonus: 'ATK +25, Combo+',
      inkCost: 5000,
      prerequisites: {'atk3', 'finisher2', 'counter2'},
      category: SkillCategory.offense,
      row: 10,
      value: 25,
      statType: 'atk'),
  SkillNode(
      id: 'hp1',
      label: 'VITALITY I',
      bonus: 'HP +25',
      inkCost: 600,
      prerequisites: {},
      category: SkillCategory.defense,
      row: 0,
      value: 25,
      statType: 'hp'),
  SkillNode(
      id: 'hp2',
      label: 'VITALITY II',
      bonus: 'HP +40',
      inkCost: 900,
      prerequisites: {'hp1'},
      category: SkillCategory.defense,
      row: 1,
      value: 40,
      statType: 'hp'),
  SkillNode(
      id: 'hp3',
      label: 'VITALITY III',
      bonus: 'HP +60',
      inkCost: 1400,
      prerequisites: {'hp2'},
      category: SkillCategory.defense,
      row: 2,
      value: 60,
      statType: 'hp'),
  SkillNode(
      id: 'def1',
      label: 'ARMOR I',
      bonus: 'DMG RED +3%',
      inkCost: 800,
      prerequisites: {'hp1'},
      category: SkillCategory.defense,
      row: 3,
      value: 3,
      statType: 'damageReduction'),
  SkillNode(
      id: 'def2',
      label: 'ARMOR II',
      bonus: 'DMG RED +6%',
      inkCost: 1200,
      prerequisites: {'def1'},
      category: SkillCategory.defense,
      row: 4,
      value: 6,
      statType: 'damageReduction'),
  SkillNode(
      id: 'shield1',
      label: 'GUARD I',
      bonus: 'Shield +10',
      inkCost: 800,
      prerequisites: {'hp1'},
      category: SkillCategory.defense,
      row: 5,
      value: 10,
      statType: 'shield_def'),
  SkillNode(
      id: 'shield2',
      label: 'GUARD II',
      bonus: 'Shield +18',
      inkCost: 1400,
      prerequisites: {'shield1'},
      category: SkillCategory.defense,
      row: 6,
      value: 18,
      statType: 'shield_def'),
  SkillNode(
      id: 'regen1',
      label: 'REGEN I',
      bonus: 'HP 0.5%/s',
      inkCost: 2000,
      prerequisites: {'hp2'},
      category: SkillCategory.defense,
      row: 7,
      value: 0.005,
      statType: 'regen'),
  SkillNode(
      id: 'regen2',
      label: 'REGEN II',
      bonus: 'HP 1.0%/s',
      inkCost: 3000,
      prerequisites: {'regen1', 'hp3'},
      category: SkillCategory.defense,
      row: 8,
      value: 0.01,
      statType: 'regen'),
  SkillNode(
      id: 'iron_wall',
      label: 'IRON WALL',
      bonus: 'Block -15%',
      inkCost: 2500,
      prerequisites: {'def2', 'shield2'},
      category: SkillCategory.defense,
      row: 9,
      value: -0.15,
      statType: 'block_cost'),
  SkillNode(
      id: 'fortress',
      label: 'FORTRESS',
      bonus: 'HP +100, DMG RED+',
      inkCost: 5000,
      prerequisites: {'hp3', 'iron_wall', 'regen2'},
      category: SkillCategory.defense,
      row: 10,
      value: 100,
      statType: 'hp'),
  SkillNode(
      id: 'stam1',
      label: 'ENDURANCE I',
      bonus: 'Stamina +20',
      inkCost: 600,
      prerequisites: {},
      category: SkillCategory.utility,
      row: 0,
      value: 20,
      statType: 'stamina'),
  SkillNode(
      id: 'stam2',
      label: 'ENDURANCE II',
      bonus: 'Stamina +35',
      inkCost: 900,
      prerequisites: {'stam1'},
      category: SkillCategory.utility,
      row: 1,
      value: 35,
      statType: 'stamina'),
  SkillNode(
      id: 'active_skill1',
      label: 'ACTIVE SKILL I',
      bonus: 'Charge +15%',
      inkCost: 1000,
      prerequisites: {},
      category: SkillCategory.utility,
      row: 2,
      value: 0.15,
      statType: 'skill_charge'),
  SkillNode(
      id: 'active_skill2',
      label: 'ACTIVE SKILL II',
      bonus: 'Skill Uses +1',
      inkCost: 3000,
      prerequisites: {'active_skill1', 'stam2'},
      category: SkillCategory.utility,
      row: 3,
      value: 1,
      statType: 'skill_uses'),
  SkillNode(
      id: 'parry1',
      label: 'PARRY ART I',
      bonus: 'Parry drain -5',
      inkCost: 800,
      prerequisites: {'stam1'},
      category: SkillCategory.utility,
      row: 4,
      value: -5,
      statType: 'parry_cost'),
  SkillNode(
      id: 'parry2',
      label: 'PARRY ART II',
      bonus: 'Counter Window +0.3s',
      inkCost: 1500,
      prerequisites: {'parry1'},
      category: SkillCategory.utility,
      row: 5,
      value: 0.3,
      statType: 'counter_duration'),
  SkillNode(
      id: 'dodge1',
      label: 'PHANTOM I',
      bonus: 'Dodge -5 cost',
      inkCost: 800,
      prerequisites: {'stam1'},
      category: SkillCategory.utility,
      row: 6,
      value: -5,
      statType: 'dodge_cost'),
  SkillNode(
      id: 'dodge2',
      label: 'PHANTOM II',
      bonus: 'Counter +20%',
      inkCost: 1500,
      prerequisites: {'dodge1'},
      category: SkillCategory.utility,
      row: 7,
      value: 0.20,
      statType: 'counter'),
  SkillNode(
      id: 'lifesteal',
      label: 'LIFESTEAL',
      bonus: 'Steal 8% ATK',
      inkCost: 2500,
      prerequisites: {'active_skill1', 'stam2'},
      category: SkillCategory.utility,
      row: 9,
      value: 0.08,
      statType: 'lifesteal'),
  SkillNode(
      id: 'mastery',
      label: 'MASTERY',
      bonus: 'All Stats +5%',
      inkCost: 6000,
      prerequisites: {'active_skill2', 'lifesteal', 'parry2', 'dodge2'},
      category: SkillCategory.utility,
      row: 10,
      value: 0.05,
      statType: 'all_stats_mult'),
];

List<SkillNode> nodesForCategory(SkillCategory cat) =>
    kAllSkillNodes.where((n) => n.category == cat).toList()
      ..sort((a, b) => a.row.compareTo(b.row));

String formatResourceCost(int v) {
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
  return '$v';
}

String labelFromItemId(String itemId) {
  final parts = itemId.split('_');
  final words = parts.length > 1 ? parts.sublist(1) : parts;
  return words
      .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

double multiplierForLevel(int level, int breakthroughCount) =>
    EquipmentProgression.calculateMultiplier(breakthroughCount, level);

int calculateUpgradeCost(int level, int breakthroughCount) {
  return EquipmentProgression.upgradeCost(level);
}

String getStatLabelForSlot(String slotKey) {
  if (slotKey.contains('weapon')) return 'ATK';
  if (slotKey.contains('shield')) return 'SHIELD';
  if (slotKey.contains('armor')) return 'HP';
  if (slotKey.contains('helmet')) return 'HP';
  return 'STAT';
}


