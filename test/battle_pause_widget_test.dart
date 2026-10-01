import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:colosynth/game/widgets/battle_pause_widget.dart';

void main() {
  group('BattlePauseWidget Tests', () {
    testWidgets('renders main pause menu with Bangers PAUSED title and buttons',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BattlePauseWidget(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PAUSED'), findsOneWidget);
      expect(find.text('RESUME'), findsOneWidget);
      expect(find.text('RESTART'), findsOneWidget);
      expect(find.text('QUIT'), findsOneWidget);
      expect(find.text('ABANDON BATTLE?'), findsNothing);
    });

    testWidgets('triggers onResume when RESUME is tapped', (tester) async {
      bool resumed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BattlePauseWidget(
              onResume: () => resumed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('RESUME'));
      await tester.pumpAndSettle();

      expect(resumed, isTrue);
    });

    testWidgets('triggers onRestart when RESTART is tapped', (tester) async {
      bool restarted = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BattlePauseWidget(
              onRestart: () => restarted = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('RESTART'));
      await tester.pumpAndSettle();

      expect(restarted, isTrue);
    });

    testWidgets(
        'transitions in-place to ABANDON BATTLE? confirmation when QUIT is tapped',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BattlePauseWidget(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('QUIT'));
      await tester.pumpAndSettle();

      expect(find.text('ABANDON BATTLE?'), findsOneWidget);
      expect(find.text('Current match progress and rewards will be forfeited.'),
          findsOneWidget);
      expect(find.text('KEEP FIGHTING'), findsOneWidget);
      expect(find.text('QUIT BATTLE'), findsOneWidget);
      expect(find.text('PAUSED'), findsNothing);
    });

    testWidgets(
        'transitions back to PAUSED when KEEP FIGHTING is tapped',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BattlePauseWidget(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap QUIT to enter confirmation
      await tester.tap(find.text('QUIT'));
      await tester.pumpAndSettle();
      expect(find.text('ABANDON BATTLE?'), findsOneWidget);

      // Tap KEEP FIGHTING to cancel
      await tester.tap(find.text('KEEP FIGHTING'));
      await tester.pumpAndSettle();

      expect(find.text('PAUSED'), findsOneWidget);
      expect(find.text('ABANDON BATTLE?'), findsNothing);
    });

    testWidgets('triggers onQuit when QUIT BATTLE is tapped in confirmation',
        (tester) async {
      bool quit = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BattlePauseWidget(
              onQuit: () => quit = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('QUIT'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('QUIT BATTLE'));
      await tester.pumpAndSettle();

      expect(quit, isTrue);
    });

    testWidgets(
        'PopScope back navigation: cancels quit confirm first, then calls onResume',
        (tester) async {
      bool resumed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BattlePauseWidget(
              onResume: () => resumed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open quit confirm
      await tester.tap(find.text('QUIT'));
      await tester.pumpAndSettle();
      expect(find.text('ABANDON BATTLE?'), findsOneWidget);

      // 1. Simulate back button on quit confirm
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      // Should be back on main pause menu and NOT resumed
      expect(find.text('PAUSED'), findsOneWidget);
      expect(resumed, isFalse);

      // 2. Simulate back button on main pause menu
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      // Should call onResume
      expect(resumed, isTrue);
    });
  });
}
