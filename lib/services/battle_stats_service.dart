import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:colosynth/game/app_shell/battle_result.dart';
import 'package:colosynth/game_settings.dart';
import 'package:colosynth/services/audio_service.dart';

import 'package:colosynth/services/sp_manager.dart';

class BattleStatsTracker {
  int _parryCount = 0;
  int _dodgeCount = 0;
  int _brokenCount = 0;
  int _skillUseCount = 0;
  int _currentCombo = 0;
  int _maxCombo = 0;
  BattleOutcome? _outcome;

  int get parryCount => _parryCount;
  int get dodgeCount => _dodgeCount;
  int get brokenCount => _brokenCount;
  int get skillUseCount => _skillUseCount;
  int get currentCombo => _currentCombo;
  int get maxCombo => _maxCombo;
  BattleOutcome? get outcome => _outcome;

  void recordParry() => _parryCount++;
  void recordSuccessfulDodge() => _dodgeCount++;
  void recordBroken() => _brokenCount++;
  void recordSkillUse() => _skillUseCount++;
  void recordHit() {
    _currentCombo++;
    if (_currentCombo > _maxCombo) _maxCombo = _currentCombo;
    AudioService.instance.playSfx(SfxEvent.combo);
  }

  void resetCombo() => _currentCombo = 0;
  void recordOutcome(BattleOutcome outcome) => _outcome = outcome;

  void reset() {
    _parryCount = 0;
    _dodgeCount = 0;
    _brokenCount = 0;
    _skillUseCount = 0;
    _currentCombo = 0;
    _maxCombo = 0;
    _outcome = null;
  }
}

class BattleStatsService {
  BattleStatsService._();
  static final BattleStatsService instance = BattleStatsService._();

  static const int _characterScreenThreshold = 2;

  int _gamesPlayed = 0;
  int _totalBattles = 0;
  int _totalWins = 0;
  int _totalParries = 0;
  int _totalBroken = 0;
  int _longestWinStreak = 0;
  int _currentWinStreak = 0;
  int _consecLogins = 0;
  final Map<String, int> _tournamentWins = {};
  SharedPreferences? _prefs;

  int get gamesPlayed => _gamesPlayed;
  int get totalBattles => _totalBattles;
  int get totalWins => _totalWins;
  int get totalParries => _totalParries;
  int get totalBroken => _totalBroken;
  int get longestWinStreak => _longestWinStreak;
  int get currentWinStreak => _currentWinStreak;
  int get consecutiveLogins => _consecLogins;
  int get totalTournamentWins =>
      _tournamentWins.values.fold(0, (sum, val) => sum + val);

  int tournamentWins(String tier) => _tournamentWins[tier.toLowerCase()] ?? 0;

  bool get isCharacterScreenUnlocked =>
      _gamesPlayed >= _characterScreenThreshold;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final prefs = _prefs!;
    _gamesPlayed = prefs.getInt(SPKeys.gamesPlayed) ?? 0;
    _totalBattles = prefs.getInt(SPKeys.totalBattles) ?? 0;
    _totalWins = prefs.getInt(SPKeys.totalWins) ?? 0;
    _totalParries = prefs.getInt(SPKeys.totalParries) ?? 0;
    _totalBroken = prefs.getInt(SPKeys.totalBroken) ?? 0;
    _longestWinStreak = prefs.getInt(SPKeys.longestWinStreak) ?? 0;
    _currentWinStreak = prefs.getInt(SPKeys.currentWinStreak) ?? 0;
    _consecLogins = prefs.getInt(SPKeys.totalLogins) ?? 0;


    const tiers = ['easy', 'medium', 'hard', 'extreme'];
    for (final t in tiers) {
      _tournamentWins[t] = prefs.getInt('${SPKeys.tournamentWinsPrefix}$t') ?? 0;
    }
  }



  Future<void> reload() => init();


  Future<void> recordBattle({
    BattleResult? result,
    String? tournamentTierName,
  }) async {
    _totalBattles++;
    _gamesPlayed++;

    final isVictory = result?.outcome == BattleOutcome.victory;

    if (isVictory) {
      _totalWins++;
      _currentWinStreak++;
      if (_currentWinStreak > _longestWinStreak) {
        _longestWinStreak = _currentWinStreak;
      }

      if (tournamentTierName != null) {
        final key = tournamentTierName.toLowerCase();
        _tournamentWins[key] = (_tournamentWins[key] ?? 0) + 1;
      }
    } else {
      _currentWinStreak = 0;
    }

    if (result != null) {
      _totalParries += result.parryCount;
      _totalBroken += result.brokenCount;



    }

    _prefs ??= await SharedPreferences.getInstance();
    final prefs = _prefs!;
    final futures = [
      prefs.setInt(SPKeys.totalBattles, _totalBattles),
      prefs.setInt(SPKeys.gamesPlayed, _gamesPlayed),
      prefs.setInt(SPKeys.totalWins, _totalWins),
      prefs.setInt(SPKeys.totalParries, _totalParries),
      prefs.setInt(SPKeys.totalBroken, _totalBroken),
      prefs.setInt(SPKeys.longestWinStreak, _longestWinStreak),
      prefs.setInt(SPKeys.currentWinStreak, _currentWinStreak),
    ];

    if (tournamentTierName != null) {
      final key = tournamentTierName.toLowerCase();
      futures.add(prefs.setInt(
          '${SPKeys.tournamentWinsPrefix}$key', _tournamentWins[key] ?? 0));
    }

    await Future.wait(futures);
  }


  Future<int> recordLogin(int consecDays) async {
    _consecLogins = consecDays;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setInt(SPKeys.totalLogins, _consecLogins);
    return _consecLogins;
  }
}

final battleStatsServiceProvider =
    Provider<BattleStatsService>((_) => BattleStatsService.instance);
