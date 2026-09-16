import 'package:flutter_test/flutter_test.dart';
import 'package:colosynth/growth/character/character_progression.dart';
import 'package:colosynth/growth/equipment/equipment_progression.dart';

void main() {
  group('CharacterProgression Tests', () {
    test('Character level XP calculation is deterministic', () {
      expect(CharacterProgression.calcXpRequired(1), equals(0));
      expect(CharacterProgression.calcXpRequired(2), greaterThan(0));
      expect(CharacterProgression.calcXpRequired(99), greaterThan(CharacterProgression.calcXpRequired(50)));
    });

    test('Character level from total XP resolves correctly', () {
      const totalXp = 1500;
      final level = CharacterProgression.calcLevel(totalXp);
      expect(level, greaterThanOrEqualTo(1));
      expect(level, lessThanOrEqualTo(99));
    });
  });

  group('EquipmentProgression Tests', () {
    test('Equipment stats scale with level and breakthrough stage', () {
      final baseAtk = EquipmentProgression.equipStatAtLevel(
        'weapon',
        'atk',
        1,
        breakthroughCount: 0,
      );

      final upgradedAtk = EquipmentProgression.equipStatAtLevel(
        'weapon',
        'atk',
        10,
        breakthroughCount: 1,
      );

      expect(upgradedAtk, greaterThan(baseAtk));
    });
  });
}
