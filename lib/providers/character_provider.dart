import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:colosynth/services/achievement_service.dart';
import 'package:colosynth/services/remote_config_service.dart';
import 'package:colosynth/providers/save_provider.dart';
import 'package:colosynth/providers/exp_items_provider.dart';
import 'package:colosynth/game/event_bus/game_event_bus.dart';
import 'package:colosynth/game/event_bus/game_events.dart';

final charLevelProvider = Provider<({int level, int xp})>((ref) {
  final charId = ref.watch(equippedCharacterIdProvider);
  final data = ref.watch(characterLevelFamily(charId));
  return (level: data.level, xp: data.xp);
});

final characterLevelFamily = NotifierProvider.family<CharacterLevelNotifier,
    ({int level, int xp}), String>(CharacterLevelNotifier.new);

class CharacterLevelNotifier extends Notifier<({int level, int xp})> {
  final String charId;
  CharacterLevelNotifier(this.charId);

  @override
  ({int level, int xp}) build() {
    final level = ref.watch(gameplaySaveNotifierProvider.select((s) => s.charLevels[charId] ?? 1));
    final xp = ref.watch(gameplaySaveNotifierProvider.select((s) => s.charXp[charId] ?? 0));
    return (level: level, xp: xp);
  }

  Future<void> addXp(int xp) => ref
      .read(gameplaySaveNotifierProvider.notifier)
      .addCharXp(charId, xp);

  Future<void> upgrade([String? targetItemId]) async {
    final expNotifier = ref.read(expItemsProvider.notifier);
    final itemId = targetItemId ?? _findAvailableBook();
    if (itemId == null) return;
    if (expNotifier.quantityOf(itemId) <= 0) return;

    final cost = (state.level + 1) * 50;
    if (ref.read(inkProvider) < cost) return;

    await expNotifier.consume(itemId);
    await ref.read(walletProvider.notifier).spend(Currency.ink, cost, reason: 'upgrade_character');
    final xpAmount = RemoteConfigService.instance.expItemXpFor(itemId);
    await ref
        .read(gameplaySaveNotifierProvider.notifier)
        .addCharXp(charId, xpAmount > 0 ? xpAmount : 500);

    GameEventBus.instance.emit(ExpItemConsumedEvent(itemId, 1));

    final newLevel =
        ref.read(gameplaySaveNotifierProvider).charLevels[charId] ?? 1;
    await ref
        .read(achievementServiceProvider)
        .checkCharLevelAchievements(newLevel);
  }

  String? _findAvailableBook() {
    final expNotifier = ref.read(expItemsProvider.notifier);
    for (final key in ['exp_book_legendary', 'exp_book_epic', 'exp_book_rare', 'exp_book_common', 'exp_book']) {
      if (expNotifier.quantityOf(key) > 0) return key;
    }
    return null;
  }
}

final characterBreakthroughFamily =
    NotifierProvider.family<CharacterBreakthroughNotifier, int, String>(
        CharacterBreakthroughNotifier.new);

class CharacterBreakthroughNotifier extends Notifier<int> {
  final String charId;
  CharacterBreakthroughNotifier(this.charId);

  @override
  int build() {
    return ref.watch(gameplaySaveNotifierProvider.select((s) => s.charBreakthroughs[charId] ?? 0));
  }

  Future<void> setBreakthrough(int count) async {
    await ref
        .read(gameplaySaveNotifierProvider.notifier)
        .saveCharBreakthrough(charId, count);
  }
}




final skillTreeProvider =
    NotifierProvider<SkillTreeNotifier, Set<String>>(SkillTreeNotifier.new);

class SkillTreeNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() =>
      ref.watch(gameplaySaveNotifierProvider.select((s) => s.skillTree));
  Future<void> unlock(String id, int cost, Set<String> prereqs) async {
    if (state.contains(id) || !prereqs.every(state.contains)) return;
    await ref.read(walletProvider.notifier).spend(Currency.ink, cost, reason: 'skill_unlock');
    await ref
        .read(gameplaySaveNotifierProvider.notifier)
        .saveSkillTree({...state, id});
  }

  Future<void> reset() async {
    final cost = RemoteConfigService.instance.skillTreeResetPaint;
    await ref.read(walletProvider.notifier).spend(Currency.paint, cost, reason: 'skill_reset');
    await ref.read(gameplaySaveNotifierProvider.notifier).resetSkillTree();
  }
}
