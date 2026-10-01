import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:colosynth/providers/auth_provider.dart';
import 'package:colosynth/providers/notification_providers.dart';
import 'package:colosynth/providers/save_provider.dart';
import 'package:colosynth/game_settings.dart';
import 'package:colosynth/screens/settings/settings_screen.dart';
import 'package:colosynth/screens/settings/stats_screen.dart';
import 'package:colosynth/screens/settings/notifications_screen.dart';
import 'package:colosynth/screens/settings/music_screen.dart';
import 'package:colosynth/services/battle_stats_service.dart';
import 'package:colosynth/story/story_database.dart';

class _FakeAccountLevelNotifier extends AccountLevelNotifier {
  @override
  ({int accountLevel, int accountXp}) build() {
    return (accountLevel: 8, accountXp: 1250);
  }
}

class _FakeNotificationSettingsNotifier extends NotificationSettingsNotifier {
  @override
  NotificationSettingsState build() {
    return const NotificationSettingsState(
      dailySignInEnabled: true,
      bossAdsRefreshEnabled: true,
    );
  }
}

class _FakeSettingsNotifier extends SettingsNotifier {
  @override
  Future<GameSettings> build() async {
    return const GameSettings(
      bgmVolume: 80,
      sfxVolume: 65,
      bgmEnabled: true,
      sfxEnabled: true,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'totalBattles': 42,
      'totalWins': 28,
      'totalParries': 115,
      'totalBroken': 45,
      'longestWinStreak': 7,
      'currentWinStreak': 3,
      'totalLogins': 14,
      'tournamentWins_easy': 5,
      'tournamentWins_medium': 3,
      'tournamentWins_hard': 1,
      'tournamentWins_extreme': 0,
    });
    await BattleStatsService.instance.init();
  });

  Widget buildHarness(Widget child, {double width = 360, double height = 740}) {
    return ProviderScope(
      overrides: [
        accountLevelProvider.overrideWith(() => _FakeAccountLevelNotifier()),
        isGuestProvider.overrideWith((ref) => true),
        displayNameProvider.overrideWith((ref) => 'SynthPilot'),
        notificationSettingsProvider.overrideWith(() => _FakeNotificationSettingsNotifier()),
        settingsProvider.overrideWith(() => _FakeSettingsNotifier()),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(width, height)),
          child: child,
        ),
      ),
    );
  }

  group('Settings Screens Architecture & Layout Tests', () {
    testWidgets('StatsScreen renders complete career stats without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildHarness(const StatsScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('CAREER & STATS'), findsOneWidget);
      expect(find.text('BATTLE RECORD'), findsOneWidget);
      expect(find.text('STREAKS & RESILIENCE'), findsOneWidget);
      expect(find.text('COMBAT PERFORMANCE'), findsOneWidget);
      expect(find.text('ACCOUNT PROGRESSION'), findsOneWidget);
      expect(find.text('TOURNAMENT TROPHIES'), findsOneWidget);
    });

    testWidgets('SettingsScreen renders Scaffold with panels without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildHarness(const SettingsScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
      expect(find.text('SETTINGS'), findsOneWidget);
      expect(find.text('PROFILE'), findsOneWidget);
      expect(find.text('GAMEPLAY PREFERENCES'), findsOneWidget);
      expect(find.text('APP SUPPORT'), findsOneWidget);
      expect(find.text('COLOSYNTH'), findsOneWidget);
    });

    testWidgets('NotificationsScreen renders toggles without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildHarness(const NotificationsScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('NOTIFICATIONS'), findsOneWidget);
      expect(find.text('DAILY SIGN-IN REMINDER'), findsOneWidget);
      expect(find.text('BOSS DAILY REWARDED ADS REFRESH'), findsOneWidget);
    });

    testWidgets('MusicScreen renders AppBar and sections without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildHarness(const MusicScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
      expect(find.text('MUSIC & SOUND'), findsOneWidget);
    });

    testWidgets('AppSupportPanel renders 5 support square buttons with spacing',
        (tester) async {
      await tester.pumpWidget(buildHarness(const SettingsScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
      expect(find.byIcon(Icons.mail_outline), findsOneWidget);
      expect(find.byIcon(Icons.auto_stories_outlined), findsOneWidget);
      expect(find.byIcon(Icons.share_outlined), findsOneWidget);
      expect(find.byIcon(Icons.star_outline), findsOneWidget);
    });
  });

  group('Tutorial Story & Dialogue Tests', () {
    test('StoryDatabase maps tutorial_0 to Chalk Dummy intro and outro', () {
      final intro = StoryDatabase.getIntroForLevel('tutorial_0');
      expect(intro, isNotNull);
      expect(intro!.id, equals('t1_a_0_intro'));
      expect(intro.nodes.any((n) => n.dialogueText.contains('CHALK')), isTrue);

      final outro = StoryDatabase.getOutroForLevel('tutorial_0');
      expect(outro, isNotNull);
      expect(outro!.id, equals('t1_a_0_outro'));
    });
  });
}
