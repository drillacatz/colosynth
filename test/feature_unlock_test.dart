import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:colosynth/providers/feature_unlock_provider.dart';
import 'package:colosynth/providers/save_provider.dart';
import 'package:colosynth/providers/tournament_provider.dart';
import 'package:colosynth/services/level_progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ProgressionService.instance.init();
  });

  group('FeatureUnlock tests', () {
    test('ProgressionService requires permanent unlock for Character and Upgrade tabs', () {
      expect(
        ProgressionService.instance.isUnlocked(UnlockableFeature.characterScreen, 1),
        isFalse,
      );
      expect(
        ProgressionService.instance.isUnlocked(UnlockableFeature.upgradeTab, 2),
        isFalse,
      );
    });

    test('featureUnlockProvider unlocks character screen on tutorial completion', () {
      final container = ProviderContainer(
        overrides: [
          saveSyncReadyProvider.overrideWith((ref) => Future.value(null)),
          accountLevelProvider.overrideWith(
            () => _MockAccountLevelNotifier(1),
          ),
          tutorialCompletedProvider.overrideWith((ref) => false),
          tournamentProgressProvider.overrideWith(
            () => _MockTournamentProgressNotifier({}),
          ),
        ],
      );
      addTearDown(container.dispose);

      final initial = container.read(featureUnlockProvider);
      expect(initial.isCharacterScreenUnlocked, isFalse);
      expect(initial.isUpgradeScreenUnlocked, isFalse);

      // Now with tutorial completed
      final containerTutorialDone = ProviderContainer(
        overrides: [
          saveSyncReadyProvider.overrideWith((ref) => Future.value(null)),
          accountLevelProvider.overrideWith(
            () => _MockAccountLevelNotifier(1),
          ),
          tutorialCompletedProvider.overrideWith((ref) => true),
          tournamentProgressProvider.overrideWith(
            () => _MockTournamentProgressNotifier({}),
          ),
        ],
      );
      addTearDown(containerTutorialDone.dispose);

      final stateWithTutorial = containerTutorialDone.read(featureUnlockProvider);
      expect(stateWithTutorial.isCharacterScreenUnlocked, isTrue);
      expect(stateWithTutorial.isUpgradeScreenUnlocked, isFalse);
    });

    test('featureUnlockProvider unlocks upgrade screen when 3 stages are cleared', () {
      final containerStagesDone = ProviderContainer(
        overrides: [
          saveSyncReadyProvider.overrideWith((ref) => Future.value(null)),
          accountLevelProvider.overrideWith(
            () => _MockAccountLevelNotifier(1),
          ),
          tutorialCompletedProvider.overrideWith((ref) => true),
          tournamentProgressProvider.overrideWith(
            () => _MockTournamentProgressNotifier({
              'tutorial_2': 'completed',
              't1_a_0': 'completed',
              't1_a_1': 'completed',
              't1_a_2': 'completed',
            }),
          ),
        ],
      );
      addTearDown(containerStagesDone.dispose);

      final state = containerStagesDone.read(featureUnlockProvider);
      expect(state.isCharacterScreenUnlocked, isTrue);
      expect(state.isUpgradeScreenUnlocked, isTrue);
    });
  });
}

class _MockAccountLevelNotifier extends AccountLevelNotifier {
  _MockAccountLevelNotifier(this._initialLevel);
  final int _initialLevel;

  @override
  ({int accountLevel, int accountXp}) build() {
    return (accountLevel: _initialLevel, accountXp: 0);
  }
}

class _MockTournamentProgressNotifier extends TournamentProgressNotifier {
  _MockTournamentProgressNotifier(this._initialProgress);
  final Map<String, String> _initialProgress;

  @override
  Map<String, String> build() => _initialProgress;
}
