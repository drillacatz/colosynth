class EquipmentStatBlock {
  final int atk;
  final int def;
  final int hp;
  final double damageReduction;
  final int shield;

  const EquipmentStatBlock({
    required this.atk,
    this.def = 0,
    required this.hp,
    this.damageReduction = 0.0,
    required this.shield,
  });

  static const EquipmentStatBlock zero = EquipmentStatBlock(
    atk: 0,
    def: 0,
    hp: 0,
    damageReduction: 0.0,
    shield: 0,
  );

  EquipmentStatBlock operator +(EquipmentStatBlock other) {
    return EquipmentStatBlock(
      atk: atk + other.atk,
      def: def + other.def,
      hp: hp + other.hp,
      damageReduction: damageReduction + other.damageReduction,
      shield: shield + other.shield,
    );
  }
}
