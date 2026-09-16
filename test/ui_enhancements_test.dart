import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:colosynth/screens/overlays/top_bar/level_exp_chip.dart';
import 'package:colosynth/screens/overlays/daily_task_overlay.dart';
import 'package:colosynth/screens/tournament/tournament_logic.dart';
import 'package:colosynth/screens/store/recruit_tab_screen.dart';

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
}
