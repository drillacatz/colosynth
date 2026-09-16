import 'package:colosynth/database/synth/synth_definition.dart';
import 'package:colosynth/database/synth/synth_instance.dart';
import 'package:colosynth/game/logic/synth_sequence_matcher.dart';
import 'package:colosynth/game/logic/direction.dart';

/// Manages which Synths are equipped for the current battle and
/// resolves synth bonus multipliers when the counter window is open.
class CounterSynthController {
  CounterSynthController({required this.equippedDefinitions});

  final List<SynthDefinition> equippedDefinitions;
  late final SynthSequenceMatcher _matcher =
      SynthSequenceMatcher(equippedDefinitions);

  SynthDefinition? _lastTriggered;

  SynthDefinition? get lastTriggered => _lastTriggered;

  /// Feed a swipe direction during the counter window.
  /// Returns a [SynthSequenceResult] with completed Synths and matching state.
  SynthSequenceResult feedDirectionInCounterWindow(AttackDirection dir) {
    final result = _matcher.feedDirection(dir);
    if (result.completed.isNotEmpty) {
      _lastTriggered = result.completed.first;
    }
    return result;
  }

  /// Returns the last triggered definition's counter stamina damage bonus.
  int lastCounterStaminaDamage() => _lastTriggered?.counterStaminaDamage ?? 0;

  /// Returns the last triggered definition's skill charge bonus.
  int lastActiveSkillChargeBonus() =>
      _lastTriggered?.activeSkillChargeBonus ?? 0;

  void resetLastTriggered() {
    _lastTriggered = null;
  }

  void resetSequences() {
    _matcher.resetAll();
    _lastTriggered = null;
  }

  /// Convenience factory to build from raw SynthInstance list + definition lookup.
  static CounterSynthController fromInstances(
    List<SynthInstance> instances,
    List<SynthDefinition> allDefinitions,
  ) {
    final defs = <SynthDefinition>[];
    for (final inst in instances) {
      final def = allDefinitions.firstWhere(
        (d) => d.id == inst.definitionId,
        orElse: () => allDefinitions.first,
      );
      defs.add(def);
    }
    return CounterSynthController(equippedDefinitions: defs);
  }
}
