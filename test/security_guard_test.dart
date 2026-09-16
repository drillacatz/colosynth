import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:colosynth/services/security_guard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SecurityGuard guard;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    guard = SecurityGuard.instance;
    await guard.init(prefs);
  });

  group('SecurityGuard Tests', () {
    test('computeTag and verifyTag generate valid HMAC tags', () {
      final tag = guard.computeTag('ink', 500);
      expect(tag, isNotEmpty);
      expect(guard.verifyTag('ink', 500, tag), isTrue);
      expect(guard.verifyTag('ink', 501, tag), isFalse);
    });

    test('validateAwardSource allows valid sources and rejects invalid ones', () {
      expect(() => guard.validateAwardSource('tournament_stage_reward'), returnsNormally);
      expect(() => guard.validateAwardSource('daily_checkin_day_1'), returnsNormally);
      expect(() => guard.validateAwardSource('hacked_cheat_code'), throwsA(isA<InvalidSourceException>()));
    });

    test('validateSpendReason checks allowed spend reasons', () {
      expect(() => guard.validateSpendReason('upgrade_character'), returnsNormally);
      expect(() => guard.validateSpendReason('illegal_spend_type'), throwsA(isA<InvalidSourceException>()));
    });

    test('checkAwardRate permits 10+ rapid awards for daily tasks and milestones without rate limiting', () {
      for (int i = 0; i < 15; i++) {
        expect(() => guard.checkAwardRate('daily_task'), returnsNormally);
      }
      for (int i = 0; i < 5; i++) {
        expect(() => guard.checkAwardRate('daily_milestone'), returnsNormally);
      }
      for (int i = 0; i < 5; i++) {
        expect(() => guard.checkAwardRate('weekly_activity'), returnsNormally);
      }
    });

    test('isIapSource recognizes standardized product IDs and legacy IAP tags', () {
      expect(guard.isIapSource('colosynth_ink_12000'), isTrue);
      expect(guard.isIapSource('colosynth_paint_2500'), isTrue);
      expect(guard.isIapSource('iap:ink_70000'), isTrue);
      expect(guard.isIapSource('store_purchase'), isTrue);
      expect(guard.isIapSource('daily_task'), isFalse);
    });
  });
}
