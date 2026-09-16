import 'dart:async';
import 'package:colosynth/database/character/character_equipment_slot.dart';
import 'package:colosynth/database/synth/synth_instance.dart';
import 'package:colosynth/providers/synth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';

import 'package:colosynth/services/save_manager.dart';
import 'package:colosynth/providers/auth_provider.dart';
import 'package:colosynth/utils/constants.dart';
import 'package:colosynth/providers/account_provider.dart';
import 'package:colosynth/providers/tournament_provider.dart';
import 'package:colosynth/providers/wallet_provider.dart';

export 'wallet_provider.dart';
export 'account_provider.dart';
export 'character_provider.dart';
export 'equipment_provider.dart';
export 'settings_provider.dart';
export 'tutorial_provider.dart';
export 'synth_provider.dart';

class GameplaySaveState {
  final Map<String, int> charLevels;
  final Map<String, int> charXp;
  final Map<String, int> charBreakthroughs;
  final Map<String, Map<String, CharacterEquipmentSlot>> characterEquipment;
  final Map<String, int> expItems;
  final Set<String> skillTree;
  final Map<int, int> synthSlotLevels;
  final bool synthSlot3Unlocked;
  final Map<String, List<String?>> characterSynths;

  GameplaySaveState({
    required this.charLevels,
    required this.charXp,
    required this.charBreakthroughs,
    required this.characterEquipment,
    required this.expItems,
    required this.skillTree,
    required this.synthSlotLevels,
    required this.synthSlot3Unlocked,
    required this.characterSynths,
  });

  GameplaySaveState copyWith({
    Map<String, int>? charLevels,
    Map<String, int>? charXp,
    Map<String, int>? charBreakthroughs,
    Map<String, Map<String, CharacterEquipmentSlot>>? characterEquipment,
    Map<String, int>? expItems,
    Set<String>? skillTree,
    Map<int, int>? synthSlotLevels,
    bool? synthSlot3Unlocked,
    Map<String, List<String?>>? characterSynths,
  }) {
    return GameplaySaveState(
      charLevels: charLevels != null ? Map<String, int>.from(charLevels) : Map<String, int>.from(this.charLevels),
      charXp: charXp != null ? Map<String, int>.from(charXp) : Map<String, int>.from(this.charXp),
      charBreakthroughs: charBreakthroughs != null ? Map<String, int>.from(charBreakthroughs) : Map<String, int>.from(this.charBreakthroughs),
      characterEquipment: characterEquipment != null
          ? Map<String, Map<String, CharacterEquipmentSlot>>.from(characterEquipment)
          : Map<String, Map<String, CharacterEquipmentSlot>>.from(this.characterEquipment),
      expItems: expItems != null ? Map<String, int>.from(expItems) : Map<String, int>.from(this.expItems),
      skillTree: skillTree != null ? Set<String>.from(skillTree) : Set<String>.from(this.skillTree),
      synthSlotLevels: synthSlotLevels != null ? Map<int, int>.from(synthSlotLevels) : Map<int, int>.from(this.synthSlotLevels),
      synthSlot3Unlocked: synthSlot3Unlocked ?? this.synthSlot3Unlocked,
      characterSynths: characterSynths != null
          ? Map<String, List<String?>>.from(characterSynths)
          : Map<String, List<String?>>.from(this.characterSynths),
    );
  }

  static const _mapEq = MapEquality();
  static const _setEq = SetEquality();
  static const _charEquipEq =
      MapEquality(keys: DefaultEquality(), values: MapEquality());
  static const _charSynthsEq =
      MapEquality(keys: DefaultEquality(), values: ListEquality());

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameplaySaveState &&
        _mapEq.equals(other.charLevels, charLevels) &&
        _mapEq.equals(other.charXp, charXp) &&
        _mapEq.equals(other.charBreakthroughs, charBreakthroughs) &&
        _charEquipEq.equals(other.characterEquipment, characterEquipment) &&
        _mapEq.equals(other.expItems, expItems) &&
        _setEq.equals(other.skillTree, skillTree) &&
        _mapEq.equals(other.synthSlotLevels, synthSlotLevels) &&
        other.synthSlot3Unlocked == synthSlot3Unlocked &&
        _charSynthsEq.equals(other.characterSynths, characterSynths);
  }

  @override
  int get hashCode => Object.hash(
        _mapEq.hash(charLevels),
        _mapEq.hash(charXp),
        _mapEq.hash(charBreakthroughs),
        _charEquipEq.hash(characterEquipment),
        _mapEq.hash(expItems),
        _setEq.hash(skillTree),
        _mapEq.hash(synthSlotLevels),
        synthSlot3Unlocked,
        _charSynthsEq.hash(characterSynths),
      );
}

class GameplaySaveNotifier extends Notifier<GameplaySaveState> {
  @override
  GameplaySaveState build() {
    ref.watch(authStateProvider);
    ref.watch(saveSyncReadyProvider);

    final saveManager = ref.watch(saveManagerProvider);
    if (!saveManager.isInitialized) {
      return GameplaySaveState(
        charLevels: const {'arthur': 1},
        charXp: const {'arthur': 0},
        charBreakthroughs: const {'arthur': 0},
        characterEquipment: const {},
        expItems: const {},
        skillTree: const {},
        synthSlotLevels: const {0: 1, 1: 1, 2: 1, 3: 1},
        synthSlot3Unlocked: false,
        characterSynths: const {
          'arthur': ['starter_synth', null, null, null]
        },
      );
    }

    final sm = ref.watch(gameplaySaveProvider);
    final unlockedChars = ref
        .watch(accountSaveNotifierProvider.select((s) => s.unlockedCharacters));

    final charLevels = <String, int>{};
    final charXp = <String, int>{};
    final charBreakthroughs = <String, int>{};
    final characterEquipment = <String, Map<String, CharacterEquipmentSlot>>{};
    final characterSynths = <String, List<String?>>{};

    for (final id in unlockedChars) {
      charLevels[id] = sm.loadCharLevelFor(id);
      charXp[id] = sm.loadCharXpFor(id);
      charBreakthroughs[id] = sm.loadCharBreakthroughFor(id);
      characterEquipment[id] = sm.loadEquipmentFor(id);
      characterSynths[id] = sm.loadEquippedSynthsFor(id);
    }

    final synthSlotLevels = {
      0: sm.loadSynthSlotLevel(0),
      1: sm.loadSynthSlotLevel(1),
      2: sm.loadSynthSlotLevel(2),
      3: sm.loadSynthSlotLevel(3),
    };
    final synthSlot3Unlocked = sm.loadSynthSlot3Unlocked();

    return GameplaySaveState(
      charLevels: charLevels,
      charXp: charXp,
      charBreakthroughs: charBreakthroughs,
      characterEquipment: characterEquipment,
      expItems: sm.loadExpItems(),
      skillTree: sm.loadSkillTree(),
      synthSlotLevels: synthSlotLevels,
      synthSlot3Unlocked: synthSlot3Unlocked,
      characterSynths: characterSynths,
    );
  }

  Future<void> addCharXp(String characterId, int xp) async {
    final sm = ref.read(gameplaySaveProvider);
    await sm.addCharXpFor(characterId, xp);
    state = state.copyWith(
      charLevels: {
        ...state.charLevels,
        characterId: sm.loadCharLevelFor(characterId)
      },
      charXp: {...state.charXp, characterId: sm.loadCharXpFor(characterId)},
    );
  }

  Future<void> saveCharBreakthrough(String characterId, int count) async {
    final sm = ref.read(gameplaySaveProvider);
    await sm.saveCharBreakthroughFor(characterId, count);
    state = state.copyWith(
      charBreakthroughs: {...state.charBreakthroughs, characterId: count},
    );
  }

  Future<void> saveEquipmentLevel(
      String charId, String slotKey, int level) async {
    final sm = ref.read(gameplaySaveProvider);
    await sm.saveEquipmentLevelFor(charId, slotKey, level);

    final charEquip = Map<String, CharacterEquipmentSlot>.from(
        state.characterEquipment[charId] ?? {});
    final current = charEquip[slotKey] ??
        const CharacterEquipmentSlot(level: 1, xp: 0, breakthroughCount: 0);
    charEquip[slotKey] = current.copyWith(level: level, xp: 0);

    state = state.copyWith(
      characterEquipment: {
        ...state.characterEquipment,
        charId: charEquip,
      },
    );
  }

  Future<void> saveEquipmentXp(String charId, String slotKey, int xp) async {
    final sm = ref.read(gameplaySaveProvider);
    await sm.saveEquipmentXpFor(charId, slotKey, xp);

    final charEquip = Map<String, CharacterEquipmentSlot>.from(
        state.characterEquipment[charId] ?? {});
    final current = charEquip[slotKey] ??
        const CharacterEquipmentSlot(level: 1, xp: 0, breakthroughCount: 0);
    charEquip[slotKey] = current.copyWith(xp: xp);

    state = state.copyWith(
      characterEquipment: {
        ...state.characterEquipment,
        charId: charEquip,
      },
    );
  }

  Future<void> addEquipmentXpToAll(String charId, int amount) async {
    final sm = ref.read(gameplaySaveProvider);
    final charEquip = Map<String, CharacterEquipmentSlot>.from(
        state.characterEquipment[charId] ?? {});

    for (final slot in AppConstants.equipmentSlots) {
      final current = charEquip[slot] ??
          const CharacterEquipmentSlot(level: 1, xp: 0, breakthroughCount: 0);
      final maxLvl = current.maxLevel;
      if (current.level >= maxLvl) continue;

      final threshold = (current.level + 1) * 200;
      final newXp = (current.xp + amount).clamp(0, threshold);
      charEquip[slot] = current.copyWith(xp: newXp);
      await sm.saveEquipmentXpFor(charId, slot, newXp);
    }
    state = state.copyWith(
      characterEquipment: {
        ...state.characterEquipment,
        charId: charEquip,
      },
    );
  }

  Future<void> saveEquipmentBreakthrough(
      String charId, String slotKey, int count) async {
    final sm = ref.read(gameplaySaveProvider);
    await sm.saveEquipmentBreakthroughFor(charId, slotKey, count);

    final charEquip = Map<String, CharacterEquipmentSlot>.from(
        state.characterEquipment[charId] ?? {});
    final current = charEquip[slotKey] ??
        const CharacterEquipmentSlot(level: 1, xp: 0, breakthroughCount: 0);
    charEquip[slotKey] = current.copyWith(breakthroughCount: count);

    state = state.copyWith(
      characterEquipment: {
        ...state.characterEquipment,
        charId: charEquip,
      },
    );
  }

  Future<void> addExpItem(String itemId, int count) async {
    final sm = ref.read(gameplaySaveProvider);
    await sm.addExpItem(itemId, count);
    state = state.copyWith(expItems: sm.loadExpItems());
  }

  Future<bool> consumeExpItem(String itemId) async {
    final sm = ref.read(gameplaySaveProvider);
    final ok = await sm.consumeExpItem(itemId);
    if (ok) {
      state = state.copyWith(expItems: sm.loadExpItems());
    }
    return ok;
  }

  Future<void> saveSkillTree(Set<String> unlockedIds) async {
    final sm = ref.read(gameplaySaveProvider);
    await sm.saveSkillTree(unlockedIds);
    state = state.copyWith(skillTree: unlockedIds);
  }

  Future<void> resetSkillTree() async {
    final sm = ref.read(gameplaySaveProvider);
    await sm.resetSkillTree();
    state = state.copyWith(skillTree: {});
  }

  Future<void> saveSynthSlotLevel(int slotIndex, int level) async {
    final sm = ref.read(gameplaySaveProvider);
    await sm.saveSynthSlotLevel(slotIndex, level);
    state = state.copyWith(
      synthSlotLevels: {
        ...state.synthSlotLevels,
        slotIndex: level,
      },
    );
  }

  Future<void> saveSynthSlot3Unlocked(bool unlocked) async {
    final sm = ref.read(gameplaySaveProvider);
    await sm.saveSynthSlot3Unlocked(unlocked);
    state = state.copyWith(synthSlot3Unlocked: unlocked);
  }

  Future<void> saveEquippedSynthsFor(
      String characterId, List<String?> equipped) async {
    final sm = ref.read(gameplaySaveProvider);
    await sm.saveEquippedSynthsFor(characterId, equipped);
    state = state.copyWith(
      characterSynths: {
        ...state.characterSynths,
        characterId: List<String?>.from(equipped),
      },
    );
  }

  Future<void> equipSynth({
    required String characterId,
    required String instanceId,
    required int slotIndex,
  }) async {
    final list = List<String?>.from(
        state.characterSynths[characterId] ?? List<String?>.filled(4, null));
    for (int i = 0; i < list.length; i++) {
      if (list[i] == instanceId) list[i] = null;
    }
    while (list.length <= slotIndex) {
      list.add(null);
    }
    list[slotIndex] = instanceId;

    for (final otherCharId in state.characterSynths.keys) {
      if (otherCharId == characterId) continue;
      final otherList = List<String?>.from(state.characterSynths[otherCharId]!);
      bool modified = false;
      for (int i = 0; i < otherList.length; i++) {
        if (otherList[i] == instanceId) {
          otherList[i] = null;
          modified = true;
        }
      }

      if (modified) {
        final remainingCount = otherList.where((id) => id != null).length;
        if (remainingCount == 0) {
          final allEquipped = <String>{};
          allEquipped.addAll(list.whereType<String>());
          for (final cId in state.characterSynths.keys) {
            if (cId == otherCharId || cId == characterId) continue;
            allEquipped.addAll(state.characterSynths[cId]!.whereType<String>());
          }

          final owned = ref.read(ownedSynthInstancesProvider);
          final fallbackId =
              owned.keys.firstWhereOrNull((id) => !allEquipped.contains(id));
          if (fallbackId != null) {
            otherList[0] = fallbackId;
          } else {
            final nowMs = DateTime.now().millisecondsSinceEpoch;
            final newInstanceId = 'synth_gen_${otherCharId}_$nowMs';
            final newInst = SynthInstance(
              instanceId: newInstanceId,
              definitionId: 'synth_01',
              equippedCharacterId: otherCharId,
              slotIndex: 0,
              unlockedAtMs: nowMs,
            );

            final sm = ref.read(gameplaySaveProvider);
            final currentInstances = Map<String, SynthInstance>.from(owned);
            currentInstances[newInstanceId] = newInst;
            await sm.saveSynthInstances(currentInstances);
            ref.read(ownedSynthInstancesProvider.notifier).refresh();

            otherList[0] = newInstanceId;
          }
        }
        await saveEquippedSynthsFor(otherCharId, otherList);
      }
    }

    await saveEquippedSynthsFor(characterId, list);
  }

  Future<void> unequipSynth({
    required String characterId,
    required int slotIndex,
  }) async {
    final list = List<String?>.from(
        state.characterSynths[characterId] ?? List<String?>.filled(4, null));
    final nonNullCount = list.where((id) => id != null).length;
    if (nonNullCount <= 1) {
      return;
    }
    if (slotIndex < list.length) {
      list[slotIndex] = null;
    }
    await saveEquippedSynthsFor(characterId, list);
  }

  Future<bool> unlockSynthSlot3() async {
    final tournamentProgress = ref.read(tournamentProgressProvider);
    final isTier1Cleared = tournamentProgress.containsKey('tier_1_cleared');
    if (!isTier1Cleared) return false;

    final wallet = ref.read(walletProvider);
    if (!wallet.canAfford(Currency.paint, 199)) return false;

    await ref
        .read(walletProvider.notifier)
        .spend(Currency.paint, 199, reason: 'synth_slot3_unlock');
    await saveSynthSlot3Unlocked(true);
    return true;
  }
}

final gameplaySaveNotifierProvider =
    NotifierProvider<GameplaySaveNotifier, GameplaySaveState>(
        GameplaySaveNotifier.new);

final saveSyncReadyProvider = FutureProvider<void>((ref) async {
  final sm = ref.watch(saveManagerProvider);
  if (sm.initialSyncFuture != null) {
    try {
      await sm.initialSyncFuture;
    } catch (e) {
      debugPrint('saveSyncReadyProvider: initial sync error: $e');
    }
  }
});
