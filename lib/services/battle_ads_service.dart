import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:colosynth/utils/app_logger.dart';
import 'package:colosynth/utils/date_utils.dart';
import 'package:colosynth/services/rewarded_ad_service.dart';


class BattleAdsService {
  BattleAdsService._();
  static final BattleAdsService instance = BattleAdsService._();

  static const _kDoubleRewardDateKey = 'colosynth_double_reward_date';
  static const _kDoubleRewardCountKey = 'colosynth_double_reward_count';
  static const int maxDoubleRewardsPerDay = 2;

  SharedPreferences? _prefs;
  int _doubleRewardCount = 0;
  String _doubleRewardDate = '';

  Future<void> init() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final today = AppDateUtils.todayKey();
      _doubleRewardDate = _prefs!.getString(_kDoubleRewardDateKey) ?? '';
      if (_doubleRewardDate != today) {
        _doubleRewardCount = 0;
        _doubleRewardDate = today;
        await _prefs!.setString(_kDoubleRewardDateKey, today);
        await _prefs!.setInt(_kDoubleRewardCountKey, 0);
      } else {
        _doubleRewardCount = _prefs!.getInt(_kDoubleRewardCountKey) ?? 0;
      }
    } catch (e, stack) {
      AppLogger.e('BattleAdsService', 'init error: $e', stack);
    }
  }

  /// Whether the player can still claim a double reward today.
  bool get canShowDoubleReward => true;

  /// How many double-reward claims remain today (unlimited).
  int get remainingDoubleRewards => 999;

  void _refreshIfNewDay() {
    final today = AppDateUtils.todayKey();
    if (_doubleRewardDate != today) {
      _doubleRewardCount = 0;
      _doubleRewardDate = today;
      _prefs?.setString(_kDoubleRewardDateKey, today);
      _prefs?.setInt(_kDoubleRewardCountKey, 0);
    }
  }


  /// Shows a rewarded ad for doubling battle rewards without daily cap.
  Future<bool> showDoubleRewardAd({
    required VoidCallback onRewarded,
    VoidCallback? onDismissed,
  }) async {
    _refreshIfNewDay();

    bool rewarded = false;
    final shown = await RewardedAdService.instance.showAd(
      onRewarded: () {
        rewarded = true;
        _doubleRewardCount++;
        _prefs?.setInt(_kDoubleRewardCountKey, _doubleRewardCount);
        AppLogger.d('BattleAdsService', 'Double reward claimed. Count today: $_doubleRewardCount');
        onRewarded();
      },
      onDismissed: onDismissed,
    );

    return shown && rewarded;
  }
}
