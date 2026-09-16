import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:colosynth/services/level_progress_service.dart';
import 'package:colosynth/providers/tournament_provider.dart';
import 'package:colosynth/providers/auth_provider.dart';
import 'package:colosynth/providers/save_provider.dart';
import 'package:colosynth/providers/shared_preferences_provider.dart';
import 'package:colosynth/utils/app_logger.dart';


class MilestoneReward {
  const MilestoneReward({
    required this.ink,
    required this.paint,
    required this.accountXp,
    this.expItemKey,
    this.expItemCount = 0,
  });

  final int ink;
  final int paint;
  final int accountXp;
  final String? expItemKey;
  final int expItemCount;
}

/// Returns the 6 milestone rewards for a given [tier].
/// Distribution is derived from TournamentController._tierTotals:
///   Row 0  Stage A normals  → 10% ink, 10% paint
///   Row 1  Stage A boss     → 15% ink, 15% paint, 15% XP
///   Row 2  Stage B normals  → 15% ink, 15% paint
///   Row 3  Stage B boss     → 20% ink, 20% paint, 25% XP + exp items (half)
///   Row 4  Stage C normals  → 15% ink, 15% paint
///   Row 5  Stage C boss     → 25% ink, 25% paint, 60% XP + exp items (full)
List<MilestoneReward> milestoneRewardsForTier(int tier) {
  const totals = <int, (int ink, int paint, int xp, String? expKey, int expCount)>{
    1:  (5000,  10,  250, 'exp_hammer_common',    7),
    2:  (10000, 15,  400, 'exp_hammer_rare',       5),
    3:  (12000, 20,  500, 'exp_hammer_rare',       7),
    4:  (25000, 25,  750, 'exp_hammer_epic',       4),
    5:  (35000, 30, 1000, 'exp_hammer_epic',       6),
    6:  (45000, 35, 1200, 'exp_hammer_epic',       6),
    7:  (50000, 40, 1500, 'exp_hammer_legendary',  2),
    8:  (50000, 45, 2000, 'exp_hammer_legendary',  4),
    9:  (70000, 50, 2500, 'exp_hammer_legendary',  5),
    10: (90000, 55, 4000, 'exp_hammer_legendary',  6),
  };

  final t = totals[tier.clamp(1, 10)]!;
  final ink = t.$1;
  final paint = t.$2;
  final xp = ProgressionService.chestXpForTier(tier);
  final expKey = t.$4;
  final expCount = t.$5;

  return [
    MilestoneReward(ink: (ink * 0.10).round(), paint: (paint * 0.10).round(), accountXp: 0),
    MilestoneReward(ink: (ink * 0.15).round(), paint: (paint * 0.15).round(), accountXp: (xp * 0.15).round()),
    MilestoneReward(ink: (ink * 0.15).round(), paint: (paint * 0.15).round(), accountXp: 0),
    MilestoneReward(
      ink: (ink * 0.20).round(), paint: (paint * 0.20).round(),
      accountXp: (xp * 0.25).round(),
      expItemKey: expKey, expItemCount: (expCount * 0.5).round().clamp(1, 999),
    ),
    MilestoneReward(ink: (ink * 0.15).round(), paint: (paint * 0.15).round(), accountXp: 0),
    MilestoneReward(
      ink: (ink * 0.25).round(), paint: (paint * 0.25).round(),
      accountXp: (xp * 0.60).round(),
      expItemKey: expKey, expItemCount: expCount,
    ),
  ];
}


/// Returns true when milestone [row] (0–5) is completable given [progress].
bool isMilestoneCleared(int tier, int row, Map<String, String> progress) {
  final t = tier;
  switch (row) {
    case 0:
      return progress.containsKey('t${t}_a_0') &&
             progress.containsKey('t${t}_a_1') &&
             progress.containsKey('t${t}_a_2');
    case 1:
      return progress.containsKey('t${t}_a_boss');
    case 2:
      return progress.containsKey('t${t}_b_0') &&
             progress.containsKey('t${t}_b_1') &&
             progress.containsKey('t${t}_b_2');
    case 3:
      return progress.containsKey('t${t}_b_boss');
    case 4:
      return progress.containsKey('t${t}_c_0') &&
             progress.containsKey('t${t}_c_1') &&
             progress.containsKey('t${t}_c_2');
    case 5:
      return progress.containsKey('t${t}_c_boss');
    default:
      return false;
  }
}

const _kMilestoneLabels = [
  'Clear 3 Stage A battles',
  'Defeat Stage A Boss',
  'Clear 3 Stage B battles',
  'Defeat Stage B Boss',
  'Clear 3 Stage C battles',
  'Defeat Stage C Boss',
];

String milestoneLabel(int row) => _kMilestoneLabels[row.clamp(0, 5)];


class TierChestState {
  const TierChestState({required this.claimed});
  final List<bool> claimed;

  bool get allClaimed => claimed.every((c) => c);

  TierChestState copyWithClaim(int row) {
    final next = List<bool>.from(claimed);
    next[row] = true;
    return TierChestState(claimed: next);
  }
}


class TierChestNotifier extends Notifier<TierChestState> {
  final int tier;
  TierChestNotifier(this.tier);

  @override
  TierChestState build() {
    ref.watch(authStateProvider);
    ref.watch(saveSyncReadyProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    return _load(prefs, tier);
  }

  static TierChestState _load(SharedPreferences prefs, int tier) {
    final raw = prefs.getString(_key(tier));
    if (raw == null) return TierChestState(claimed: List.filled(6, false));
    try {
      final list = (jsonDecode(raw) as List).cast<bool>();
      while (list.length < 6) {
        list.add(false);
      }
      return TierChestState(claimed: list.take(6).toList());
    } catch (_) {
      return TierChestState(claimed: List.filled(6, false));
    }
  }

  static String _key(int tier) => 'tier_chest_claimed_t$tier';

  /// Claims milestone [row] for this tier: grants rewards, persists, fires badge.
  Future<void> claim(int row) async {
    if (state.claimed[row]) return;
    final progress = ref.read(tournamentProgressProvider);
    if (!isMilestoneCleared(tier, row, progress)) return;

    final reward = milestoneRewardsForTier(tier)[row];
    final controller = ref.read(tournamentControllerProvider);

    try {
      await controller.grantRewards(
        RewardSummary(
          ink: reward.ink,
          paint: reward.paint,
          accountXp: reward.accountXp,
          equipmentXp: 0,
          bonusInk: 0,
          bonusPaint: 0,
          expItems: reward.expItemKey != null && reward.expItemCount > 0
              ? {reward.expItemKey!: reward.expItemCount}
              : {},
        ),
      );
    } catch (e, st) {
      AppLogger.e('TierChestNotifier.claim', e, st);
    }

    state = state.copyWithClaim(row);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key(tier), jsonEncode(state.claimed));
  }
}

final tierChestProvider =
    NotifierProvider.family<TierChestNotifier, TierChestState, int>(
  TierChestNotifier.new,
);

