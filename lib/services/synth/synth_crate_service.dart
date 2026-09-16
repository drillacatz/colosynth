import 'dart:math' as math;

import 'package:colosynth/database/synth/synth_definition.dart';
import 'package:colosynth/database/synth/synth_instance.dart';
import 'package:colosynth/game/event_bus/game_event_bus.dart';
import 'package:colosynth/game/event_bus/game_events.dart';
import 'package:colosynth/growth/synth/synth_database.dart';
import 'package:colosynth/growth/synth/synth_module.dart';
import 'package:colosynth/services/gameplay_save_manager.dart';
import 'package:colosynth/services/save_manager.dart';

/// Handles opening Synth Crates and managing the Synth inventory.
class SynthCrateService {
  SynthCrateService._();
  static final SynthCrateService instance = SynthCrateService._();

  static final _rng = math.Random();

  GameplaySaveManager get _gameplay => SaveManager.instance.gameplay;


  int loadSynthKeys() {
    return _gameplay.loadSynthKeys();
  }

  Future<void> saveSynthKeys(int count) async {
    await _gameplay.saveSynthKeys(count);
  }

  /// Called on every tournament stage first-clear to award 1 Synth Key.
  Future<void> onStageFirstClear() async {
    final newCount = loadSynthKeys() + 1;
    await saveSynthKeys(newCount);
    GameEventBus.instance.emit(const SynthKeyGrantedEvent(1));
  }


  /// Opens a single Synth Crate. Returns the SynthInstance awarded and
  /// whether it was a duplicate (definition already owned).
  Future<({SynthInstance instance, bool isDuplicate})> openCrate({
    required int nowMs,
  }) async {
    final allDefs = SynthDatabase.getAllDefinitions();
    final owned = _gameplay.loadSynthInstances();

    final unownedDefs = allDefs.where((def) => !SynthModule.isAlreadyOwned(
      definitionId: def.id,
      existingInstances: owned.values,
    )).toList();

    if (unownedDefs.isNotEmpty) {
      final picked = unownedDefs[_rng.nextInt(unownedDefs.length)];
      final newInstance = SynthModule.createInstance(
        definitionId: picked.id,
        nowMs: nowMs,
      );

      owned[newInstance.instanceId] = newInstance;
      await _gameplay.saveSynthInstances(owned);

      return (instance: newInstance, isDuplicate: false);
    } else {
      final picked = allDefs[_rng.nextInt(allDefs.length)];
      final newInstance = SynthModule.createInstance(
        definitionId: picked.id,
        nowMs: nowMs,
      );

      await _gameplay.addExpItem('exp_note_legendary', 1);

      return (instance: newInstance, isDuplicate: true);
    }
  }


  /// Returns the SynthDefinitions equipped to a given character,
  /// in slot order, skipping null slots.
  List<SynthDefinition> loadEquippedDefinitions(String characterId) {
    final equippedIds = _gameplay.loadEquippedSynthsFor(characterId);
    final allInstances = _gameplay.loadSynthInstances();
    final allDefs = SynthDatabase.getAllDefinitions();

    final result = <SynthDefinition>[];
    for (final id in equippedIds) {
      if (id == null) continue;
      final inst = allInstances[id];
      if (inst == null) continue;
      final def = allDefs.firstWhere(
        (d) => d.id == inst.definitionId,
        orElse: () => allDefs.first,
      );
      result.add(def);
    }
    return result;
  }
}
