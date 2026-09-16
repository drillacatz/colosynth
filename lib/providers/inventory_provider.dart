import 'dart:math' as math;
import 'package:colosynth/database/synth/synth_instance.dart';
import 'package:colosynth/providers/save_provider.dart';
import 'package:colosynth/providers/exp_items_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum InventoryItemType { synth, expItem, key }

class InventoryItem {
  final String id;
  final InventoryItemType type;
  final SynthInstance? synthInstance;
  final int stackCount;

  InventoryItem({
    required this.id,
    required this.type,
    this.synthInstance,
    this.stackCount = 1,
  });
}

class Inventory {
  final List<String> characters;
  final List<InventoryItem> upgradeItems;

  Inventory({
    required this.characters,
    required this.upgradeItems,
  });

  bool ownsCharacter(String id) => characters.contains(id);
}

final inventoryProvider = Provider<Inventory>((ref) {
  final characters = ref.watch(unlockedCharactersProvider);
  final ownedSynths = ref.watch(ownedSynthInstancesProvider);
  final expItemsMap = ref.watch(expItemsProvider);

  final List<InventoryItem> items = [];

  for (final entry in ownedSynths.entries) {
    items.add(
      InventoryItem(
        id: entry.key,
        type: InventoryItemType.synth,
        synthInstance: entry.value,
        stackCount: 1,
      ),
    );
  }

  final sortedExpKeys = expItemsMap.keys.toList()..sort();
  for (final itemId in sortedExpKeys) {
    final totalCount = expItemsMap[itemId] ?? 0;
    if (totalCount > 0) {
      int countLeft = totalCount;
      while (countLeft > 0) {
        final currentStack = math.min(99, countLeft);
        items.add(
          InventoryItem(
            id: itemId,
            type: InventoryItemType.expItem,
            stackCount: currentStack,
          ),
        );
        countLeft -= currentStack;
      }
    }
  }

  return Inventory(
    characters: characters,
    upgradeItems: items,
  );
});
