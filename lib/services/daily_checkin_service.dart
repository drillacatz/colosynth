import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:colosynth/services/save_manager.dart';
import 'package:colosynth/services/remote_config_service.dart';
import 'package:colosynth/providers/wallet_provider.dart';
import 'package:colosynth/providers/exp_items_provider.dart';
import 'package:colosynth/game/event_bus/game_event_bus.dart';
import 'package:colosynth/game/event_bus/game_events.dart';

class CheckInReward {
  final int day;
  final int ink;
  final int paint;
  final String? itemKey;
  final int itemCount;
  final String label;

  const CheckInReward({
    required this.day,
    this.ink = 0,
    this.paint = 0,
    this.itemKey,
    this.itemCount = 0,
    required this.label,
  });
}

class DailyCheckInState {
  final int currentCycleDay;
  final DateTime? lastCheckInDate;
  final DateTime? lastDoubleClaimDate;
  final bool isClaimedToday;
  final bool isDoubleClaimedToday;
  final int makeUpUsedInCycle;
  final int advanceClaimUsedInCycle;
  final bool isAdvanceClaimedTomorrow;
  final bool missedYesterday;

  const DailyCheckInState({
    required this.currentCycleDay,
    this.lastCheckInDate,
    this.lastDoubleClaimDate,
    required this.isClaimedToday,
    required this.isDoubleClaimedToday,
    required this.makeUpUsedInCycle,
    required this.advanceClaimUsedInCycle,
    required this.isAdvanceClaimedTomorrow,
    required this.missedYesterday,
  });

  factory DailyCheckInState.initial() {
    return const DailyCheckInState(
      currentCycleDay: 1,
      lastCheckInDate: null,
      lastDoubleClaimDate: null,
      isClaimedToday: false,
      isDoubleClaimedToday: false,
      makeUpUsedInCycle: 0,
      advanceClaimUsedInCycle: 0,
      isAdvanceClaimedTomorrow: false,
      missedYesterday: false,
    );
  }

  factory DailyCheckInState.fromJson(Map<String, dynamic> json, DateTime now) {
    final day = (json['currentCycleDay'] as int? ?? 1).clamp(1, 7);
    final lastMs = json['lastCheckInDate'] as int?;
    final lastDate = lastMs != null ? DateTime.fromMillisecondsSinceEpoch(lastMs) : null;
    final makeUpUsed = json['makeUpUsedInCycle'] as int? ?? 0;
    final advanceUsed = json['advanceClaimUsedInCycle'] as int? ?? 0;
    final isAdvTomorrow = json['isAdvanceClaimedTomorrow'] as bool? ?? false;
    final doubleClaimedMs = json['lastDoubleClaimDate'] as int?;
    final doubleClaimDate = doubleClaimedMs != null ? DateTime.fromMillisecondsSinceEpoch(doubleClaimedMs) : null;

    final isSameDay = _isSameCalendarDay(lastDate, now);
    final isYesterday = _isYesterday(lastDate, now);

    final bool claimedToday = isSameDay;
    final bool doubleClaimedToday = _isSameCalendarDay(doubleClaimDate, now);
    bool missed = false;
    final int cycleDay = day;

    if (lastDate != null && !isSameDay && !isYesterday && !isAdvTomorrow) {
      missed = true;
    }

    return DailyCheckInState(
      currentCycleDay: cycleDay,
      lastCheckInDate: lastDate,
      lastDoubleClaimDate: doubleClaimDate,
      isClaimedToday: claimedToday,
      isDoubleClaimedToday: doubleClaimedToday,
      makeUpUsedInCycle: makeUpUsed,
      advanceClaimUsedInCycle: advanceUsed,
      isAdvanceClaimedTomorrow: isAdvTomorrow,
      missedYesterday: missed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentCycleDay': currentCycleDay,
      'lastCheckInDate': lastCheckInDate?.millisecondsSinceEpoch,
      'lastDoubleClaimDate': lastDoubleClaimDate?.millisecondsSinceEpoch,
      'makeUpUsedInCycle': makeUpUsedInCycle,
      'advanceClaimUsedInCycle': advanceClaimUsedInCycle,
      'isAdvanceClaimedTomorrow': isAdvanceClaimedTomorrow,
    };
  }

  static bool _isSameCalendarDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool _isYesterday(DateTime? last, DateTime now) {
    if (last == null) return false;
    final yesterday = now.subtract(const Duration(days: 1));
    return _isSameCalendarDay(last, yesterday);
  }
}

class DailyCheckInService {
  DailyCheckInService._();
  static final DailyCheckInService instance = DailyCheckInService._();

  static const List<CheckInReward> rewardsSchedule = [
    CheckInReward(day: 1, ink: 200, label: '200 Ink'),
    CheckInReward(day: 2, ink: 500, label: '500 Ink'),
    CheckInReward(day: 3, paint: 5, label: '5 Paint'),
    CheckInReward(day: 4, itemKey: 'exp_book_rare', itemCount: 2, label: '2x EXP Boost'),
    CheckInReward(day: 5, ink: 200, label: '200 Ink'),
    CheckInReward(day: 6, paint: 5, label: '5 Paint'),
    CheckInReward(day: 7, ink: 700, label: '700 Ink'),
  ];

  DailyCheckInState? _state;

  DailyCheckInState get state {
    if (_state == null) {
      refreshState();
    }
    return _state!;
  }

  void refreshState() {
    final now = DateTime.now();
    try {
      final raw = SaveManager.instance.gameplay.loadDailyCheckInStateRaw();
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        _state = DailyCheckInState.fromJson(decoded, now);
      } else {
        _state = DailyCheckInState.initial();
      }
    } catch (e) {
      debugPrint('DailyCheckInService load state error: $e');
      _state = DailyCheckInState.initial();
    }
  }

  Future<void> _saveState(DailyCheckInState newState) async {
    _state = newState;
    final raw = jsonEncode(newState.toJson());
    await SaveManager.instance.gameplay.saveDailyCheckInStateRaw(raw);
  }


  int getTodayRewardedAdCount() {
    final now = DateTime.now();
    try {
      final raw = SaveManager.instance.gameplay.loadAdSafetyValveStateRaw();
      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final lastMs = map['lastAdDate'] as int?;
        if (lastMs != null) {
          final lastDate = DateTime.fromMillisecondsSinceEpoch(lastMs);
          if (lastDate.year == now.year && lastDate.month == now.month && lastDate.day == now.day) {
            return map['count'] as int? ?? 0;
          }
        }
      }
    } catch (_) {}
    return 0;
  }

  bool canWatchRewardedAd() => true;

  Future<void> recordRewardedAdWatched() async {
    final now = DateTime.now();
    final currentCount = getTodayRewardedAdCount();
    final newCount = currentCount + 1;
    final map = {
      'lastAdDate': now.millisecondsSinceEpoch,
      'count': newCount,
    };
    await SaveManager.instance.gameplay.saveAdSafetyValveStateRaw(jsonEncode(map));
  }


  CheckInReward getRewardForDay(int day) {
    final idx = (day - 1).clamp(0, rewardsSchedule.length - 1);
    return rewardsSchedule[idx];
  }

  Future<bool> claimToday({dynamic ref}) async {
    final current = state;
    if (current.isClaimedToday) return false;

    int cycleDay = current.currentCycleDay;

    if (current.missedYesterday) {
      cycleDay = 1;
    }

    final reward = getRewardForDay(cycleDay);

    await _grantReward(reward, ref: ref, multiplier: 1);

    final now = DateTime.now();
    int nextCycleDay = cycleDay + 1;
    int makeUpCount = current.makeUpUsedInCycle;
    int advanceCount = current.advanceClaimUsedInCycle;

    if (nextCycleDay > 7) {
      nextCycleDay = 1;
      makeUpCount = 0;
      advanceCount = 0;
    }

    final newState = DailyCheckInState(
      currentCycleDay: nextCycleDay,
      lastCheckInDate: now,
      isClaimedToday: true,
      isDoubleClaimedToday: false,
      makeUpUsedInCycle: makeUpCount,
      advanceClaimUsedInCycle: advanceCount,
      isAdvanceClaimedTomorrow: false,
      missedYesterday: false,
    );

    await _saveState(newState);
    return true;
  }

  Future<bool> claimDoubleWithAd({dynamic ref}) async {
    final current = state;
    if (!current.isClaimedToday || current.isDoubleClaimedToday) return false;

    int claimedDay = current.currentCycleDay - 1;
    if (claimedDay < 1) claimedDay = 7;

    final reward = getRewardForDay(claimedDay);
    await _grantReward(reward, ref: ref, multiplier: 1, sourceSuffix: '_double');

    await recordRewardedAdWatched();

    final now = DateTime.now();
    final newState = DailyCheckInState(
      currentCycleDay: current.currentCycleDay,
      lastCheckInDate: current.lastCheckInDate,
      lastDoubleClaimDate: now,
      isClaimedToday: true,
      isDoubleClaimedToday: true,
      makeUpUsedInCycle: current.makeUpUsedInCycle,
      advanceClaimUsedInCycle: current.advanceClaimUsedInCycle,
      isAdvanceClaimedTomorrow: current.isAdvanceClaimedTomorrow,
      missedYesterday: false,
    );

    await _saveState(newState);
    return true;
  }

  Future<bool> claimTodayWithDoubleAd({dynamic ref}) async {
    final current = state;
    if (current.isClaimedToday && current.isDoubleClaimedToday) return false;

    if (current.isClaimedToday && !current.isDoubleClaimedToday) {
      return claimDoubleWithAd(ref: ref);
    }

    int cycleDay = current.currentCycleDay;
    if (current.missedYesterday) {
      cycleDay = 1;
    }

    final reward = getRewardForDay(cycleDay);
    await _grantReward(reward, ref: ref, multiplier: 2, sourceSuffix: '_double');
    await recordRewardedAdWatched();

    final now = DateTime.now();
    int nextCycleDay = cycleDay + 1;
    int makeUpCount = current.makeUpUsedInCycle;
    int advanceCount = current.advanceClaimUsedInCycle;

    if (nextCycleDay > 7) {
      nextCycleDay = 1;
      makeUpCount = 0;
      advanceCount = 0;
    }

    final newState = DailyCheckInState(
      currentCycleDay: nextCycleDay,
      lastCheckInDate: now,
      lastDoubleClaimDate: now,
      isClaimedToday: true,
      isDoubleClaimedToday: true,
      makeUpUsedInCycle: makeUpCount,
      advanceClaimUsedInCycle: advanceCount,
      isAdvanceClaimedTomorrow: false,
      missedYesterday: false,
    );

    await _saveState(newState);
    return true;
  }

  Future<bool> makeUpWithAd({dynamic ref}) async {
    final current = state;
    if (!current.missedYesterday) return false;
    final limit = RemoteConfigService.instance.dailyCheckinMakeupLimit;
    if (current.makeUpUsedInCycle >= limit) return false;
    if (!canWatchRewardedAd()) return false;

    final reward = getRewardForDay(current.currentCycleDay);
    await _grantReward(reward, ref: ref, multiplier: 1, sourceSuffix: '_makeup');

    await recordRewardedAdWatched();

    final now = DateTime.now();
    int nextCycleDay = current.currentCycleDay + 1;
    int makeUpCount = current.makeUpUsedInCycle + 1;
    int advanceCount = current.advanceClaimUsedInCycle;

    if (nextCycleDay > 7) {
      nextCycleDay = 1;
      makeUpCount = 0;
      advanceCount = 0;
    }

    final newState = DailyCheckInState(
      currentCycleDay: nextCycleDay,
      lastCheckInDate: now,
      isClaimedToday: true,
      isDoubleClaimedToday: false,
      makeUpUsedInCycle: makeUpCount,
      advanceClaimUsedInCycle: advanceCount,
      isAdvanceClaimedTomorrow: false,
      missedYesterday: false,
    );

    await _saveState(newState);
    return true;
  }

  Future<bool> claimTomorrowWithAd({dynamic ref}) async {
    final current = state;
    if (!current.isClaimedToday || current.isAdvanceClaimedTomorrow) return false;
    final limit = RemoteConfigService.instance.dailyCheckinAdvanceLimit;
    if (current.advanceClaimUsedInCycle >= limit) return false;
    if (!canWatchRewardedAd()) return false;

    final int tomorrowDay = current.currentCycleDay;
    final reward = getRewardForDay(tomorrowDay);

    await _grantReward(reward, ref: ref, multiplier: 1, sourceSuffix: '_advance');

    await recordRewardedAdWatched();

    int nextCycleDay = tomorrowDay + 1;
    int makeUpCount = current.makeUpUsedInCycle;
    int advanceCount = current.advanceClaimUsedInCycle + 1;

    if (nextCycleDay > 7) {
      nextCycleDay = 1;
      makeUpCount = 0;
      advanceCount = 0;
    }

    final newState = DailyCheckInState(
      currentCycleDay: nextCycleDay,
      lastCheckInDate: current.lastCheckInDate,
      isClaimedToday: true,
      isDoubleClaimedToday: current.isDoubleClaimedToday,
      makeUpUsedInCycle: makeUpCount,
      advanceClaimUsedInCycle: advanceCount,
      isAdvanceClaimedTomorrow: true,
      missedYesterday: false,
    );

    await _saveState(newState);
    return true;
  }

  Future<void> _grantReward(CheckInReward reward, {dynamic ref, int multiplier = 1, String sourceSuffix = ''}) async {
    final source = 'daily_checkin_day_${reward.day}$sourceSuffix';
    final totalInk = reward.ink * multiplier;
    final totalPaint = reward.paint * multiplier;
    final totalItemCount = reward.itemCount * multiplier;

    if (ref != null) {
      if (totalInk > 0 || totalPaint > 0) {
        await ref.read(walletProvider.notifier).awardMultiple(
          ink: totalInk,
          paint: totalPaint,
          source: source,
        );
      }
      if (reward.itemKey != null && totalItemCount > 0) {
        await ref.read(expItemsProvider.notifier).grant(reward.itemKey!, totalItemCount);
      }
    } else {
      if (totalInk > 0) {
        await SaveManager.instance.account.awardInk(totalInk, source: source);
      }
      if (totalPaint > 0) {
        await SaveManager.instance.account.awardPaint(totalPaint, source: source);
      }
      if (reward.itemKey != null && totalItemCount > 0) {
        await SaveManager.instance.gameplay.addExpItem(reward.itemKey!, totalItemCount);
      }
    }

    GameEventBus.instance.emit(RewardGrantedEvent(
      source: source,
      inkDelta: totalInk,
      paintDelta: totalPaint,
      accountXpDelta: 0,
      itemDeltas: reward.itemKey != null ? {reward.itemKey!: totalItemCount} : const {},
    ));
  }
}
