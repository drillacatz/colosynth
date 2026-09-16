import 'package:flutter/foundation.dart';

import 'package:colosynth/game/logic/battle_constants.dart';

class StaminaSystem {
  final int maxStamina;
  int _current;
  bool _blocking = false;
  bool _exhaustionFired = false;

  double _drainAccum = 0;
  double _restoreAccum = 0;

  VoidCallback? onExhausted;

  final ValueNotifier<int> notifier;

  StaminaSystem({this.maxStamina = StaminaConstants.defaultMax})
      : _current = maxStamina,
        notifier = ValueNotifier(maxStamina);

  int get current => _current;
  double get ratio => _current / maxStamina;
  bool get isExhausted => _current <= 0;
  bool get canDodge => _current >= StaminaConstants.dodgeMinRequired;

  void setBlocking(bool value) => _blocking = value;

  void update(double dt) {
    if (_blocking) {
      _restoreAccum = 0;
      _drainAccum += StaminaConstants.blockDrainPerSec * dt;
      final toApply = _drainAccum.floor();
      if (toApply > 0) {
        _drain(toApply);
        _drainAccum -= toApply;
      }
    } else {
      _drainAccum = 0;
      _restoreAccum += StaminaConstants.idleRestorePerSec * dt;
      final toApply = _restoreAccum.floor();
      if (toApply > 0) {
        _restore(toApply);
        _restoreAccum -= toApply;
      }
    }
  }

  void consumeDodge() => _drain(StaminaConstants.dodgeCost);
  void onHitRestore() => _restore(StaminaConstants.hitRestoreAmount);
  void restore(int amount) => _restore(amount);
  void drain(int amount) => _drain(amount);
  void drainPercent(double ratio) => _drain((maxStamina * ratio).round());

  void drainFromSuccessfulDodge() =>
      _drain((maxStamina * StaminaConstants.enemyDodgeDrainRatio).round());

  void drainFromSuccessfulParry() =>
      _drain((maxStamina * StaminaConstants.enemyParryDrainRatio).round());

  void drainFromSuccessfulDefense() =>
      _drain((maxStamina * StaminaConstants.enemyDefenseDrainRatio).round());

  void _drain(int amount) {
    final wasAboveZero = _current > 0;
    _current = (_current - amount).clamp(0, maxStamina);
    notifier.value = _current;
    if (wasAboveZero && _current <= 0 && !_exhaustionFired) {
      _exhaustionFired = true;
      onExhausted?.call();
    }
  }

  void _restore(int amount) {
    _current = (_current + amount).clamp(0, maxStamina);
    if (_current > 0) _exhaustionFired = false;
    notifier.value = _current;
  }

  void reset() {
    _current = maxStamina;
    _drainAccum = 0;
    _restoreAccum = 0;
    _exhaustionFired = false;
    notifier.value = _current;
  }

  void dispose() => notifier.dispose();
}
