import 'package:colosynth/database/synth/synth_definition.dart';
import 'package:colosynth/database/synth/synth_instance.dart';

/// Resolves Synth bonuses and handles Synth upgrades/unlocks.
class SynthModule {
  SynthModule._();

  /// Returns the effective bonus damage multiplier of a synth at base level.
  static double bonusMultiplier(SynthDefinition def) => def.bonusDamageMult;

  /// Returns the counter stamina damage for a synth.
  static int counterStaminaDamage(SynthDefinition def) =>
      def.counterStaminaDamage;

  /// Returns the active skill charge bonus for a synth.
  static int activeSkillChargeBonus(SynthDefinition def) =>
      def.activeSkillChargeBonus;

  /// Returns whether a player can afford to unlock this synth.
  static bool canAffordUnlock({
    required SynthDefinition def,
    required int currentPaint,
    required int currentInk,
  }) {
    return currentPaint >= def.unlockCostPaint &&
        currentInk >= def.unlockCostInk;
  }

  /// Creates a new SynthInstance for a definition.
  static SynthInstance createInstance({
    required String definitionId,
    required int nowMs,
  }) {
    final instanceId = 'synth_inst_${nowMs}_$definitionId';
    return SynthInstance(
      instanceId: instanceId,
      definitionId: definitionId,
      unlockedAtMs: nowMs,
    );
  }

  /// Checks if a definition is already owned given a list of instances.
  static bool isAlreadyOwned({
    required String definitionId,
    required Iterable<SynthInstance> existingInstances,
  }) {
    return existingInstances.any((i) => i.definitionId == definitionId);
  }
}
