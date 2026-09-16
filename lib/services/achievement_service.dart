import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:games_services/games_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:colosynth/providers/save_provider.dart';
import 'package:colosynth/utils/async_mutex.dart';

class AchievementIds {
  static const String login7 = 'colosynth_login_7';
  static const String login30 = 'colosynth_login_30';
  static const String tournamentT1 = 'colosynth_tournament_t1';
  static const String tournamentT2 = 'colosynth_tournament_t2';
  static const String tournamentT3 = 'colosynth_tournament_t3';
  static const String tournamentT4 = 'colosynth_tournament_t4';
  static const String tournamentT5 = 'colosynth_tournament_t5';
  static const String tournamentT6 = 'colosynth_tournament_t6';
  static const String tournamentT7 = 'colosynth_tournament_t7';
  static const String tournamentT8 = 'colosynth_tournament_t8';
  static const String tournamentT9 = 'colosynth_tournament_t9';
  static const String tournamentT10 = 'colosynth_tournament_t10';
  static const String characterLv30 = 'colosynth_char_lv30';
  static const String characterLv60 = 'colosynth_char_lv60';
  static const String characterLv90 = 'colosynth_char_lv90';
  static const String equipLv30 = 'colosynth_equip_lv30';
  static const String equipLv60 = 'colosynth_equip_lv60';
  static const String equipLv90 = 'colosynth_equip_lv90';
  static const String synthLv10 = 'colosynth_synth_lv10';
  static const String synthLv30 = 'colosynth_synth_lv30';
  static const String synthLv60 = 'colosynth_synth_lv60';
  static const String synthLv90 = 'colosynth_synth_lv90';
  static const String firstWin = 'colosynth_first_win';
}

class AchievementReward {
  const AchievementReward({required this.ink, required this.paint});
  final int ink;
  final int paint;
}

abstract final class AchievementRewards {
  static const Map<String, AchievementReward> all = {
    AchievementIds.login7: AchievementReward(ink: 0, paint: 5),
    AchievementIds.login30: AchievementReward(ink: 0, paint: 10),
    AchievementIds.tournamentT1: AchievementReward(ink: 2000, paint: 15),
    AchievementIds.tournamentT2: AchievementReward(ink: 2500, paint: 15),
    AchievementIds.tournamentT3: AchievementReward(ink: 3000, paint: 20),
    AchievementIds.tournamentT4: AchievementReward(ink: 3500, paint: 20),
    AchievementIds.tournamentT5: AchievementReward(ink: 4000, paint: 20),
    AchievementIds.tournamentT6: AchievementReward(ink: 4500, paint: 20),
    AchievementIds.tournamentT7: AchievementReward(ink: 5000, paint: 20),
    AchievementIds.tournamentT8: AchievementReward(ink: 5500, paint: 20),
    AchievementIds.tournamentT9: AchievementReward(ink: 6000, paint: 25),
    AchievementIds.tournamentT10: AchievementReward(ink: 8000, paint: 25),
    AchievementIds.characterLv30: AchievementReward(ink: 0, paint: 2),
    AchievementIds.characterLv60: AchievementReward(ink: 0, paint: 3),
    AchievementIds.characterLv90: AchievementReward(ink: 0, paint: 5),
    AchievementIds.equipLv30: AchievementReward(ink: 0, paint: 2),
    AchievementIds.equipLv60: AchievementReward(ink: 0, paint: 3),
    AchievementIds.equipLv90: AchievementReward(ink: 0, paint: 5),
    AchievementIds.synthLv10: AchievementReward(ink: 0, paint: 1),
    AchievementIds.synthLv30: AchievementReward(ink: 0, paint: 2),
    AchievementIds.synthLv60: AchievementReward(ink: 0, paint: 3),
    AchievementIds.synthLv90: AchievementReward(ink: 0, paint: 5),
    AchievementIds.firstWin: AchievementReward(ink: 1000, paint: 2),
  };
}

class AchievementService {
  AchievementService._();
  static final AchievementService instance = AchievementService._();

  static const String _kLastAutoSignInPromptKey = 'last_play_games_auto_signin_prompt_ts';
  static const Duration _autoSignInCooldown = Duration(hours: 24);

  Ref? _ref;
  bool _signedIn = false;
  bool get isSignedIn => _signedIn;

  Future<bool> checkAuthStatus() async {
    try {
      _signedIn = await GameAuth.isSignedIn;
    } catch (_) {
      _signedIn = false;
    }
    return _signedIn;
  }

  /// Sign in to Google Play Games / Game Center.
  /// If [manual] is true, triggers native sign-in prompt regardless of cooldown.
  /// If [manual] is false (auto-start / warm start), checks silent status first
  /// and throttles automatic prompts to once every 24 hours to avoid annoying popups.
  Future<bool> signIn({bool manual = false}) async {
    if (await checkAuthStatus()) {
      return true;
    }

    if (!manual) {
      final prefs = await SharedPreferences.getInstance();
      final lastPrompt = prefs.getInt(_kLastAutoSignInPromptKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - lastPrompt < _autoSignInCooldown.inMilliseconds) {
        return false;
      }
      await prefs.setInt(_kLastAutoSignInPromptKey, now);
    }

    try {
      await GameAuth.signIn();
      _signedIn = await GameAuth.isSignedIn;
      return _signedIn;
    } catch (_) {
      _signedIn = false;
      return false;
    }
  }

  Future<void> signOut() async {
    _signedIn = false;
  }

  final _unlockMutex = AsyncMutex();

  Future<void> unlock(String achievementId) async {
    await _unlockMutex.protect(() async {
      if (_signedIn) {
        try {
          await GamesServices.unlock(
              achievement: Achievement(androidID: achievementId));
        } catch (_) {}
      }

      final prefs = await SharedPreferences.getInstance();
      final claimed = prefs.getStringList('rewarded_achievements_v1') ?? [];
      if (claimed.contains(achievementId)) return;

      claimed.add(achievementId);
      await prefs.setStringList('rewarded_achievements_v1', claimed);

      final reward = rewardFor(achievementId);
      if (reward != null && _ref != null) {
        try {
          if (reward.ink > 0 || reward.paint > 0) {
            await _ref!.read(walletProvider.notifier).awardMultiple(
                  ink: reward.ink,
                  paint: reward.paint,
                  source: 'achievement',
                );
          }
        } catch (_) {}
      }
    });
  }

  Future<void> increment(String achievementId, int steps) async {
    if (!_signedIn) return;
    await GamesServices.increment(
      achievement: Achievement(androidID: achievementId, steps: steps),
    );
  }

  Future<void> showAchievements() async {
    if (!_signedIn) return;
    await GamesServices.showAchievements();
  }

  AchievementReward? rewardFor(String achievementId) =>
      AchievementRewards.all[achievementId];

  Future<void> checkCharLevelAchievements(int charLevel) async {
    if (charLevel >= 30) await unlock(AchievementIds.characterLv30);
    if (charLevel >= 60) await unlock(AchievementIds.characterLv60);
    if (charLevel >= 90) await unlock(AchievementIds.characterLv90);
  }

  Future<void> checkEquipLevelAchievements(int equipLevel) async {
    if (equipLevel >= 30) await unlock(AchievementIds.equipLv30);
    if (equipLevel >= 60) await unlock(AchievementIds.equipLv60);
    if (equipLevel >= 90) await unlock(AchievementIds.equipLv90);
  }

  Future<void> checkSynthLevelAchievements(int synthLevel) async {
    if (synthLevel >= 10) await unlock(AchievementIds.synthLv10);
    if (synthLevel >= 30) await unlock(AchievementIds.synthLv30);
    if (synthLevel >= 60) await unlock(AchievementIds.synthLv60);
    if (synthLevel >= 90) await unlock(AchievementIds.synthLv90);
  }

  Future<void> checkLoginAchievements(int consecDays) async {
    if (consecDays >= 7) await unlock(AchievementIds.login7);
    if (consecDays >= 30) await unlock(AchievementIds.login30);
  }

  Future<void> checkTournamentAchievements(int highestTier) async {
    if (highestTier >= 1) await unlock(AchievementIds.tournamentT1);
    if (highestTier >= 2) await unlock(AchievementIds.tournamentT2);
    if (highestTier >= 3) await unlock(AchievementIds.tournamentT3);
    if (highestTier >= 4) await unlock(AchievementIds.tournamentT4);
    if (highestTier >= 5) await unlock(AchievementIds.tournamentT5);
    if (highestTier >= 6) await unlock(AchievementIds.tournamentT6);
    if (highestTier >= 7) await unlock(AchievementIds.tournamentT7);
    if (highestTier >= 8) await unlock(AchievementIds.tournamentT8);
    if (highestTier >= 9) await unlock(AchievementIds.tournamentT9);
    if (highestTier >= 10) await unlock(AchievementIds.tournamentT10);
  }
}

final achievementServiceProvider = Provider<AchievementService>((ref) {
  final service = AchievementService.instance;
  service._ref = ref;
  return service;
});
