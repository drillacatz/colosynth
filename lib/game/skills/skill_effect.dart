enum SkillEffectType {
  damageMultiplier,
  healPercent,
  staminaRestore,
  activeSkillCharge,
  lifeSteal,
  damageReduction,
  damageReflect,
}

class SkillEffect {
  const SkillEffect({
    required this.type,
    required this.value,
    this.durationSeconds = 0,
  });

  final SkillEffectType type;
  final double value;
  final double durationSeconds;
}
