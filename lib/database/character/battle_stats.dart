

class BattleStats {
  final int atk;
  final int def;
  final double damageReduction;
  final int hp;
  final int shield;
  final int stamina;
  final int speed;

  final double counterRate;
  final double comboWindow;
  final double parryBonus;
  final double dodgeBonus;
  final double activeSkillMult;

  final int charContribAtk;
  final int skillTreeContribAtk;
  final int equipContribAtk;
  final int synthContribAtk;

  const BattleStats({
    required this.atk,
    this.def = 0,
    this.damageReduction = 0.0,
    required this.hp,
    required this.shield,
    required this.stamina,
    required this.speed,
    this.counterRate = 0.0,
    this.comboWindow = 0.0,
    this.parryBonus = 0.0,
    this.dodgeBonus = 0.0,
    this.activeSkillMult = 0.0,
    this.charContribAtk = 0,
    this.skillTreeContribAtk = 0,
    this.equipContribAtk = 0,
    this.synthContribAtk = 0,
  });

  static const BattleStats empty = BattleStats(
    atk: 0,
    def: 0,
    damageReduction: 0.0,
    hp: 0,
    shield: 0,
    stamina: 0,
    speed: 0,
  );
}
