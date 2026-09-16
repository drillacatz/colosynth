import 'package:flutter_test/flutter_test.dart';
import 'package:colosynth/game/logic/damage_law.dart';
import 'package:colosynth/game/logic/direction.dart';
import 'package:colosynth/database/synth/synth_definition.dart';

void main() {
  group('Combat Damage Mechanics Tests', () {
    test('Normal slash damage multiplier is within 20% to 30% range', () {
      final normalDamage = DamageLaw.computeWithSynthBonus(
        1000,
        0,
        0,
        type: HitType.normal,
      );

      expect(normalDamage, greaterThanOrEqualTo(200));
      expect(normalDamage, lessThanOrEqualTo(300));
    });

    test('Counter Slash combo scaling scales from 1.00x up to 1.50x', () {
      final hit1 = DamageLaw.computeWithSynthBonus(1000, 0, 0, type: HitType.counterSlash, comboCount: 1);
      final hit2 = DamageLaw.computeWithSynthBonus(1000, 0, 0, type: HitType.counterSlash, comboCount: 2);
      final hit3 = DamageLaw.computeWithSynthBonus(1000, 0, 0, type: HitType.counterSlash, comboCount: 3);
      final hit4 = DamageLaw.computeWithSynthBonus(1000, 0, 0, type: HitType.counterSlash, comboCount: 4);
      final hit5 = DamageLaw.computeWithSynthBonus(1000, 0, 0, type: HitType.counterSlash, comboCount: 5);

      expect(hit1, equals(1000));
      expect(hit2, equals(1150));
      expect(hit3, equals(1200));
      expect(hit4, equals(1350));
      expect(hit5, equals(1500));
    });

    test('SynthDefinition caps combo sequence to max 5 directions', () {
      final longSeq = [
        AttackDirection.n,
        AttackDirection.s,
        AttackDirection.e,
        AttackDirection.w,
        AttackDirection.ne,
        AttackDirection.sw,
        AttackDirection.nw,
      ];
      final synth = SynthDefinition(
        id: 'test_long',
        name: 'Long Synth',
        comboSequence: longSeq,
        counterStaminaDamage: 10,
        bonusDamageMult: 1.5,
        activeSkillChargeBonus: 5,
        unlockCostPaint: 10,
        unlockCostInk: 50,
      );

      expect(synth.effectiveSequence.length, equals(5));
      expect(synth.effectiveSequence, equals(longSeq.sublist(0, 5)));
    });

    test('Attack directions map to valid angle representations', () {
      expect(AttackDirection.e, isNotNull);
      expect(AttackDirection.n, isNotNull);
      expect(AttackDirection.values.length, equals(8));
    });
  });
}
