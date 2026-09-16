import 'package:flutter/foundation.dart';

enum BattleState {
  idle,
  enemyTelegraph,
  playerSlash,
  blockedRecoil,
  enemyHurt,
  parrySuccess,
  blockSuccess,
  dodgeSuccess,
  dodgeFail,
  enemyHit,
  playerHurt,
  activeSkill,
  victory,
  defeat,
  counterWindow,
}

typedef StateChangeCallback = void Function(BattleState prev, BattleState next);

class BattleStateMachine {
  BattleState _current = BattleState.idle;
  final List<StateChangeCallback> _listeners = [];

  BattleState get current => _current;

  bool get isIdle => _current == BattleState.idle;
  bool get isVictory => _current == BattleState.victory;
  bool get isDefeat => _current == BattleState.defeat;
  bool get isBattleOver => isVictory || isDefeat;
  bool get isInCounterWindow => _current == BattleState.counterWindow;


  void addListener(StateChangeCallback cb) => _listeners.add(cb);
  void removeListener(StateChangeCallback cb) => _listeners.remove(cb);

  void transition(BattleState next) {
    if (_current == next) return;
    final prev = _current;
    _current = next;
    if (kDebugMode) debugPrint('[FSM] $prev → $next');
    if (_listeners.isNotEmpty) {
      final snapshot = List<StateChangeCallback>.of(_listeners);
      for (final cb in snapshot) {
        cb(prev, next);
      }
    }
  }

  void reset() {


    final prev = _current;
    _current = BattleState.idle;
    if (kDebugMode) debugPrint('[FSM] RESET → idle');
    if (_listeners.isNotEmpty) {
      final snapshot = List<StateChangeCallback>.of(_listeners);
      for (final cb in snapshot) {
        cb(prev, BattleState.idle);
      }
    }
  }
}
