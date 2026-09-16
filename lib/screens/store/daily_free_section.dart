import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colosynth/game_data/store_data.dart';
import 'package:colosynth/providers/store_provider.dart';
import 'package:colosynth/screens/overlays/claim_reward_overlay.dart';
import 'package:colosynth/screens/store/shop_card.dart';

class DailyFreeSection extends StatelessWidget {
  const DailyFreeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 140,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: DailyInkSlotsRow(),
      ),
    );
  }
}

class DailyInkSlotsRow extends ConsumerStatefulWidget {
  const DailyInkSlotsRow({super.key});

  @override
  ConsumerState<DailyInkSlotsRow> createState() => _DailyInkSlotsRowState();
}

class _DailyInkSlotsRowState extends ConsumerState<DailyInkSlotsRow> {
  Timer? _countdownTimer;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _updateTimerSubscription(bool allDone) {
    if (allDone && _countdownTimer == null) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!allDone && _countdownTimer != null) {
      _countdownTimer?.cancel();
      _countdownTimer = null;
    }
  }

  String _countdown() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final d = midnight.difference(now);
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(dailyInkProvider);
    final steps = StoreData.dailyInkStepAmounts;

    stateAsync.whenData((data) {
      _updateTimerSubscription(data.allClaimed);
    });

    return stateAsync.when(
      data: (data) {
        if (data.allClaimed) {
          return SizedBox(
            width: 130,
            child: ShopCard(
              icon: Icons.check_circle_outline,
              mainLabel: 'ALL DONE',
              subLabel: _countdown(),
              highlighted: false,
              compact: true,
              dimmed: true,
              accentColor: const Color(0xFF888888),
              onTap: null,
            ),
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(steps.length, (i) {
            final slot = data.slots[i];
            final amount = steps[i];
            final isFree = i == 0;
            final prevClaimed = i == 0 || data.slots[i - 1].claimed;

            return Padding(
              padding: EdgeInsets.only(right: i < steps.length - 1 ? 8 : 0),
              child: SizedBox(
                width: 110,
                child: _buildSlotCard(
                  index: i,
                  slot: slot,
                  amount: amount,
                  isFree: isFree,
                  prevClaimed: prevClaimed,
                  busy: data.busy,
                ),
              ),
            );
          }),
        );
      },
      loading: () => const SizedBox(
        width: 110,
        child: ShopCard(
          icon: Icons.water_drop,
          mainLabel: 'INK',
          subLabel: 'LOADING...',
          highlighted: false,
          compact: true,
          accentColor: Color(0xFF00B0FF),
          onTap: null,
        ),
      ),
      error: (err, _) => const SizedBox(
        width: 110,
        child: ShopCard(
          icon: Icons.error_outline,
          mainLabel: 'ERROR',
          subLabel: 'TRY LATER',
          highlighted: false,
          compact: true,
          dimmed: true,
          accentColor: Color(0xFFE53935),
          onTap: null,
        ),
      ),
    );
  }

  Widget _buildSlotCard({
    required int index,
    required DailyInkSlotState slot,
    required int amount,
    required bool isFree,
    required bool prevClaimed,
    required bool busy,
  }) {
    final label = '+$amount INK';

    if (slot.claimed) {
      return ShopCard(
        icon: Icons.check_circle_outline,
        mainLabel: label,
        subLabel: 'CLAIMED',
        highlighted: false,
        compact: true,
        dimmed: true,
        accentColor: const Color(0xFF777777),
        onTap: null,
      );
    }

    if (isFree && slot.unlocked) {
      return ShopCard(
        icon: Icons.card_giftcard,
        mainLabel: label,
        subLabel: 'FREE',
        highlighted: true,
        compact: true,
        showRedDot: true,
        accentColor: const Color(0xFF00E5FF),
        badgeText: 'DAILY FREE',
        onTap: busy ? null : () => _handleClaim(index, amount),
      );
    }

    if (!prevClaimed) {
      return ShopCard(
        icon: Icons.lock_outline,
        mainLabel: label,
        subLabel: 'LOCKED',
        highlighted: false,
        compact: true,
        dimmed: true,
        accentColor: const Color(0xFF666666),
        onTap: null,
      );
    }

    if (!slot.unlocked) {
      final isAdFree = ref.watch(adFreeProvider).value ?? false;
      if (isAdFree) {
        return ShopCard(
          icon: Icons.card_giftcard,
          mainLabel: label,
          subLabel: 'FREE',
          highlighted: true,
          compact: true,
          accentColor: const Color(0xFF00E5FF),
          badgeText: 'AD FREE',
          onTap: busy ? null : () => _handleUnlock(index, amount),
        );
      }
      return ShopCard(
        icon: Icons.play_circle_outline,
        mainLabel: label,
        subLabel: 'WATCH AD',
        highlighted: true,
        compact: true,
        accentColor: const Color(0xFF00E5FF),
        badgeText: '+INK AD',
        onTap: busy ? null : () => _handleUnlock(index, amount),
      );
    }

    return ShopCard(
      icon: Icons.card_giftcard,
      mainLabel: label,
      subLabel: 'CLAIM',
      highlighted: true,
      compact: true,
      accentColor: const Color(0xFF00E676),
      badgeText: 'READY',
      onTap: busy ? null : () => _handleClaim(index, amount),
    );
  }

  void _handleClaim(int index, int amount) async {
    try {
      await ref.read(dailyInkProvider.notifier).claimSlot(index);
      if (mounted) {
        await ClaimRewardOverlay.show(
          context,
          inkReward: amount,
          paintReward: 0,
        );
      }
    } catch (_) {}
  }

  void _handleUnlock(int index, int amount) {
    ref.read(dailyInkProvider.notifier).unlockSlot(index, (earned) async {
      try {
        await ref.read(dailyInkProvider.notifier).claimSlot(index);
        if (mounted) {
          await ClaimRewardOverlay.show(
            context,
            inkReward: earned,
            paintReward: 0,
          );
        }
      } catch (_) {}
    });
  }
}
