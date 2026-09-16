import 'package:colosynth/database/synth/synth_definition.dart';

class SynthDatabase {
  static SynthDefinition? getDefinition(String id) {
    for (final def in globalSynthDefinitions) {
      if (def.id == id) return def;
    }
    return null;
  }

  static List<SynthDefinition> getAllDefinitions() => globalSynthDefinitions;
}
