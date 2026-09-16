import 'package:colosynth/database/synth/synth_definition.dart';
import 'package:colosynth/game/logic/direction.dart';

class SynthSequenceResult {
  final List<SynthDefinition> completed;
  final bool hasMatchedStep;

  const SynthSequenceResult({
    required this.completed,
    required this.hasMatchedStep,
  });
}

class SynthSequenceMatcher {
  final List<SynthDefinition> definitions;
  final Map<String, int> _progress = {};

  SynthSequenceMatcher(this.definitions) {
    for (final def in definitions) {
      _progress[def.id] = 0;
    }
  }

  SynthSequenceResult feedDirection(AttackDirection dir) {
    final List<SynthDefinition> completed = [];
    bool matchedAny = false;

    for (final def in definitions) {
      final seq = def.comboSequence.take(5).toList();
      if (seq.isEmpty) continue;

      final currentIdx = _progress[def.id] ?? 0;
      if (seq[currentIdx] == dir) {
        matchedAny = true;
        final newIdx = currentIdx + 1;
        if (newIdx == seq.length) {
          completed.add(def);
          _progress[def.id] = 0;
        } else {
          _progress[def.id] = newIdx;
        }
      } else {
        if (seq[0] == dir) {
          matchedAny = true;
          _progress[def.id] = 1;
        } else {
          _progress[def.id] = 0;
        }
      }
    }
    return SynthSequenceResult(
      completed: completed,
      hasMatchedStep: matchedAny,
    );
  }

  void resetAll() {
    for (final key in _progress.keys) {
      _progress[key] = 0;
    }
  }
}
