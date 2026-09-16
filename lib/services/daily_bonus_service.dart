import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyRewardService {
  DailyRewardService._();
  static final DailyRewardService instance = DailyRewardService._();

  static const _lastClaimKey = 'daily_reward_last_claim_ms';
  static const _streakKey = 'daily_reward_streak';

  DateTime? _lastClaim;
  int _streak = 0;
  bool _initialized = false;
  SharedPreferences? _prefs;

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final ms = _prefs!.getInt(_lastClaimKey);
      if (ms != null) {
        _lastClaim = DateTime.fromMillisecondsSinceEpoch(ms);
      }
      _streak = _prefs!.getInt(_streakKey) ?? 0;
      _maybeResetStreak();
      _initialized = true;
    } catch (e) {
      debugPrint('DailyRewardService init error: $e');
    }
  }

  void _maybeResetStreak() {
    if (_lastClaim == null) return;
    final now = DateTime.now().toUtc();
    final yesterday = DateTime.utc(now.year, now.month, now.day)
        .subtract(const Duration(days: 1));

    final lastClaimDay = DateTime.utc(
        _lastClaim!.year, _lastClaim!.month, _lastClaim!.day);
    if (lastClaimDay.isBefore(yesterday)) {
      _streak = 0;
    }
  }

  bool get isAvailable {
    if (!_initialized) return false;
    if (_lastClaim == null) return true;
    final now = DateTime.now().toUtc();
    final todayMidnight = DateTime.utc(now.year, now.month, now.day);
    return _lastClaim!.isBefore(todayMidnight);
  }

  int get currentStreak => _streak;

  Future<void> reload() async {
    _lastClaim = null;
    _streak = 0;
    _initialized = false;
    await init();
  }
}
