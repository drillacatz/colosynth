import 'package:flutter/foundation.dart';
import 'package:colosynth/game/logic/battle_constants.dart';

/// Snapshot of the active skill charge state, used for UI & serialization.
@immutable
class ActiveSkillChargeState {
  final int charge;
  final int maxCharge;
  final int storedCharges;
  final int maxStoredCharges;

  const ActiveSkillChargeState({
    required this.charge,
    required this.maxCharge,
    required this.storedCharges,
    required this.maxStoredCharges,
  });

  factory ActiveSkillChargeState.empty() => const ActiveSkillChargeState(
        charge: 0,
        maxCharge: SkillMeterConstants.maxCharge,
        storedCharges: 0,
        maxStoredCharges: 1,
      );

  double get ratio => maxCharge == 0 ? 0 : charge / maxCharge;
  bool get isFull => charge >= maxCharge;
  bool get canActivate => storedCharges > 0 || charge >= maxCharge;

  @override
  String toString() =>
      'ActiveSkillChargeState(charge: $charge/$maxCharge, stored: $storedCharges/$maxStoredCharges)';
}
