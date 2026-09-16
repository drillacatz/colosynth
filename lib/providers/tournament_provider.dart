import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:colosynth/utils/app_logger.dart';
import 'package:colosynth/providers/exp_items_provider.dart';
import 'package:colosynth/providers/save_provider.dart';
import 'package:colosynth/providers/service_providers.dart';
import 'package:colosynth/providers/auth_provider.dart';
import 'package:colosynth/game/event_bus/game_event_bus.dart';
import 'package:colosynth/game/event_bus/game_events.dart';

class TournamentReward {
  final int ink;
  final int paint;
  final int accountXp;
  final int equipmentXp;
  final Map<String, int> expItems;

  const TournamentReward({
    required this.ink,
    required this.paint,
    required this.accountXp,
    required this.equipmentXp,
    required this.expItems,
  });
}

class TierTotalReward {
  final int ink;
  final int paint;
  final int accountXp;
  final Map<String, int> expItems;

  const TierTotalReward({
    required this.ink,
    required this.paint,
    required this.accountXp,
    required this.expItems,
  });
}

class RewardSummary {
  final int ink;
  final int paint;
  final int accountXp;
  final int equipmentXp;
  final int bonusInk;
  final int bonusPaint;
  final Map<String, int> expItems;
  final String? bonusLabel;

  const RewardSummary({
    required this.ink,
    required this.paint,
    required this.accountXp,
    required this.equipmentXp,
    required this.bonusInk,
    required this.bonusPaint,
    this.expItems = const {},
    this.bonusLabel,
  });
}

class TournamentProgressNotifier extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() {
    ref.watch(authStateProvider);
    ref.watch(saveSyncReadyProvider);

    final subStage = GameEventBus.instance.on<TournamentStageClearedEvent>().listen((e) {
      markCompleted(e.slotId);
    });
    final subTier = GameEventBus.instance.on<TournamentTierClearedEvent>().listen((e) {
      markCompleted('tier_${e.tier}_cleared');
    });
    final subTutorial = GameEventBus.instance.on<TutorialCompletedEvent>().listen((_) {
      markCompleted('tutorial_2');
    });
    ref.onDispose(() {
      subStage.cancel();
      subTier.cancel();
      subTutorial.cancel();
    });

    return ref.watch(saveManagerProvider).loadTournamentProgress();
  }

  void refresh() {
    state = Map.unmodifiable(ref.read(saveManagerProvider).loadTournamentProgress());
  }

  void loadFrom(Map<String, String> saved) {
    state = Map.unmodifiable(saved);
  }

  void markCompleted(String slotId) {
    if (state.containsKey(slotId)) return;
    state = Map.unmodifiable({...state, slotId: 'completed'});
  }

  bool isSlotCompleted(String slotId) => state.containsKey(slotId);

  void reset() => state = const {};
}

final tournamentProgressProvider =
    NotifierProvider<TournamentProgressNotifier, Map<String, String>>(
  TournamentProgressNotifier.new,
);

class TournamentController {
  TournamentController(this.ref);

  final Ref ref;

  static const Map<int, TierTotalReward> _tierTotals = {
    1: TierTotalReward(
      ink: 5000,
      paint: 10,
      accountXp: 250,
      expItems: {
        'exp_hammer_common': 7,
        'exp_note_common': 7,
        'exp_book_common': 7
      },
    ),
    2: TierTotalReward(
      ink: 10000,
      paint: 15,
      accountXp: 400,
      expItems: {
        'exp_hammer_rare': 5,
        'exp_note_rare': 5,
        'exp_book_rare': 5
      },
    ),
    3: TierTotalReward(
      ink: 12000,
      paint: 20,
      accountXp: 500,
      expItems: {
        'exp_hammer_rare': 7,
        'exp_note_rare': 7,
        'exp_book_rare': 7
      },
    ),
    4: TierTotalReward(
      ink: 25000,
      paint: 25,
      accountXp: 750,
      expItems: {
        'exp_hammer_epic': 4,
        'exp_note_epic': 4,
        'exp_book_epic': 4
      },
    ),
    5: TierTotalReward(
      ink: 35000,
      paint: 30,
      accountXp: 1000,
      expItems: {
        'exp_hammer_rare': 2,
        'exp_hammer_epic': 4,
        'exp_note_rare': 2,
        'exp_note_epic': 4,
        'exp_book_rare': 2,
        'exp_book_epic': 4,
      },
    ),
    6: TierTotalReward(
      ink: 45000,
      paint: 35,
      accountXp: 1200,
      expItems: {
        'exp_hammer_epic': 6,
        'exp_note_epic': 6,
        'exp_book_epic': 6
      },
    ),
    7: TierTotalReward(
      ink: 50000,
      paint: 40,
      accountXp: 1500,
      expItems: {
        'exp_hammer_epic': 4,
        'exp_hammer_legendary': 2,
        'exp_note_epic': 4,
        'exp_note_legendary': 2,
        'exp_book_epic': 4,
        'exp_book_legendary': 2,
      },
    ),
    8: TierTotalReward(
      ink: 50000,
      paint: 45,
      accountXp: 2000,
      expItems: {
        'exp_hammer_epic': 1,
        'exp_hammer_legendary': 4,
        'exp_note_epic': 1,
        'exp_note_legendary': 4,
        'exp_book_epic': 1,
        'exp_book_legendary': 4,
      },
    ),
    9: TierTotalReward(
      ink: 70000,
      paint: 50,
      accountXp: 2500,
      expItems: {
        'exp_hammer_legendary': 5,
        'exp_note_legendary': 5,
        'exp_book_legendary': 5
      },
    ),
    10: TierTotalReward(
      ink: 90000,
      paint: 55,
      accountXp: 4000,
      expItems: {
        'exp_hammer_legendary': 6,
        'exp_note_legendary': 6,
        'exp_book_legendary': 6
      },
    ),
  };

  static int _getSlotWeight(int index) {
    if (index < 3) return 2;
    if (index == 3) return 4;
    if (index < 7) return 3;
    if (index == 7) return 6;
    if (index < 11) return 4;
    return 8;
  }

  static List<int> _distributeByWeights(int total, List<int> weights) {
    final totalWeight = weights.reduce((a, b) => a + b);
    final result = List<int>.filled(weights.length, 0);
    int sum = 0;
    for (int i = 0; i < weights.length; i++) {
      result[i] = (total * weights[i]) ~/ totalWeight;
      sum += result[i];
    }
    final int remainder = total - sum;
    if (remainder > 0) {
      final indices = List<int>.generate(weights.length, (i) => i);
      indices.sort((a, b) => weights[b].compareTo(weights[a]));
      for (int i = 0; i < remainder; i++) {
        result[indices[i % indices.length]]++;
      }
    }
    return result;
  }

  static TournamentReward getSlotFirstClearReward(String slotId, int tier) {
    final totals = _tierTotals[tier] ?? _tierTotals[1]!;
    final weights = List<int>.generate(12, (i) => _getSlotWeight(i));

    int slotIndex = 0;
    if (slotId == 'extreme_boss') {
      slotIndex = 11;
    } else {
      final parts = slotId.split('_');
      if (parts.length >= 3) {
        final stageKey = parts[1];
        final pos = parts[2];

        int stageOffset = 0;
        if (stageKey == 'b') {
          stageOffset = 4;
        } else if (stageKey == 'c') {
          stageOffset = 8;
        }

        int slotOffset = 0;
        if (pos == 'boss') {
          slotOffset = 3;
        } else {
          slotOffset = int.tryParse(pos) ?? 0;
        }
        slotIndex = (stageOffset + slotOffset).clamp(0, 11);
      }
    }

    final inkList = _distributeByWeights(totals.ink, weights);
    final paintList = _distributeByWeights(totals.paint, weights);
    final xpList = _distributeByWeights(totals.accountXp, weights);

    final slotExpItems = <String, int>{};
    for (final entry in totals.expItems.entries) {
      final itemList = _distributeByWeights(entry.value, weights);
      final count = itemList[slotIndex];
      if (count > 0) {
        slotExpItems[entry.key] = count;
      }
    }

    return TournamentReward(
      ink: inkList[slotIndex],
      paint: paintList[slotIndex],
      accountXp: xpList[slotIndex],
      equipmentXp: 0,
      expItems: slotExpItems,
    );
  }

  static TournamentReward getFirstClearReward(int tier) {
    return getSlotFirstClearReward('t${tier}_a_0', tier);
  }

  static int countCompleted(Map<String, String> progress) => progress.length;

  Future<void> grantRewards(RewardSummary summary) async {
    AppLogger.d('TournamentController',
        'Granting rewards: ${summary.ink} ink, ${summary.accountXp} xp');

    if (summary.ink > 0 || summary.paint > 0) {
      try {
        await ref.read(walletProvider.notifier).awardMultiple(
              ink: summary.ink,
              paint: summary.paint,
              source: 'tournament_stage_reward',
            );
      } catch (e, st) {
        AppLogger.e(
            'TournamentController.grantRewards [base ink/paint]', e, st);
      }
    }

    if (summary.accountXp > 0) {
      try {
        await ref.read(accountLevelProvider.notifier).addXp(summary.accountXp);
      } catch (e, st) {
        AppLogger.e('TournamentController.grantRewards [accountXp]', e, st);
      }
    }

    if (summary.equipmentXp > 0) {
      try {
        await ref
            .read(equipmentLevelsProvider.notifier)
            .addXpToAll(summary.equipmentXp);
      } catch (e, st) {
        AppLogger.e('TournamentController.grantRewards [equipmentXp]', e, st);
      }
    }

    for (final entry in summary.expItems.entries) {
      if (entry.value <= 0) continue;
      try {
        await ref.read(expItemsProvider.notifier).grant(entry.key, entry.value);
      } catch (e, st) {
        AppLogger.e(
            'TournamentController.grantRewards [expItem:${entry.key}]', e, st);
      }
    }

    if (summary.bonusInk > 0 || summary.bonusPaint > 0) {
      try {
        await ref.read(walletProvider.notifier).awardMultiple(
              ink: summary.bonusInk,
              paint: summary.bonusPaint,
              source: 'tournament_stage_reward',
            );
      } catch (e, st) {
        AppLogger.e('TournamentController.grantRewards [tierBonus]', e, st);
      }
    }

    AppLogger.d('TournamentController', 'Rewards grant complete');
  }
}

final tournamentControllerProvider = Provider<TournamentController>((ref) {
  return TournamentController(ref);
});
