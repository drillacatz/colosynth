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
  // ==========================================
  // COLUMN 0: OFFENSE (9 Nodes)
  // ==========================================
  SkillNode(
    id: 'atk1',
    label: 'STRIKE I',
    bonus: 'ATK +10',
    inkCost: 300,
    prerequisites: {},
    category: SkillCategory.offense,
    row: 0,
    value: 10,
    statType: 'atk',
  ),
  SkillNode(
    id: 'atk2',
    label: 'STRIKE II',
    bonus: 'ATK +20',
    inkCost: 500,
    prerequisites: {'atk1'},
    category: SkillCategory.offense,
    row: 1,
    value: 20,
    statType: 'atk',
  ),
  SkillNode(
    id: 'crit1',
    label: 'CRIT I',
    bonus: 'Counter +5%',
    inkCost: 600,
    prerequisites: {'atk1'},
    category: SkillCategory.offense,
    row: 2,
    value: 0.05,
    statType: 'counter',
  ),
  SkillNode(
    id: 'combo1',
    label: 'COMBOIST',
    bonus: 'Window +0.1s',
    inkCost: 600,
    prerequisites: {'atk1'},
    category: SkillCategory.offense,
    row: 2,
    value: 0.10,
    statType: 'combo_window',
  ),
  SkillNode(
    id: 'atk3',
    label: 'STRIKE III',
    bonus: 'ATK +35',
    inkCost: 800,
    prerequisites: {'atk2'},
    category: SkillCategory.offense,
    row: 3,
    value: 35,
    statType: 'atk',
  ),
  SkillNode(
    id: 'active1',
    label: 'FOCUS I',
    bonus: 'Skill ×10%',
    inkCost: 700,
    prerequisites: {'atk2'},
    category: SkillCategory.offense,
    row: 3,
    value: 0.10,
    statType: 'active_skill',
  ),
  SkillNode(
    id: 'crit2',
    label: 'CRIT II',
    bonus: 'Counter +10%',
    inkCost: 1000,
    prerequisites: {'crit1'},
    category: SkillCategory.offense,
    row: 4,
    value: 0.10,
    statType: 'counter',
  ),
  SkillNode(
    id: 'active2',
    label: 'FOCUS II',
    bonus: 'Skill ×15%',
    inkCost: 1200,
    prerequisites: {'active1'},
    category: SkillCategory.offense,
    row: 4,
    value: 0.15,
    statType: 'active_skill',
  ),
  SkillNode(
    id: 'finisher1',
    label: 'FINISHER I',
    bonus: 'Finisher ×20%',
    inkCost: 1500,
    prerequisites: {'atk3'},
    category: SkillCategory.offense,
    row: 5,
    value: 0.20,
    statType: 'finisher_mult',
  ),

  // ==========================================
  // COLUMN 1: DEFENSE (10 Nodes)
  // ==========================================
  SkillNode(
    id: 'hp1',
    label: 'VITALITY I',
    bonus: 'HP +50',
    inkCost: 300,
    prerequisites: {},
    category: SkillCategory.defense,
    row: 0,
    value: 50,
    statType: 'hp',
  ),
  SkillNode(
    id: 'hp2',
    label: 'VITALITY II',
    bonus: 'HP +100',
    inkCost: 500,
    prerequisites: {'hp1'},
    category: SkillCategory.defense,
    row: 1,
    value: 100,
    statType: 'hp',
  ),
  SkillNode(
    id: 'def1',
    label: 'ARMOR I',
    bonus: 'DMG RED +3%',
    inkCost: 400,
    prerequisites: {'hp1'},
    category: SkillCategory.defense,
    row: 2,
    value: 0.03,
    statType: 'damageReduction',
  ),
  SkillNode(
    id: 'shield1',
    label: 'GUARD I',
    bonus: 'Shield +30',
    inkCost: 400,
    prerequisites: {'hp1'},
    category: SkillCategory.defense,
    row: 2,
    value: 30,
    statType: 'shield_def',
  ),
  SkillNode(
    id: 'hp3',
    label: 'VITALITY III',
    bonus: 'HP +200',
    inkCost: 800,
    prerequisites: {'hp2'},
    category: SkillCategory.defense,
    row: 3,
    value: 200,
    statType: 'hp',
  ),
  SkillNode(
    id: 'parry_def',
    label: 'PARRY GUARD',
    bonus: 'Parry +10%',
    inkCost: 600,
    prerequisites: {'def1'},
    category: SkillCategory.defense,
    row: 3,
    value: 0.10,
    statType: 'parry_bonus',
  ),
  SkillNode(
    id: 'def2',
    label: 'ARMOR II',
    bonus: 'DMG RED +6%',
    inkCost: 700,
    prerequisites: {'def1'},
    category: SkillCategory.defense,
    row: 4,
    value: 0.06,
    statType: 'damageReduction',
  ),
  SkillNode(
    id: 'shield2',
    label: 'GUARD II',
    bonus: 'Shield +60',
    inkCost: 700,
    prerequisites: {'shield1'},
    category: SkillCategory.defense,
    row: 4,
    value: 60,
    statType: 'shield_def',
  ),
  SkillNode(
    id: 'block1',
    label: 'IRON GUARD',
    bonus: 'Block -15%',
    inkCost: 600,
    prerequisites: {'shield1'},
    category: SkillCategory.defense,
    row: 4,
    value: -0.15,
    statType: 'block_cost',
  ),
  SkillNode(
    id: 'regen1',
    label: 'REGEN I',
    bonus: 'HP 2.0%/s',
    inkCost: 1200,
    prerequisites: {'hp3'},
    category: SkillCategory.defense,
    row: 5,
    value: 0.02,
    statType: 'regen',
  ),

  // ==========================================
  // COLUMN 2: UTILITY (10 Nodes)
  // ==========================================
  SkillNode(
    id: 'stam1',
    label: 'ENDURANCE I',
    bonus: 'Stamina +20',
    inkCost: 600,
    prerequisites: {},
    category: SkillCategory.utility,
    row: 0,
    value: 20,
    statType: 'stamina',
  ),
  SkillNode(
    id: 'stam2',
    label: 'ENDURANCE II',
    bonus: 'Stamina +35',
    inkCost: 900,
    prerequisites: {'stam1'},
    category: SkillCategory.utility,
    row: 1,
    value: 35,
    statType: 'stamina',
  ),
  SkillNode(
    id: 'parry1',
    label: 'PARRY ART I',
    bonus: 'Parry cost -5',
    inkCost: 800,
    prerequisites: {'stam1'},
    category: SkillCategory.utility,
    row: 2,
    value: -5,
    statType: 'parry_cost',
  ),
  SkillNode(
    id: 'dodge1',
    label: 'PHANTOM I',
    bonus: 'Dodge cost -5',
    inkCost: 800,
    prerequisites: {'stam1'},
    category: SkillCategory.utility,
    row: 2,
    value: -5,
    statType: 'dodge_cost',
  ),
  SkillNode(
    id: 'active_skill1',
    label: 'SURGE CHARGE',
    bonus: 'Charge +15%',
    inkCost: 1000,
    prerequisites: {'stam2'},
    category: SkillCategory.utility,
    row: 3,
    value: 0.15,
    statType: 'skill_charge',
  ),
  SkillNode(
    id: 'parry2',
    label: 'PARRY ART II',
    bonus: 'Window +0.3s',
    inkCost: 1500,
    prerequisites: {'parry1'},
    category: SkillCategory.utility,
    row: 3,
    value: 0.3,
    statType: 'counter_duration',
  ),
  SkillNode(
    id: 'dodge2',
    label: 'PHANTOM II',
    bonus: 'Counter +20%',
    inkCost: 1500,
    prerequisites: {'dodge1'},
    category: SkillCategory.utility,
    row: 4,
    value: 0.20,
    statType: 'counter',
  ),
  SkillNode(
    id: 'active_skill2',
    label: 'SKILL BURST',
    bonus: 'Uses +1',
    inkCost: 3000,
    prerequisites: {'active_skill1'},
    category: SkillCategory.utility,
    row: 4,
    value: 1,
    statType: 'skill_uses',
  ),
  SkillNode(
    id: 'lifesteal',
    label: 'LIFESTEAL',
    bonus: 'Steal 8% ATK',
    inkCost: 2500,
    prerequisites: {'active_skill1', 'stam2'},
    category: SkillCategory.utility,
    row: 5,
    value: 0.08,
    statType: 'lifesteal',
  ),
  SkillNode(
    id: 'mastery',
    label: 'GRAND MASTERY',
    bonus: 'All Stats +5%',
    inkCost: 6000,
    prerequisites: {'finisher1', 'regen1', 'active_skill2'},
    category: SkillCategory.utility,
    row: 6,
    value: 0.05,
    statType: 'all_stats_mult',
  ),
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


