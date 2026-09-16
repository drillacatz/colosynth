


class SkillTreeStats {
  final int flatAtk;
  final int flatHp;
  final double damageReduction;
  final int flatShield;
  final int flatStamina;
  final double allStatsPct;


  final double activeSkillMult;
  final double counterRate;
  final double dodgeBonus;
  final double comboWindow;
  final double parryBonus;

  const SkillTreeStats({
    this.flatAtk = 0,
    this.flatHp = 0,
    this.damageReduction = 0.0,
    this.flatShield = 0,
    this.flatStamina = 0,
    this.allStatsPct = 0.0,
    this.activeSkillMult = 0.0,
    this.counterRate = 0.0,
    this.dodgeBonus = 0.0,
    this.comboWindow = 0.0,
    this.parryBonus = 0.0,
  });

  static const SkillTreeStats zero = SkillTreeStats();
}




class _NodeDef {
  final String id;
  final int flatAtk;
  final int flatHp;
  final double damageReduction;
  final int flatShield;
  final int flatStamina;
  final double allStatsPct;
  final double counterRate;
  final double dodgeBonus;
  final double comboWindow;
  final double parryBonus;
  final double activeSkillMult;
  final double finisherMult;
  final double skillChargePct;
  final int skillUses;
  final double lifestealPct;
  final double blockCostReduction;
  final double regenPct;
  final int parryCostReduction;
  final int dodgeCostReduction;
  final double counterDurationBonus;
  final int inkCost;

  const _NodeDef({
    required this.id,
    this.flatAtk = 0,
    this.flatHp = 0,
    this.damageReduction = 0.0,
    this.flatShield = 0,
    this.flatStamina = 0,
    this.allStatsPct = 0.0,
    this.counterRate = 0.0,
    this.comboWindow = 0.0,
    this.parryBonus = 0.0,
    this.activeSkillMult = 0.0,
    this.finisherMult = 0.0,
    this.skillChargePct = 0.0,
    this.skillUses = 0,
    this.lifestealPct = 0.0,
    this.blockCostReduction = 0.0,
    this.regenPct = 0.0,
    this.parryCostReduction = 0,
    this.dodgeCostReduction = 0,
    this.counterDurationBonus = 0.0,
    required this.inkCost,
  }) : dodgeBonus = 0.0;
}

const _nodes = [
  _NodeDef(id: 'atk1',        flatAtk: 10,  inkCost: 300),
  _NodeDef(id: 'atk2',        flatAtk: 20,  inkCost: 500),
  _NodeDef(id: 'atk3',        flatAtk: 35,  inkCost: 800),
  _NodeDef(id: 'crit1',       counterRate: 0.05, inkCost: 600),
  _NodeDef(id: 'crit2',       counterRate: 0.10, inkCost: 1000),
  _NodeDef(id: 'active1',     activeSkillMult: 0.10, inkCost: 700),
  _NodeDef(id: 'active2',     activeSkillMult: 0.15, inkCost: 1200),
  _NodeDef(id: 'combo1',      comboWindow: 0.10, inkCost: 600),
  _NodeDef(id: 'finisher1',   finisherMult: 0.20, inkCost: 1500),

  _NodeDef(id: 'hp1',         flatHp: 50,   inkCost: 300),
  _NodeDef(id: 'hp2',         flatHp: 100,  inkCost: 500),
  _NodeDef(id: 'hp3',         flatHp: 200,  inkCost: 800),
  _NodeDef(id: 'def1',        damageReduction: 0.03, inkCost: 400),
  _NodeDef(id: 'def2',        damageReduction: 0.06, inkCost: 700),
  _NodeDef(id: 'shield1',     flatShield: 30, inkCost: 400),
  _NodeDef(id: 'shield2',     flatShield: 60, inkCost: 700),
  _NodeDef(id: 'parry_def',   parryBonus: 0.10, inkCost: 600),
  _NodeDef(id: 'block1',      blockCostReduction: -0.15, inkCost: 600),
  _NodeDef(id: 'regen1',      regenPct: 0.02, inkCost: 1200),

  _NodeDef(id: 'stam1',       flatStamina: 20, inkCost: 600),
  _NodeDef(id: 'stam2',       flatStamina: 35, inkCost: 900),
  _NodeDef(id: 'active_skill1', skillChargePct: 0.15, inkCost: 1000),
  _NodeDef(id: 'active_skill2', skillUses: 1,        inkCost: 3000),
  _NodeDef(id: 'parry1',      parryCostReduction: -5,  inkCost: 800),
  _NodeDef(id: 'parry2',      counterDurationBonus: 0.3, inkCost: 1500),
  _NodeDef(id: 'dodge1',      dodgeCostReduction: -5,  inkCost: 800),
  _NodeDef(id: 'dodge2',      counterRate: 0.20,       inkCost: 1500),
  _NodeDef(id: 'lifesteal',   lifestealPct: 0.08,      inkCost: 2500),
  _NodeDef(id: 'mastery',     allStatsPct: 0.05,       inkCost: 6000),
];

final _nodeMap = {for (final n in _nodes) n.id: n};

class SkillTreeModule {
  static const int totalInkCost = 53100;

  static Set<String> unlock(Set<String> current, String nodeId) =>
      Set<String>.from(current)..add(nodeId);

  static Set<String> reset() => {};

  static int inkCostFor(String nodeId) => _nodeMap[nodeId]?.inkCost ?? 0;

  static int totalCost(Set<String> nodes) =>
      nodes.fold(0, (sum, id) => sum + inkCostFor(id));

  static SkillTreeStats resolveStats(Set<String> nodes) {
    int flatAtk = 0, flatHp = 0, flatShield = 0, flatStamina = 0;
    double damageReduction = 0.0;
    double allStatsPct = 0, counterRate = 0, dodgeBonus = 0;
    double comboWindow = 0, parryBonus = 0, activeSkillMult = 0;

    for (final id in nodes) {
      final n = _nodeMap[id];
      if (n == null) continue;
      flatAtk      += n.flatAtk;
      flatHp       += n.flatHp;
      damageReduction += n.damageReduction;
      flatShield   += n.flatShield;
      flatStamina  += n.flatStamina;
      allStatsPct  += n.allStatsPct;
      counterRate  += n.counterRate;
      dodgeBonus   += n.dodgeBonus;
      comboWindow  += n.comboWindow;
      parryBonus   += n.parryBonus;
      activeSkillMult += n.activeSkillMult;
    }

    return SkillTreeStats(
      flatAtk:     flatAtk,
      flatHp:      flatHp,
      damageReduction: damageReduction,
      flatShield:  flatShield,
      flatStamina: flatStamina,
      allStatsPct: allStatsPct,
      counterRate: counterRate,
      dodgeBonus:  dodgeBonus,
      comboWindow: comboWindow,
      parryBonus:  parryBonus,
      activeSkillMult: activeSkillMult,
    );
  }
}
