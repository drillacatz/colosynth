class DamageEvent {
  const DamageEvent({
    required this.amount,
    required this.isPlayerDamage,
    required this.id,
    required this.worldX,
    required this.worldY,
  });

  final int amount;
  final bool isPlayerDamage;
  final int id;
  final double worldX;
  final double worldY;
}
