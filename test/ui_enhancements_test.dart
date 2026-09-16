import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:colosynth/screens/overlays/top_bar/level_exp_chip.dart';
import 'package:colosynth/screens/overlays/daily_task_overlay.dart';
import 'package:colosynth/screens/tournament/tournament_logic.dart';
import 'package:colosynth/screens/store/recruit_tab_screen.dart';
import 'package:colosynth/screens/level/tier_chest_overlay.dart';
import 'package:colosynth/screens/overlays/player_progress_overlay.dart';
import 'package:colosynth/providers/tournament_provider.dart';
import 'package:colosynth/providers/tier_chest_provider.dart';
import 'package:colosynth/providers/shared_preferences_provider.dart';

class _MockTournamentProgressNotifier extends TournamentProgressNotifier {
  @override
  Map<String, String> build() => const {};
}

class _MockTierChestNotifier extends TierChestNotifier {
  _MockTierChestNotifier(super.tier);
  @override
  TierChestState build() => const TierChestState(
        claimed: [false, false, false, false, false, false],
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LevelExpChip Tests', () {
    testWidgets('renders XP text without keyboard_arrow_right chevron',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LevelExpChip(
              level: 5,
              xp: 250,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(LevelExpChip), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_right), findsNothing);
    });
  });

  group('DailyTaskOverlay Dialog Tests', () {
    testWidgets('renders inside a Dialog container', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DailyTaskOverlay(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(DailyTaskOverlay), findsOneWidget);
    });
  });

  group('Tournament Target Logic Tests', () {
    test('buildTournamentList returns sorted tiers', () {
      final items = buildTournamentList();
      expect(items, isNotEmpty);
      for (int i = 0; i < items.length - 1; i++) {
        expect(items[i].tournament.tier <= items[i + 1].tournament.tier, isTrue);
      }
    });

    test('tournamentCompletedCount correctly counts progress', () {
      final items = buildTournamentList();
      final t1 = items.first.tournament;
      final total = tournamentTotalSlots(t1);
      expect(total, greaterThan(0));

      final progress = <String, String>{};
      expect(tournamentCompletedCount(t1, progress), 0);

      final firstSlotId = t1.stages.first.normalSlots.first.id;
      progress[firstSlotId] = '3';
      expect(tournamentCompletedCount(t1, progress), 1);
    });
  });

  group('RecruitTabScreen Surround Carousel Tests', () {
    testWidgets('renders recruit tab with surround cards and arrow controls',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: RecruitTabScreen(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(RecruitTabScreen), findsOneWidget);
      expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

      // Tap next arrow to navigate
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
    });
  });

  group('TierChestOverlay Dialog Tests', () {
    testWidgets('renders inside a Dialog container with comic styling',
        (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            tournamentProgressProvider
                .overrideWith(_MockTournamentProgressNotifier.new),
            tierChestProvider(1).overrideWith(() => _MockTierChestNotifier(1)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: TierChestOverlay(
                tier: 1,
                tournamentName: 'Novice Arena',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('TIER 1 REWARDS'), findsOneWidget);
      expect(find.text('NOVICE ARENA'), findsOneWidget);
      expect(find.byType(TierChestOverlay), findsOneWidget);
    });
  });

  group('PlayerProgressOverlay Tests', () {
    testWidgets('renders player progress overlay with level and xp',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerProgressOverlay(
              level: 5,
              xp: 1200,
              onDismiss: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(PlayerProgressOverlay), findsOneWidget);
      expect(find.text('LEVEL'), findsOneWidget);
      expect(find.text('5'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
