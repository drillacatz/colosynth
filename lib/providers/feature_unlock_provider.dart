import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:colosynth/providers/save_provider.dart';
import 'package:colosynth/providers/tournament_provider.dart';
import 'package:colosynth/services/level_progress_service.dart';

class FeatureUnlockState {
  final Set<UnlockableFeature> unlockedFeatures;

  const FeatureUnlockState(this.unlockedFeatures);

  bool isUnlocked(UnlockableFeature? feature) {
    if (feature == null) return true;
    return unlockedFeatures.contains(feature);
  }

  bool get isCharacterScreenUnlocked =>
      unlockedFeatures.contains(UnlockableFeature.characterScreen);

  bool get isUpgradeScreenUnlocked =>
      unlockedFeatures.contains(UnlockableFeature.upgradeTab);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeatureUnlockState &&
          other.unlockedFeatures.length == unlockedFeatures.length &&
          other.unlockedFeatures.containsAll(unlockedFeatures);

  @override
  int get hashCode => Object.hashAll(unlockedFeatures);
}

final featureUnlockProvider =
    NotifierProvider<FeatureUnlockNotifier, FeatureUnlockState>(
  FeatureUnlockNotifier.new,
);

class FeatureUnlockNotifier extends Notifier<FeatureUnlockState> {
  @override
  FeatureUnlockState build() {
    ref.watch(saveSyncReadyProvider);
    final accountLevel =
        ref.watch(accountLevelProvider.select((l) => l.accountLevel));
    final tutorialDone = ref.watch(tutorialCompletedProvider);
    final tournamentProgress = ref.watch(tournamentProgressProvider);

    final svc = ProgressionService.instance;
    final unlocked = Set<UnlockableFeature>.from(svc.permanentUnlocks);

    // 1. Level-based features from gates (excluding characterScreen and upgradeTab)
    for (final gate in ProgressionService.gates) {
      if (gate.feature != UnlockableFeature.characterScreen &&
          gate.feature != UnlockableFeature.upgradeTab) {
        if (accountLevel >= gate.requiredLevel) {
          unlocked.add(gate.feature);
        }
      }
    }

    // 2. Character Screen unlock rule: Strictly tutorial completion (or tutorial_2 cleared)
    final isTutorialCleared =
        tutorialDone || tournamentProgress.containsKey('tutorial_2');
    if (isTutorialCleared) {
      unlocked.add(UnlockableFeature.characterScreen);
      unawaited(svc.markPermanentUnlock(UnlockableFeature.characterScreen));
    }

    // 3. Upgrade Tab unlock rule: Strictly clearing >= 3 non-tutorial tournament stages
    final nonTutorialStagesCleared = tournamentProgress.keys
        .where((k) => !k.startsWith('tutorial_') && !k.startsWith('tier_'))
        .length;
    if (nonTutorialStagesCleared >= 3) {
      unlocked.add(UnlockableFeature.upgradeTab);
      unawaited(svc.markPermanentUnlock(UnlockableFeature.upgradeTab));
    }

    return FeatureUnlockState(Set.unmodifiable(unlocked));
  }

  Future<void> unlockFeature(UnlockableFeature feature) async {
    if (state.unlockedFeatures.contains(feature)) return;
    await ProgressionService.instance.markPermanentUnlock(feature);
    state = FeatureUnlockState(
      Set.unmodifiable({...state.unlockedFeatures, feature}),
    );
  }
}
