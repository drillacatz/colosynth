import 'package:colosynth/database/character/battle_stats.dart';
import 'package:colosynth/growth/character/character_module.dart';
import 'package:colosynth/database/equipment/equipment_stat_block.dart';
import 'package:colosynth/growth/character/skills/skill_tree_module.dart';

class BattleStatsResolver {
  static BattleStats aggregate({
    required CharStatBlock char,
    required EquipmentStatBlock equip,
    required SkillTreeStats skillTree,
    int synthAtk = 0,
    int synthHp = 0,
  }) {
    final flatAtk = char.atk + equip.atk + skillTree.flatAtk + synthAtk;
    final flatHp  = char.hp  + equip.hp  + skillTree.flatHp + synthHp;
    final flatDef = equip.def + equip.shield + skillTree.flatShield + (equip.damageReduction * 500).round();
    final totalDamageReduction = (equip.damageReduction + skillTree.damageReduction).clamp(0.0, 0.85);
    final treeMult = 1.0 + skillTree.allStatsPct;

    return BattleStats(
      atk:    (flatAtk * treeMult).round().clamp(1, 999999),
      def:    (flatDef * treeMult).round().clamp(0, 999999),
      damageReduction: totalDamageReduction,
      hp:     (flatHp  * treeMult).round().clamp(1, 999999),
      shield: ((equip.shield + skillTree.flatShield) * treeMult).round().clamp(0, 999999),
      stamina: (100 + skillTree.flatStamina).clamp(1, 999999),
      speed:   10,
      counterRate:     skillTree.counterRate,
      comboWindow:     skillTree.comboWindow,
      parryBonus:      skillTree.parryBonus,
      dodgeBonus:      skillTree.dodgeBonus,
      activeSkillMult: skillTree.activeSkillMult,
      charContribAtk:      char.atk,
      skillTreeContribAtk: skillTree.flatAtk,
      equipContribAtk:     equip.atk,
      synthContribAtk:     synthAtk,
    );
  }
}
