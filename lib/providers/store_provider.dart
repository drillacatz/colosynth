import 'dart:async';
import 'package:colosynth/providers/exp_items_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:colosynth/game_data/store_data.dart';
import 'package:colosynth/services/iap_service.dart';
import 'package:colosynth/services/rewarded_ad_service.dart';
import 'package:colosynth/services/daily_refresh_service.dart';
import 'package:colosynth/providers/save_provider.dart';
import 'package:colosynth/providers/service_providers.dart';
import 'package:colosynth/utils/date_utils.dart';
import 'package:colosynth/game/event_bus/game_event_bus.dart';
import 'package:colosynth/game/event_bus/game_events.dart';

class StoreSectionNotifier extends Notifier<StoreSection> {
  @override
  StoreSection build() => StoreSection.ink;

  void setSection(StoreSection section) => state = section;
}

final storeSectionProvider =
    NotifierProvider<StoreSectionNotifier, StoreSection>(
  StoreSectionNotifier.new,
);

class AdFreeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    await IapService.instance.init();

    final subscription = IapService.instance.customerInfoStream.listen((info) {
      Future.microtask(() {
        state = AsyncData(info.entitlements.active.containsKey('ad_free'));
      });
    });
    ref.onDispose(subscription.cancel);

    return IapService.instance.adFreeActive;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await IapService.instance.restorePurchases();
      return IapService.instance.adFreeActive;
    });
  }
}

final adFreeProvider =
    AsyncNotifierProvider<AdFreeNotifier, bool>(AdFreeNotifier.new);

class DailyInkSlotState {
  const DailyInkSlotState({
    required this.unlocked,
    required this.claimed,
  });

  final bool unlocked;
  final bool claimed;

  DailyInkSlotState copyWith({bool? unlocked, bool? claimed}) {
    return DailyInkSlotState(
      unlocked: unlocked ?? this.unlocked,
      claimed: claimed ?? this.claimed,
    );
  }
}

class DailyInkState {
  DailyInkState({
    required this.slots,
    required this.busy,
  });

  final List<DailyInkSlotState> slots;
  final bool busy;

  bool get allClaimed => slots.every((s) => s.claimed);

  DailyInkState copyWith({List<DailyInkSlotState>? slots, bool? busy}) {
    return DailyInkState(
      slots: slots ?? this.slots,
      busy: busy ?? this.busy,
    );
  }
}

class DailyInkNotifier extends AsyncNotifier<DailyInkState> {
  static const _kDailyInkDate = 'colosynth_daily_ink_date';

  static String _slotUnlockedKey(int i) =>
      'colosynth_daily_ink_slot_${i}_unlocked';
  static String _slotClaimedKey(int i) =>
      'colosynth_daily_ink_slot_${i}_claimed';

  SharedPreferences? _prefs;

  @override
  Future<DailyInkState> build() async {
    _prefs ??= await SharedPreferences.getInstance();
    final prefs = _prefs!;
    final today = AppDateUtils.todayKey();
    final savedDate = prefs.getString(_kDailyInkDate) ?? '';

    final steps = StoreData.dailyInkStepAmounts;
    final slotCount = steps.length;

    if (savedDate != today) {
      await prefs.setString(_kDailyInkDate, today);
      for (int i = 0; i < slotCount; i++) {
        await prefs.setBool(
            _slotUnlockedKey(i), i == 0);
        await prefs.setBool(_slotClaimedKey(i), false);
      }
    }

    final slots = <DailyInkSlotState>[];
    for (int i = 0; i < slotCount; i++) {
      final unlocked = prefs.getBool(_slotUnlockedKey(i)) ?? (i == 0);
      final claimed = prefs.getBool(_slotClaimedKey(i)) ?? false;
      slots.add(DailyInkSlotState(unlocked: unlocked, claimed: claimed));
    }

    final hasUnclaimedAdSlot = slots.asMap().entries.any(
          (e) => e.key > 0 && !e.value.unlocked && !e.value.claimed,
        );
    if (hasUnclaimedAdSlot) {
      unawaited(RewardedAdService.instance.preload());
    }

    void listener() {
      ref.invalidateSelf();
    }
    DailyRefreshService.instance.addCallback(listener);
    ref.onDispose(() {
      DailyRefreshService.instance.removeCallback(listener);
    });

    return DailyInkState(slots: slots, busy: false);
  }

  /// Claim a free slot (slot 0) or an already-unlocked ad slot.
  Future<void> claimSlot(int index) async {
    _prefs ??= await SharedPreferences.getInstance();
    final current = state.value;
    if (current == null || current.busy) return;

    final steps = StoreData.dailyInkStepAmounts;
    if (index < 0 || index >= steps.length) return;

    final slot = current.slots[index];
    if (!slot.unlocked || slot.claimed) return;

    state = AsyncData(current.copyWith(busy: true));

    try {
      final amount = steps[index];
      await ref
          .read(walletProvider.notifier)
          .award(Currency.ink, amount, source: 'daily_bonus');
      GameEventBus.instance.emit(const DailyGiftClaimedEvent());

      await _prefs!.setBool(_slotClaimedKey(index), true);

      final updatedSlots = List<DailyInkSlotState>.from(current.slots);
      updatedSlots[index] = slot.copyWith(claimed: true);

      final fresh = state.value ?? current;
      state = AsyncData(fresh.copyWith(slots: updatedSlots, busy: false));

      if (index + 1 < steps.length) {
        unawaited(RewardedAdService.instance.preload());
      }
    } catch (e) {
      debugPrint('DailyInkNotifier.claimSlot error: $e');
      final fresh = state.value ?? current;
      state = AsyncData(fresh.copyWith(busy: false));
      rethrow;
    }
  }

  /// Watch an ad to unlock a slot (slots 1-3). After unlocking, the
  /// player can then claim the ink.
  Future<void> unlockSlot(
      int index, void Function(int amount) onUnlocked) async {
    _prefs ??= await SharedPreferences.getInstance();
    final current = state.value;
    if (current == null || current.busy) return;

    final steps = StoreData.dailyInkStepAmounts;
    if (index <= 0 || index >= steps.length) return;

    final slot = current.slots[index];
    if (slot.unlocked || slot.claimed) return;

    if (!current.slots[index - 1].claimed) return;

    final isAdFree = IapService.instance.adFreeActive;
    if (isAdFree) {
      await _prefs!.setBool(_slotUnlockedKey(index), true);
      final latest = state.value ?? current;
      final updatedSlots = List<DailyInkSlotState>.from(latest.slots);
      updatedSlots[index] = updatedSlots[index].copyWith(unlocked: true);
      state = AsyncData(latest.copyWith(slots: updatedSlots, busy: false));
      onUnlocked(steps[index]);
      if (index + 1 < steps.length) {
        unawaited(RewardedAdService.instance.preload());
      }
      return;
    }

    if (!RewardedAdService.instance.isReady) {
      unawaited(RewardedAdService.instance.preload());
      throw Exception('Ad is not ready. Please try again in a few seconds.');
    }

    state = AsyncData(current.copyWith(busy: true));

    final shown = await RewardedAdService.instance.showAd(
      onRewarded: () async {
        await _prefs!.setBool(_slotUnlockedKey(index), true);

        final latest = state.value ?? current;
        final updatedSlots = List<DailyInkSlotState>.from(latest.slots);
        updatedSlots[index] = updatedSlots[index].copyWith(unlocked: true);
        state = AsyncData(latest.copyWith(slots: updatedSlots, busy: false));
        onUnlocked(steps[index]);

        if (index + 1 < steps.length) {
          unawaited(RewardedAdService.instance.preload());
        }
      },
      onDismissed: () {
        final s = state.value;
        if (s != null && s.busy) {
          state = AsyncData(s.copyWith(busy: false));
        }
      },
    );

    if (!shown) {
      final fresh = state.value ?? current;
      state = AsyncData(fresh.copyWith(busy: false));
    }
  }
}

final dailyInkProvider = AsyncNotifierProvider<DailyInkNotifier, DailyInkState>(
  DailyInkNotifier.new,
);

class StoreController {
  StoreController(this.ref);
  final Ref ref;

  Future<void> restorePurchases() async {
    await IapService.instance.restorePurchases();
    unawaited(ref.read(adFreeProvider.notifier).refresh());
  }

  Future<IapResult> buyBundle(String productId) async {
    unawaited(ref.read(analyticsServiceProvider).logPurchaseInitiated(productId));
    final result = await IapService.instance.purchaseProduct(productId);
    if (result is! IapSuccess) return result;

    if (productId == StoreData.adFreeBundle.productId) {
      unawaited(ref.read(adFreeProvider.notifier).refresh());
    } else {
      final inkBundle = StoreData.inkBundles
          .where((b) => b.productId == productId)
          .firstOrNull;
      if (inkBundle != null) {
        await ref
            .read(walletProvider.notifier)
            .award(Currency.ink, inkBundle.ink, source: 'store_purchase');
      } else {
        final paintBundle = StoreData.paintBundles
            .where((b) => b.productId == productId)
            .firstOrNull;
        if (paintBundle != null) {
          await ref.read(walletProvider.notifier).award(
              Currency.paint, paintBundle.paint,
              source: 'store_purchase');
        } else {
          final comboBundle = StoreData.comboBundles
              .where((b) => b.productId == productId)
              .firstOrNull;
          if (comboBundle != null) {
            await ref.read(walletProvider.notifier).awardMultiple(
                  ink: comboBundle.ink,
                  paint: comboBundle.paint,
                  source: 'store_purchase',
                );
          } else if (productId == StoreData.starterBundle.productId) {
            await ref.read(walletProvider.notifier).awardMultiple(
                  ink: StoreData.starterBundle.ink,
                  paint: StoreData.starterBundle.paint,
                  source: 'store_purchase',
                );
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('colosynth_starter_bundle_purchased', true);
          }
        }
      }
    }
    return result;
  }

  Future<bool> buyExpItem(ExpItemBundle bundle) async {
    final wallet = ref.read(walletProvider.notifier);
    if (bundle.usePaint) {
      if (!wallet.canAfford(Currency.paint, bundle.cost)) return false;
    } else {
      if (!wallet.canAfford(Currency.ink, bundle.cost)) return false;
    }

    try {
      if (bundle.usePaint) {
        await wallet.spend(Currency.paint, bundle.cost, reason: 'shop_item');
      } else {
        await wallet.spend(Currency.ink, bundle.cost, reason: 'shop_item');
      }
    } catch (e) {
      debugPrint('Failed to spend currency for exp item: $e');
      return false;
    }

    try {
      await ref
          .read(expItemsProvider.notifier)
          .grant(bundle.id, bundle.quantity);
    } catch (e) {
      debugPrint('Failed to grant exp item, rolling back currency spend: $e');
      try {
        if (bundle.usePaint) {
          await wallet.award(Currency.paint, bundle.cost,
              source: 'shop_refund');
        } else {
          await wallet.award(Currency.ink, bundle.cost, source: 'shop_refund');
        }
      } catch (innerErr) {
        debugPrint('Critical: Currency refund failed: $innerErr');
      }
      return false;
    }

    return true;
  }
}

final storeControllerProvider = Provider((ref) => StoreController(ref));
