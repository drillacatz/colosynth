import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:colosynth/database/character/battle_stats.dart';
import 'package:colosynth/database/character/character_save.dart';
import 'package:colosynth/database/character/character_equipment_slot.dart';
import 'package:colosynth/database/equipment/equipment_instance.dart';
import 'package:colosynth/growth/character/character_module.dart';
import 'package:colosynth/growth/character/skills/skill_tree_module.dart';
import 'package:colosynth/growth/equipment/equipment_module.dart';
import 'package:colosynth/services/battle_stats_resolver.dart';
import 'package:colosynth/providers/save_provider.dart';
import 'package:colosynth/providers/tournament_provider.dart';

final battleStatsProvider =
    AsyncNotifierProvider<BattleStatsNotifier, BattleStats>(
  BattleStatsNotifier.new,
);

class BattleStatsNotifier extends AsyncNotifier<BattleStats> {
  @override
  Future<BattleStats> build() async {
    await ref.watch(saveSyncReadyProvider.future);

    final saveState = ref.watch(gameplaySaveNotifierProvider);
    final unlockedSkills = ref.watch(skillTreeProvider);
    final charId = ref.watch(equippedCharacterIdProvider);
    final charLevelData = ref.watch(characterLevelFamily(charId));
    final breakthrough = ref.watch(characterBreakthroughFamily(charId));

    final charSave = CharacterSave(
      charId: charId,
      level: charLevelData.level,
      xp: charLevelData.xp,
      breakthroughCount: breakthrough,
      equipment: saveState.characterEquipment[charId] ?? const {},
      synthSlots: saveState.characterSynths[charId] ?? List<String?>.filled(4, null),
    );
    final charStats = CharacterModule.resolveStats(charSave);

    final gearSet = <String, EquipmentInstance>{};
    for (final slot in ['weapon', 'shield', 'armor', 'helmet']) {
      final slotData = charSave.equipment[slot] ?? const CharacterEquipmentSlot(level: 1, xp: 0, breakthroughCount: 0);

      gearSet[slot] = EquipmentInstance(
        instanceId: '${slot}_inst',
        equipId: '${charId}_$slot',
        slot: slot,
        level: slotData.level,
        xp: slotData.xp,
        breakthroughCount: slotData.breakthroughCount,
      );
    }
    final equipStats = EquipmentModule.resolveGearSet(gearSet);

    final skillTreeStats = SkillTreeModule.resolveStats(unlockedSkills);

    final tournamentProgress = ref.watch(tournamentProgressProvider);
    final isTier1Cleared = tournamentProgress.containsKey('tier_1_cleared');

    int synthAtk = 0;
    int synthHp = 0;

    for (int slotIndex = 0; slotIndex < 4; slotIndex++) {
      bool isUnlocked = false;
      if (slotIndex == 0) {
        isUnlocked = true;
      } else if (slotIndex == 1) {
        isUnlocked = isTier1Cleared;
      } else if (slotIndex == 2) {
        isUnlocked = isTier1Cleared && saveState.synthSlot3Unlocked;
      } else if (slotIndex == 3) {
        isUnlocked = charLevelData.level >= 50;
      }

      if (isUnlocked) {
        final equippedSynthId = (saveState.characterSynths[charId] != null &&
                slotIndex < saveState.characterSynths[charId]!.length)
            ? saveState.characterSynths[charId]![slotIndex]
            : null;
        if (equippedSynthId != null) {
          final level = saveState.synthSlotLevels[slotIndex] ?? 1;
          synthAtk += (((level - 1) / 98.0) * 500).round();
          synthHp += (((level - 1) / 98.0) * 5000).round();
        }
      }
    }

    return BattleStatsResolver.aggregate(
      char: charStats,
      equip: equipStats,
      skillTree: skillTreeStats,
      synthAtk: synthAtk,
      synthHp: synthHp,
    );
  }
}
