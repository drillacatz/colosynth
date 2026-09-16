import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:colosynth/database/synth/synth_instance.dart';
import 'package:colosynth/services/synth/synth_crate_service.dart';
import 'package:colosynth/services/save_manager.dart';
import 'package:colosynth/services/account_sync_service.dart';
import 'package:colosynth/providers/save_provider.dart';
import 'package:colosynth/providers/auth_provider.dart';
import 'package:colosynth/providers/tournament_provider.dart';


final synthKeysProvider =
    NotifierProvider<SynthKeysNotifier, int>(SynthKeysNotifier.new);

class SynthKeysNotifier extends Notifier<int> {
  @override
  int build() {
    ref.watch(authStateProvider);
    ref.watch(saveSyncReadyProvider);
    return SaveManager.instance.loadSynthKeys();
  }

  Future<void> award(int count) async {
    final newCount = state + count;
    await SaveManager.instance.saveSynthKeys(newCount);
    state = newCount;
  }

  /// Spends one key. Returns false if no keys available.
  Future<bool> spendOne() async {
    if (state <= 0) return false;
    final newCount = state - 1;
    await SaveManager.instance.saveSynthKeys(newCount);
    state = newCount;
    return true;
  }
}


final ownedSynthInstancesProvider =
    NotifierProvider<OwnedSynthInstancesNotifier, Map<String, SynthInstance>>(
  OwnedSynthInstancesNotifier.new,
);

class OwnedSynthInstancesNotifier
    extends Notifier<Map<String, SynthInstance>> {
  @override
  Map<String, SynthInstance> build() {
    ref.watch(authStateProvider);
    ref.watch(saveSyncReadyProvider);
    return SaveManager.instance.gameplay.loadSynthInstances();
  }

  /// Opens one Synth crate (spends 1 key). Returns null if no keys.
  Future<({SynthInstance instance, bool isDuplicate})?> openCrate() async {
    final spent = await ref.read(synthKeysProvider.notifier).spendOne();
    if (!spent) return null;

    final result = await SynthCrateService.instance
        .openCrate(nowMs: DateTime.now().millisecondsSinceEpoch);

    state = SaveManager.instance.gameplay.loadSynthInstances();
    unawaited(AccountSyncService.instance.flushMilestone());
    return result;
  }

  void refresh() {
    state = SaveManager.instance.gameplay.loadSynthInstances();
  }
}


class SynthSlotUnlockState {
  /// slot 0..3 => true if that slot is unlocked
  final List<bool> slotUnlocked;

  const SynthSlotUnlockState(this.slotUnlocked);

  bool isUnlocked(int slotIndex) =>
      slotIndex >= 0 && slotIndex < slotUnlocked.length
          ? slotUnlocked[slotIndex]
          : false;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SynthSlotUnlockState &&
          _listEq(other.slotUnlocked, slotUnlocked);

  static bool _listEq(List<bool> a, List<bool> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(slotUnlocked);
}

final synthSlotUnlockStateProvider =
    Provider<SynthSlotUnlockState>((ref) {
  final tournamentProgress = ref.watch(tournamentProgressProvider);
  final saveState = ref.watch(gameplaySaveNotifierProvider);
  final charId = ref.watch(equippedCharacterIdProvider);
  final charLevel = saveState.charLevels[charId] ?? 1;

  final isTier1Cleared = tournamentProgress.containsKey('tier_1_cleared');

  final unlocked = [
    true,
    isTier1Cleared,
    isTier1Cleared && saveState.synthSlot3Unlocked,
    charLevel >= 50,
  ];

  return SynthSlotUnlockState(unlocked);
});


final charSynthSlotsFamily =
    Provider.family<List<String?>, String>((ref, charId) {
  final saveState = ref.watch(gameplaySaveNotifierProvider);
  return saveState.characterSynths[charId] ??
      List<String?>.filled(4, null, growable: false);
});

final equippedCharSynthSlotsProvider = Provider<List<String?>>((ref) {
  final charId = ref.watch(equippedCharacterIdProvider);
  return ref.watch(charSynthSlotsFamily(charId));
});


final synthSlotLevelsProvider = Provider<Map<int, int>>((ref) {
  return ref.watch(
    gameplaySaveNotifierProvider.select((s) => s.synthSlotLevels),
  );
});

final synthSlot3UnlockedProvider = Provider<bool>((ref) {
  return ref.watch(
    gameplaySaveNotifierProvider.select((s) => s.synthSlot3Unlocked),
  );
});
