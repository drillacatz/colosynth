import 'package:flutter_test/flutter_test.dart';
import 'package:colosynth/services/daily_checkin_service.dart';
import 'package:colosynth/services/security_guard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DailyCheckInService logic tests', () {
    test('Rewards schedule contains 7 days', () {
      expect(DailyCheckInService.rewardsSchedule.length, equals(7));
      expect(DailyCheckInService.rewardsSchedule[0].ink, equals(200));
      expect(DailyCheckInService.rewardsSchedule[1].ink, equals(500));
      expect(DailyCheckInService.rewardsSchedule[2].paint, equals(5));
      expect(DailyCheckInService.rewardsSchedule[3].itemKey, equals('exp_book_rare'));
      expect(DailyCheckInService.rewardsSchedule[3].itemCount, equals(2));
      expect(DailyCheckInService.rewardsSchedule[4].ink, equals(200));
      expect(DailyCheckInService.rewardsSchedule[5].paint, equals(5));
      expect(DailyCheckInService.rewardsSchedule[6].ink, equals(700));
    });

    test('Initial DailyCheckInState defaults to cycle day 1 and unclaimed', () {
      final state = DailyCheckInState.initial();
      expect(state.currentCycleDay, equals(1));
      expect(state.isClaimedToday, isFalse);
      expect(state.isDoubleClaimedToday, isFalse);
      expect(state.makeUpUsedInCycle, equals(0));
      expect(state.advanceClaimUsedInCycle, equals(0));
      expect(state.missedYesterday, isFalse);
    });

    test('Serialization and deserialization of DailyCheckInState', () {
      final now = DateTime.now();
      final original = DailyCheckInState(
        currentCycleDay: 3,
        lastCheckInDate: now,
        isClaimedToday: true,
        isDoubleClaimedToday: false,
        makeUpUsedInCycle: 0,
        advanceClaimUsedInCycle: 0,
        isAdvanceClaimedTomorrow: false,
        missedYesterday: false,
      );

      final json = original.toJson();
      final restored = DailyCheckInState.fromJson(json, now);

      expect(restored.currentCycleDay, equals(3));
      expect(restored.isClaimedToday, isTrue);
    });

    test('SecurityGuard validates daily check-in reward sources', () {
      expect(() => SecurityGuard.instance.validateAwardSource('daily_checkin_day_1'), returnsNormally);
      expect(() => SecurityGuard.instance.validateAwardSource('daily_checkin_day_3_double'), returnsNormally);
      expect(() => SecurityGuard.instance.validateAwardSource('daily_checkin_day_5_makeup'), returnsNormally);
    });
  });
}
