import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colosynth/game/app_shell/battle_result.dart';
import 'package:colosynth/game/widgets/battle_overlays.dart';
import 'package:colosynth/game_data/character_database.dart';
import 'package:colosynth/game_data/level_data.dart';
import 'package:colosynth/providers/daily_checkin_provider.dart';
import 'package:colosynth/providers/inventory_provider.dart';
import 'package:colosynth/providers/save_provider.dart';
import 'package:colosynth/providers/tournament_provider.dart';
import 'package:colosynth/screens/character/character_misc.dart';
import 'package:colosynth/screens/error/initialization_error_screen.dart';
import 'package:colosynth/screens/overlays/claim_reward_overlay.dart';
import 'package:colosynth/screens/overlays/daily_checkin_dialog.dart';
import 'package:colosynth/screens/overlays/daily_task_overlay.dart';
import 'package:colosynth/screens/overlays/level_up_overlay.dart';
import 'package:colosynth/screens/overlays/locked_feature_overlay.dart';
import 'package:colosynth/screens/result/result_screen.dart';
import 'package:colosynth/screens/settings/app_support_panel.dart';
import 'package:colosynth/screens/store/recruit_confirm_overlay.dart';
import 'package:colosynth/screens/tournament/tournament_screen.dart';
import 'package:colosynth/screens/upgrade/upgrade_inventory_view.dart';
import 'package:colosynth/services/daily_checkin_service.dart';

class _FakeDailyCheckInNotifier extends DailyCheckInNotifier {
  @override
  DailyCheckInState build() => DailyCheckInState.initial();
}

class _FakeTournamentProgressNotifier extends TournamentProgressNotifier {
  @override
  Map<String, String> build() => {};
  @override
  Future<void> markCompleted(String slotId) async {}
}

class _FakeAccountLevelNotifier extends AccountLevelNotifier {
  @override
  ({int accountLevel, int accountXp}) build() {
    return (accountLevel: 12, accountXp: 1850);
  }
}

class _FakeSynthKeysNotifier extends SynthKeysNotifier {
  @override
  int build() => 5;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestHost({
    required Widget child,
    Size size = const Size(320, 568),
    double textScale = 1.0,
  }) {
    return ProviderScope(
      overrides: [
        dailyCheckInProvider.overrideWith(() => _FakeDailyCheckInNotifier()),
        tournamentProgressProvider.overrideWith(() => _FakeTournamentProgressNotifier()),
        tutorialCompletedProvider.overrideWith((ref) => true),
        accountLevelProvider.overrideWith(() => _FakeAccountLevelNotifier()),
        inventoryProvider.overrideWithValue(Inventory(characters: [], upgradeItems: [])),
        inkProvider.overrideWithValue(25400),
        paintProvider.overrideWithValue(350),
        synthKeysProvider.overrideWith(() => _FakeSynthKeysNotifier()),
      ],
      child: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
          padding: const EdgeInsets.only(top: 20, bottom: 20),
        ),
        child: MaterialApp(
          home: Scaffold(body: child),
        ),
      ),
    );
  }

  Future<void> testWidgetOverflow(
    WidgetTester tester, {
    required Widget child,
    Size size = const Size(320, 568),
    double textScale = 1.3,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      buildTestHost(
        child: child,
        size: size,
        textScale: textScale,
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('RenderFlex Overflow Prevention Suite (Compact Viewports & High Text Scaling)', () {
    testWidgets('UpgradeInventoryView renders on 320x568 with 1.3x text scale without overflow', (tester) async {
      await testWidgetOverflow(tester, child: const InventoryView());
    });

    testWidgets('DailyTaskOverlay renders on 320x568 with 1.3x text scale without overflow', (tester) async {
      await testWidgetOverflow(tester, child: const DailyTaskOverlay());
    });

    testWidgets('DailyCheckInDialog renders on 320x568 with 1.3x text scale without overflow', (tester) async {
      await testWidgetOverflow(tester, child: const DailyCheckInDialog());
    });

    testWidgets('LevelUpOverlay renders on 320x568 with 1.3x text scale without overflow', (tester) async {
      await testWidgetOverflow(
        tester,
        child: LevelUpOverlay(
          newLevel: 5,
          newUnlocks: const [],
          onDismiss: () {},
        ),
      );
    });

    testWidgets('ClaimRewardOverlay renders on 320x568 with 1.3x text scale without overflow', (tester) async {
      await testWidgetOverflow(
        tester,
        child: ClaimRewardOverlay(
          inkReward: 500,
          paintReward: 100,
          xpReward: 250,
          expItems: const {'exp_book_common': 2, 'exp_hammer_common': 1},
          onDismiss: () {},
        ),
      );
    });

    testWidgets('LockedFeatureOverlay renders on 320x568 with 1.3x text scale without overflow', (tester) async {
      await testWidgetOverflow(
        tester,
        child: LockedFeatureOverlay(
          customTitle: 'Tournament Mode Locked',
          customDescription: 'Clear previous lesson in Training Grounds to unlock.',
          requiredLevel: 2,
          currentLevel: 1,
          onDismiss: () {},
        ),
      );
    });

    testWidgets('ResultScreen renders on 320x568 without Spacer overflow', (tester) async {
      final slot = kArenas.first.tournaments.first.stages.first.bossSlot;

      final result = BattleResult.empty(BattleOutcome.defeat).copyWith(
        inkEarned: 0,
        paintEarned: 0,
        xpEarned: 10,
        score: 500,
      );

      await testWidgetOverflow(
        tester,
        child: ResultScreen(slot: slot, result: result),
        textScale: 1.0,
      );
    });

    testWidgets('TournamentScreen renders on 320x568 with 1.3x text scale without overflow', (tester) async {
      await testWidgetOverflow(tester, child: const TournamentScreen());
    });

    testWidgets('CharacterNameBar renders in constrained 260px container with 1.3x text scale', (tester) async {
      final char = CharacterDatabase.all.first;

      await testWidgetOverflow(
        tester,
        child: SizedBox(
          width: 260,
          child: CharacterNameBar(
            character: char,
            level: 15,
          ),
        ),
      );
    });

    testWidgets('AppSupportPanel renders in constrained 240px container without horizontal overflow', (tester) async {
      await testWidgetOverflow(
        tester,
        child: const SizedBox(
          width: 240,
          child: AppSupportPanel(),
        ),
        textScale: 1.0,
      );
    });

    testWidgets('InitializationErrorScreen renders on 320x568 with 1.3x text scale without overflow', (tester) async {
      await testWidgetOverflow(
        tester,
        child: InitializationErrorScreen(
          error: 'Detailed exception trace with long descriptive lines that take substantial space',
          onRetry: () {},
        ),
      );
    });

    testWidgets('RecruitConfirmOverlay renders on 320x568 with 1.3x text scale without overflow', (tester) async {
      final char = CharacterDatabase.all.first;

      await testWidgetOverflow(
        tester,
        child: RecruitConfirmOverlay(
          character: char,
          canAfford: false,
          onConfirm: () {},
          onCancel: () {},
        ),
      );
    });

    testWidgets('VictoryOverlay renders on 320x568 with 1.3x text scale without overflow', (tester) async {
      final result = BattleResult.empty(BattleOutcome.victory).copyWith(
        inkEarned: 100,
        paintEarned: 20,
        xpEarned: 60,
      );

      await testWidgetOverflow(
        tester,
        child: VictoryOverlay(
          result: result,
          onContinue: () {},
        ),
      );
    });

    testWidgets('DefeatOverlay renders on 320x568 with 1.3x text scale without overflow', (tester) async {
      await testWidgetOverflow(
        tester,
        child: DefeatOverlay(
          reviveAvailable: true,
          onRevive: () {},
          onRestart: () {},
          onQuit: () {},
        ),
      );
    });
  });
}
