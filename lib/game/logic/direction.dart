import 'dart:math';

enum AttackDirection { n, ne, e, se, s, sw, w, nw }

enum DodgeDirection { left, right }

extension AttackDirectionX on AttackDirection {
  AttackDirection get opposite => AttackDirection.values[(index + 4) % 8];

  String get arrow => const ['↑', '↗', '→', '↘', '↓', '↙', '←', '↖'][index];

  bool isOppositeOf(AttackDirection other) => opposite == other;

  DodgeDirection? get requiredDodge => switch (this) {
        AttackDirection.ne => DodgeDirection.right,
        AttackDirection.nw => DodgeDirection.left,
        _ => null,
      };

  bool canDodgeWith(DodgeDirection dodge) {
    final required = requiredDodge;
    return required == null || required == dodge;
  }
}

AttackDirection swipeToDirection(double dx, double dy) {
  final angle = atan2(dy, dx);
  final deg = (angle * 180 / pi + 360) % 360;
  final sector = ((deg + 22.5) / 45).floor() % 8;
  return switch (sector) {
    0 => AttackDirection.e,
    1 => AttackDirection.se,
    2 => AttackDirection.s,
    3 => AttackDirection.sw,
    4 => AttackDirection.w,
    5 => AttackDirection.nw,
    6 => AttackDirection.n,
    7 => AttackDirection.ne,
    _ => AttackDirection.e,
  };
}
