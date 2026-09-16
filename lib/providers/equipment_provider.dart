import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:colosynth/services/achievement_service.dart';
import 'package:colosynth/growth/equipment/equipment_progression.dart';
import 'package:colosynth/database/character/character_equipment_slot.dart';
import 'package:colosynth/providers/save_provider.dart';
import 'package:colosynth/providers/exp_items_provider.dart';
import 'package:colosynth/game/event_bus/game_event_bus.dart';
import 'package:colosynth/game/event_bus/game_events.dart';

final charEquipmentProvider =
    Provider.family<Map<String, CharacterEquipmentSlot>, String>((ref, charId) {
  final save = ref.watch(gameplaySaveNotifierProvider);
  return save.characterEquipment[charId] ??
      const {
        'weapon': CharacterEquipmentSlot(level: 1, xp: 0, breakthroughCount: 0),
        'shield': CharacterEquipmentSlot(level: 1, xp: 0, breakthroughCount: 0),
        'armor': CharacterEquipmentSlot(level: 1, xp: 0, breakthroughCount: 0),
        'helmet': CharacterEquipmentSlot(level: 1, xp: 0, breakthroughCount: 0),
      };
});

final equipmentLevelsProvider = NotifierProvider<EquipmentLevelsNotifier,
    Map<String, ({int level, int xp})>>(EquipmentLevelsNotifier.new);

class EquipmentLevelsNotifier
    extends Notifier<Map<String, ({int level, int xp})>> {
  @override
  Map<String, ({int level, int xp})> build() {
    final charId = ref.watch(equippedCharacterIdProvider);
    final equip = ref.watch(gameplaySaveNotifierProvider
        .select((s) => s.characterEquipment[charId] ?? const {}));
    return equip.map((k, v) => MapEntry(k, (level: v.level, xp: v.xp)));
  }

  bool canBreakthrough(String slotKey) {
    final bt = ref.read(equipmentBreakthroughProvider)[slotKey] ?? 0;
    final level = state[slotKey]?.level ?? 1;
    final cap = EquipmentProgression.levelCapForBreakthrough(bt);
    return level >= cap && bt < 2;
  }

  bool canUpgrade(String slotKey) {
    final level = state[slotKey]?.level ?? 1;
    final bt = ref.read(equipmentBreakthroughProvider)[slotKey] ?? 0;
    final cap = EquipmentProgression.levelCapForBreakthrough(bt);
    return level < cap;
  }

  int upgradeCost(String slotKey) {
    final level = state[slotKey]?.level ?? 1;
    return EquipmentProgression.upgradeCost(level);
  }

  int breakthroughCost(String slotKey) {
    final bt = ref.read(equipmentBreakthroughProvider)[slotKey] ?? 0;
    return EquipmentProgression.breakthroughPaintCost(bt + 1);
  }

  String _upgradeReason(String slotKey) {
    switch (slotKey) {
      case 'weapon':
        return 'upgrade_weapon';
      case 'shield':
        return 'upgrade_shield';
      case 'armor':
        return 'upgrade_armor';
      case 'helmet':
        return 'upgrade_helmet';
      default:
        return 'upgrade_weapon';
    }
  }

  Future<void> upgrade(String itemId, String slotKey) async {
    if (!canUpgrade(slotKey)) return;
    final current = state[slotKey] ?? (level: 1, xp: 0);
    final cost = upgradeCost(slotKey);

    if (ref.read(inkProvider) < cost) return;

    final expNotifier = ref.read(expItemsProvider.notifier);
    final hammerKey = expNotifier.quantityOf(itemId) > 0 ? itemId : _findAvailableHammer();
    if (hammerKey == null || expNotifier.quantityOf(hammerKey) <= 0) {
      return;
    }

    final charId = ref.read(equippedCharacterIdProvider);

    await expNotifier.consume(hammerKey);
    await ref
        .read(walletProvider.notifier)
        .spend(Currency.ink, cost, reason: _upgradeReason(slotKey));
    await ref
        .read(gameplaySaveNotifierProvider.notifier)
        .saveEquipmentLevel(charId, slotKey, current.level + 1);

    GameEventBus.instance
        .emit(EquipmentUpgradedEvent(charId, slotKey, current.level + 1));

    await ref
        .read(achievementServiceProvider)
        .checkEquipLevelAchievements(current.level + 1);
  }

  String? _findAvailableHammer() {
    final expNotifier = ref.read(expItemsProvider.notifier);
    for (final key in ['exp_hammer_legendary', 'exp_hammer_epic', 'exp_hammer_rare', 'exp_hammer_common', 'exp_hammer']) {
      if (expNotifier.quantityOf(key) > 0) return key;
    }
    return null;
  }

  Future<void> breakthrough(String itemId, String slotKey) async {
    if (!canBreakthrough(slotKey)) return;
    final bt = ref.read(equipmentBreakthroughProvider)[slotKey] ?? 0;
    final cost = breakthroughCost(slotKey);
    if (cost > 0) {
      if (ref.read(paintProvider) < cost) return;
      await ref
          .read(walletProvider.notifier)
          .spend(Currency.paint, cost, reason: 'equipment_breakthrough');
    }
    final nextBt = bt + 1;
    final charId = ref.read(equippedCharacterIdProvider);
    await ref
        .read(gameplaySaveNotifierProvider.notifier)
        .saveEquipmentBreakthrough(charId, slotKey, nextBt);

    final level = state[slotKey]?.level ?? 1;
    await ref
        .read(achievementServiceProvider)
        .checkEquipLevelAchievements(level);
  }

  Future<void> addXpToAll(int amount) {
    final charId = ref.read(equippedCharacterIdProvider);
    return ref
        .read(gameplaySaveNotifierProvider.notifier)
        .addEquipmentXpToAll(charId, amount);
  }
}

final equipmentBreakthroughProvider =
    NotifierProvider<EquipmentBreakthroughNotifier, Map<String, int>>(
        EquipmentBreakthroughNotifier.new);

class EquipmentBreakthroughNotifier extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() {
    final charId = ref.watch(equippedCharacterIdProvider);
    final equip = ref.watch(gameplaySaveNotifierProvider
        .select((s) => s.characterEquipment[charId] ?? const {}));
    return equip.map((k, v) => MapEntry(k, v.breakthroughCount));
  }
}

