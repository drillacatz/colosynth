import 'package:flutter/foundation.dart';
import 'package:colosynth/game/logic/battle_constants.dart';

class ActiveSkillMeter {
  static const int maxCharge = SkillMeterConstants.maxCharge;

  int _charge = 0;
  int storedCharges = 0;
  int maxStoredCharges = 1;

  final ValueNotifier<int> chargeNotifier;

  ActiveSkillMeter() : chargeNotifier = ValueNotifier(0);

  int get charge => _charge;
  bool get isFull => _charge >= maxCharge;
  bool get canActivate => storedCharges > 0 || _charge >= maxCharge;
  double get ratio => _charge / maxCharge;

  void onHitNormal() => _add(SkillMeterConstants.chargePerNormalHit);
  void onParry() => _add(SkillMeterConstants.chargePerParry);
  void onDodge() => _add(SkillMeterConstants.chargePerDodge);
  void onHurt() => _add(SkillMeterConstants.chargeOnHurt);
  void onCounterSlash() => _add(SkillMeterConstants.chargePerCounterSlash);
  void addCharge(int amount) => _add(amount);

  bool consume() {
    if (storedCharges > 0) {
      storedCharges--;
      chargeNotifier.value = _charge;
      return true;
    }
    if (_charge >= maxCharge) {
      _charge = 0;
      chargeNotifier.value = _charge;
      return true;
    }
    return false;
  }

  void _add(int amount) {
    _charge += amount;
    while (_charge >= maxCharge && storedCharges < maxStoredCharges) {
      storedCharges++;
      _charge -= maxCharge;
    }
    if (_charge >= maxCharge) {
      _charge = maxCharge;
    }
    chargeNotifier.value = _charge;
  }

  void reset() {
    _charge = 0;
    storedCharges = 0;
    chargeNotifier.value = _charge;
  }

  void dispose() {
    chargeNotifier.dispose();
  }
}
