import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:colosynth/game/event_bus/game_event_bus.dart';
import 'package:colosynth/game/event_bus/game_events.dart';

class PlayerStatsTracker {
  PlayerStatsTracker._();
  static final PlayerStatsTracker instance = PlayerStatsTracker._();

  SharedPreferences? _prefs;
  bool _inBattle = false;
  bool _initialized = false;

  int totalWins = 0;
  int totalParries = 0;
  int totalDodges = 0;
  int totalBlocks = 0;
  int totalBroken = 0;
  int totalSynthTriggers = 0;
  int totalLogins = 0;
  int totalInkEarned = 0;
  int totalPaintEarned = 0;
  int totalExpItemsEarned = 0;
  int totalExtremeRotationsCleared = 0;
  int totalTournamentStagesCleared = 0;

  final Map<String, int> _buffer = {};

  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    _loadFromSP();
    if (_initialized) return;
    _initialized = true;

    GameEventBus.instance.on<VictoryEvent>().listen((event) {
      if (event.mode != BattleMode.tutorial) {
        _inc('totalWins');
        if (event.mode == BattleMode.tournament) {
          _inc('totalTournamentStagesCleared');
        }
      }
      _flushBattle();
    });

    GameEventBus.instance.on<DefeatEvent>().listen((event) {
      _flushBattle();
    });

    GameEventBus.instance.on<BattleQuitEvent>().listen((event) {
      _clearBattle();
    });

    GameEventBus.instance.on<ParrySuccessEvent>().listen((_) => _inc('totalParries'));
    GameEventBus.instance.on<DodgeSuccessEvent>().listen((_) => _inc('totalDodges'));
    GameEventBus.instance.on<BlockSuccessEvent>().listen((_) => _inc('totalBlocks'));
    GameEventBus.instance.on<BrokenEvent>().listen((_) => _inc('totalBroken'));
    GameEventBus.instance.on<SynthAbilityTriggeredEvent>().listen((_) => _inc('totalSynthTriggers'));
    
    GameEventBus.instance.on<ExtremeRotationClearedEvent>().listen((event) {
      _inc('totalExtremeRotationsCleared');
    });

    GameEventBus.instance.on<RewardGrantedEvent>().listen((event) {
      _incBy('totalInkEarned', event.inkDelta);
      _incBy('totalPaintEarned', event.paintDelta);
      int itemsSum = 0;
      event.itemDeltas.forEach((_, qty) {
        if (qty > 0) itemsSum += qty;
      });
      _incBy('totalExpItemsEarned', itemsSum);
    });
  }

  void startBattle() {
    _inBattle = true;
    _buffer.clear();
  }


  void _inc(String key) {
    if (_inBattle) {
      _buffer[key] = (_buffer[key] ?? 0) + 1;
    } else {
      _incDirect(key);
      _saveToSP();
    }
  }

  void _incBy(String key, int amount) {
    if (amount <= 0) return;
    if (_inBattle) {
      _buffer[key] = (_buffer[key] ?? 0) + amount;
    } else {
      _incDirectBy(key, amount);
      _saveToSP();
    }
  }

  void _incDirect(String key) {
    _incDirectBy(key, 1);
  }

  void _incDirectBy(String key, int amount) {
    switch (key) {
      case 'totalWins':
        totalWins += amount;
        break;
      case 'totalParries':
        totalParries += amount;
        break;
      case 'totalDodges':
        totalDodges += amount;
        break;
      case 'totalBlocks':
        totalBlocks += amount;
        break;
      case 'totalBroken':
        totalBroken += amount;
        break;
      case 'totalSynthTriggers':
        totalSynthTriggers += amount;
        break;
      case 'totalLogins':
        totalLogins += amount;
        break;
      case 'totalInkEarned':
        totalInkEarned += amount;
        break;
      case 'totalPaintEarned':
        totalPaintEarned += amount;
        break;
      case 'totalExpItemsEarned':
        totalExpItemsEarned += amount;
        break;
      case 'totalExtremeRotationsCleared':
        totalExtremeRotationsCleared += amount;
        break;
      case 'totalTournamentStagesCleared':
        totalTournamentStagesCleared += amount;
        break;
    }
  }

  void _flushBattle() {
    _buffer.forEach((key, amount) {
      _incDirectBy(key, amount);
    });
    _buffer.clear();
    _inBattle = false;
    _saveToSP();
  }

  void _clearBattle() {
    _buffer.clear();
    _inBattle = false;
  }

  void _loadFromSP() {
    final prefs = _prefs;
    if (prefs == null) return;
    final jsonStr = prefs.getString('colosynth_player_stats');
    if (jsonStr != null) {
      try {
        final Map<String, dynamic> map = jsonDecode(jsonStr);
        totalWins = map['totalWins'] ?? 0;
        totalParries = map['totalParries'] ?? 0;
        totalDodges = map['totalDodges'] ?? 0;
        totalBlocks = map['totalBlocks'] ?? 0;
        totalBroken = map['totalBroken'] ?? 0;
        totalSynthTriggers = map['totalSynthTriggers'] ?? 0;
        totalLogins = map['totalLogins'] ?? 0;
        totalInkEarned = map['totalInkEarned'] ?? 0;
        totalPaintEarned = map['totalPaintEarned'] ?? 0;
        totalExpItemsEarned = map['totalExpItemsEarned'] ?? 0;
        totalExtremeRotationsCleared = map['totalExtremeRotationsCleared'] ?? 0;
        totalTournamentStagesCleared = map['totalTournamentStagesCleared'] ?? 0;
      } catch (e) {
        debugPrint('PlayerStatsTracker load error: $e');
      }
    }
  }

  Future<void> _saveToSP() async {
    final prefs = _prefs;
    if (prefs == null) return;
    final map = {
      'totalWins': totalWins,
      'totalParries': totalParries,
      'totalDodges': totalDodges,
      'totalBlocks': totalBlocks,
      'totalBroken': totalBroken,
      'totalSynthTriggers': totalSynthTriggers,
      'totalLogins': totalLogins,
      'totalInkEarned': totalInkEarned,
      'totalPaintEarned': totalPaintEarned,
      'totalExpItemsEarned': totalExpItemsEarned,
      'totalExtremeRotationsCleared': totalExtremeRotationsCleared,
      'totalTournamentStagesCleared': totalTournamentStagesCleared,
    };
    await prefs.setString('colosynth_player_stats', jsonEncode(map));
  }


  Future<void> reload() async {
    totalWins = 0;
    totalParries = 0;
    totalDodges = 0;
    totalBlocks = 0;
    totalBroken = 0;
    totalSynthTriggers = 0;
    totalLogins = 0;
    totalInkEarned = 0;
    totalPaintEarned = 0;
    totalExpItemsEarned = 0;
    totalExtremeRotationsCleared = 0;
    totalTournamentStagesCleared = 0;
    _buffer.clear();
    _inBattle = false;
    _loadFromSP();
  }
}
