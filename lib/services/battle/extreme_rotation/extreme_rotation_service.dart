import 'dart:convert';
import 'package:colosynth/providers/exp_items_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:colosynth/game/event_bus/game_event_bus.dart';
import 'package:colosynth/game/event_bus/game_events.dart';
import 'package:colosynth/game_data/extreme_profile_data.dart';
import 'package:colosynth/providers/wallet_provider.dart';
import 'package:colosynth/providers/save_provider.dart';
import 'package:colosynth/services/save_manager.dart';

class ExtremeRotationState {
  final DateTime unlockedAt;
  final List<bool> clearedRotationSlots;
  final DateTime? lastDailyClearDate;

  ExtremeRotationState({
    required this.unlockedAt,
    required this.clearedRotationSlots,
    this.lastDailyClearDate,
  });

  factory ExtremeRotationState.fromJson(Map<String, dynamic> json) {
    final unlockedAtMs =
        json['unlockedAt'] as int? ?? DateTime.now().millisecondsSinceEpoch;
    final clearedList = json['clearedRotationSlots'] as List<dynamic>?;
    final cleared = clearedList != null
        ? List<bool>.from(clearedList.map((e) => e as bool))
        : List<bool>.filled(10, false);
    final lastClearMs = json['lastDailyClearDate'] as int?;

    return ExtremeRotationState(
      unlockedAt: DateTime.fromMillisecondsSinceEpoch(unlockedAtMs),
      clearedRotationSlots: cleared,
      lastDailyClearDate: lastClearMs != null
          ? DateTime.fromMillisecondsSinceEpoch(lastClearMs)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'unlockedAt': unlockedAt.millisecondsSinceEpoch,
      'clearedRotationSlots': clearedRotationSlots,
      'lastDailyClearDate': lastDailyClearDate?.millisecondsSinceEpoch,
    };
  }
}

class ExtremeRotationService {
  ExtremeRotationService._();
  static final ExtremeRotationService instance = ExtremeRotationService._();

  Ref? _ref;
  set ref(Ref? value) => _ref = value;

  ExtremeRotationState? _state;

  ExtremeRotationState get state {
    if (_state == null) {
      _loadState();
    }
    return _state!;
  }

  void _loadState() {
    try {
      final raw = SaveManager.instance.gameplay.loadExtremeStateRaw();
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        _state = ExtremeRotationState.fromJson(decoded);
      } else {
        _state = ExtremeRotationState(
          unlockedAt: DateTime.fromMillisecondsSinceEpoch(0),
          clearedRotationSlots: List<bool>.filled(10, false),
        );
      }
    } catch (e) {
      debugPrint('ExtremeRotationService load state error: $e');
      _state = ExtremeRotationState(
        unlockedAt: DateTime.fromMillisecondsSinceEpoch(0),
        clearedRotationSlots: List<bool>.filled(10, false),
      );
    }
  }

  Future<void> saveState(ExtremeRotationState state) async {
    _state = state;
    final raw = jsonEncode(state.toJson());
    await SaveManager.instance.gameplay.saveExtremeStateRaw(raw);
  }

  /// Refreshes/initializes rotation state on app launch.
  Future<void> refresh() async {
    _loadState();
  }

  /// Unlocks Extreme mode (should be called on T10 Final Boss first clear).
  Future<void> unlockExtremeMode() async {
    final currentState = state;
    if (currentState.unlockedAt.millisecondsSinceEpoch == 0) {
      final newState = ExtremeRotationState(
        unlockedAt: DateTime.now(),
        clearedRotationSlots: List<bool>.filled(10, false),
      );
      await saveState(newState);
    }
  }

  bool get isUnlocked {
    return state.unlockedAt.millisecondsSinceEpoch > 0;
  }

  int get currentSlotIndex {
    if (!isUnlocked) return 0;
    final now = DateTime.now();
    final daysSince = now.difference(state.unlockedAt).inDays;
    return (daysSince % 10).abs();
  }

  ExtremeProfileData get currentProfile {
    final idx = currentSlotIndex.clamp(0, kExtremeProfiles.length - 1);
    return kExtremeProfiles[idx];
  }

  bool _isDifferentCalendarDay(DateTime? dateA, DateTime dateB) {
    if (dateA == null) return true;
    return dateA.year != dateB.year ||
        dateA.month != dateB.month ||
        dateA.day != dateB.day;
  }

  Future<void> onExtremeClear(int rotationSlot) async {
    final currentState = state;
    final isFirstEver = !currentState.clearedRotationSlots[rotationSlot];
    final now = DateTime.now();
    final isFirstOfDay =
        _isDifferentCalendarDay(currentState.lastDailyClearDate, now);

    GameEventBus.instance.emit(const VictoryEvent(BattleMode.extreme));

    if (isFirstOfDay) {
      if (_ref != null) {
        await _ref!.read(walletProvider.notifier).awardMultiple(
              ink: 25000,
              paint: 10,
              source: 'tournament_extreme_daily',
            );
        await _ref!
            .read(expItemsProvider.notifier)
            .grant('exp_book_legendary', 2);
        await _ref!
            .read(expItemsProvider.notifier)
            .grant('exp_hammer_legendary', 2);
        await _ref!
            .read(expItemsProvider.notifier)
            .grant('exp_note_legendary', 2);
      }

      GameEventBus.instance.emit(const RewardGrantedEvent(
        source: 'tournament_extreme_daily',
        inkDelta: 25000,
        paintDelta: 10,
        accountXpDelta: 0,
        itemDeltas: {
          'exp_book_legendary': 2,
          'exp_hammer_legendary': 2,
          'exp_note_legendary': 2,
        },
      ));
    } else {
      final repeatInk = (5000 * 0.1).round().clamp(300, 999999);
      if (_ref != null) {
        await _ref!.read(walletProvider.notifier).award(
              Currency.ink,
              repeatInk,
              source: 'tournament_extreme_repeat',
            );
      }

      GameEventBus.instance.emit(RewardGrantedEvent(
        source: 'tournament_extreme_repeat',
        inkDelta: repeatInk,
        paintDelta: 0,
        accountXpDelta: 0,
        itemDeltas: const {},
      ));
    }

    final newClearedSlots = List<bool>.from(currentState.clearedRotationSlots);
    if (isFirstEver) {
      newClearedSlots[rotationSlot] = true;
    }
    final newDailyClearDate = isFirstOfDay ? now : currentState.lastDailyClearDate;

    final newState = ExtremeRotationState(
      unlockedAt: currentState.unlockedAt,
      clearedRotationSlots: newClearedSlots,
      lastDailyClearDate: newDailyClearDate,
    );
    await saveState(newState);

    if (isFirstEver) {
      GameEventBus.instance.emit(ExtremeRotationClearedEvent(
        rotationSlot + 1,
        isFirstOfDay,
        true,
      ));

      if (newState.clearedRotationSlots.every((c) => c)) {
        await SaveManager.instance.account.unlockCharacter('char_12');
        GameEventBus.instance.emit(const CharacterRecruitedEvent('char_12'));
      }
    }
  }


  Map<String, dynamic> _loadExtremeAdAttemptsMap() {
    final now = DateTime.now();
    try {
      final raw = SaveManager.instance.gameplay.loadExtremeAdAttemptsRaw();
      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final lastMs = map['lastDate'] as int?;
        if (lastMs != null) {
          final lastDate = DateTime.fromMillisecondsSinceEpoch(lastMs);
          if (lastDate.year == now.year && lastDate.month == now.month && lastDate.day == now.day) {
            return map;
          }
        }
      }
    } catch (_) {}
    return {'lastDate': now.millisecondsSinceEpoch, 'totalAdsToday': 0, 'slotsUnlocked': <String, int>{}};
  }

  int getTodayExtremeAdCount() {
    final map = _loadExtremeAdAttemptsMap();
    return map['totalAdsToday'] as int? ?? 0;
  }

  bool hasUnlockedExtraAttemptForSlotToday(int slotIndex) {
    final map = _loadExtremeAdAttemptsMap();
    final slotsMap = map['slotsUnlocked'] as Map<String, dynamic>? ?? {};
    return (slotsMap['slot_$slotIndex'] as int? ?? 0) > 0;
  }

  bool canUnlockExtraAttemptWithAd(int slotIndex) {
    if (hasUnlockedExtraAttemptForSlotToday(slotIndex)) return false;
    final extremeCap = SaveManager.instance.isInitialized ? 5 : 5;
    if (getTodayExtremeAdCount() >= extremeCap) return false;
    return true;
  }

  Future<bool> unlockExtraAttemptWithAd(int slotIndex) async {
    if (!canUnlockExtraAttemptWithAd(slotIndex)) return false;

    final now = DateTime.now();
    final map = _loadExtremeAdAttemptsMap();
    final slotsMap = Map<String, dynamic>.from(map['slotsUnlocked'] as Map<String, dynamic>? ?? {});
    slotsMap['slot_$slotIndex'] = (slotsMap['slot_$slotIndex'] as int? ?? 0) + 1;

    final newTotal = (map['totalAdsToday'] as int? ?? 0) + 1;

    final newMap = {
      'lastDate': now.millisecondsSinceEpoch,
      'totalAdsToday': newTotal,
      'slotsUnlocked': slotsMap,
    };

    await SaveManager.instance.gameplay.saveExtremeAdAttemptsRaw(jsonEncode(newMap));
    return true;
  }
}
