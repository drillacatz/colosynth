import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:colosynth/services/auth_service.dart';
import 'package:colosynth/services/user_data_service.dart';
import 'package:colosynth/services/account_sync_service.dart';
import 'package:colosynth/services/fcm_service.dart';
import 'package:colosynth/services/sp_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late UserDataService userDataService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    userDataService = UserDataService();
  });

  group('Safe Firebase Offline Fallback Tests (Firebase.apps.isEmpty)', () {
    test('AuthService.instance.currentUser returns null gracefully without throwing', () {
      expect(AuthService.instance.currentUser, isNull);
    });

    test('UserDataService handles guest user initialization without throwing when offline', () async {
      await expectLater(
        userDataService.initUser('test_guest_uid', isGuest: true),
        completes,
      );
    });

    test('UserDataService tracks login rewards locally in SharedPreferences when Firestore is unavailable', () async {
      final claimedBefore = await userDataService.hasClaimedLoginReward(
        'test_user',
        'google',
        prefs: prefs,
      );
      expect(claimedBefore, isFalse);

      final claimResult = await userDataService.claimLoginReward(
        'test_user',
        'google',
        prefs: prefs,
      );
      expect(claimResult, isTrue);

      final claimedAfter = await userDataService.hasClaimedLoginReward(
        'test_user',
        'google',
        prefs: prefs,
      );
      expect(claimedAfter, isTrue);
    });

    test('UserDataService saves custom display name to SharedPreferences when offline', () async {
      await userDataService.saveCustomDisplayName(
        'test_user',
        'HeroPlayer',
        prefs: prefs,
      );
      expect(prefs.getString(SPKeys.customDisplayName), 'HeroPlayer');
    });

    test('AccountSyncService flush and push execute safely without throwing when offline', () async {
      AccountSyncService.instance.bindUser('test_sync_uid');
      AccountSyncService.instance.push({'paint': 50});
      await expectLater(AccountSyncService.instance.flushNow(), completes);
    });

    test('FcmService bindUser executes safely without throwing when Firebase is uninitialized', () async {
      await expectLater(FcmService.instance.bindUser('test_fcm_uid'), completes);
    });
  });
}
