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
import 'package:colosynth/widgets/comic/comic_word_badge.dart';
import 'package:colosynth/providers/tournament_provider.dart';
import 'package:colosynth/providers/tier_chest_provider.dart';
import 'package:colosynth/providers/shared_preferences_provider.dart';
import 'package:colosynth/widgets/comic/zzz_extruded_banner.dart';

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
      expect(find.byType(ComicWordBadge), findsOneWidget);
      expect(find.text('LV.5'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders pure digit roadmap and manga trapezoid milestone chip',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerProgressOverlay(
              level: 1,
              xp: 50,
              onDismiss: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Milestone digits should be displayed as pure numbers
      expect(find.text('2'), findsWidgets);

      // Verify trapezoid clip path is present for the milestone description box
      expect(find.byType(ClipPath), findsWidgets);

      // Verify initial selected milestone shows LEVEL 2 in the trapezoid card
      expect(find.textContaining('LEVEL 2'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('show modal dialog has full dim barrierColor (0xD0000000)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    PlayerProgressOverlay.show(context, level: 3, xp: 100);
                  },
                  child: const Text('SHOW'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('SHOW'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final modalBarrier =
          tester.widget<ModalBarrier>(find.byType(ModalBarrier).last);
      expect(modalBarrier.color, equals(const Color(0xD0000000)));

      // Dismiss dialog
      await tester.tap(find.byType(PlayerProgressOverlay));
      await tester.pumpAndSettle();
    });

    testWidgets(
        'renders ZZZ 3D extruded moving banner with ticker text and motion',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerProgressOverlay(
              level: 2,
              xp: 80,
              onDismiss: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Verify ZZZ banner ticker text exists
      expect(find.textContaining('PLAYER ROADMAP'), findsWidgets);
      expect(find.textContaining('LEVEL PROGRESSION'), findsWidgets);
      expect(find.textContaining('MILESTONE ARCHIVE'), findsWidgets);

      // Verify no exceptions thrown during fast-to-slow motion
      await tester.pump(const Duration(milliseconds: 1000));
      expect(tester.takeException(), isNull);
    });
  });

  group('ZZZ Dual LED Banner Tests', () {
    testWidgets('ZzzDualLedBanner renders both foreground LED and background ZZZ extruded text',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 44,
              child: ZzzDualLedBanner(
                label: 'INK SUPPLY',
                ledColor: Colors.cyanAccent,
                reverse: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(ZzzDualLedBanner), findsOneWidget);
      expect(find.byType(ZzzExtrudedText), findsWidgets);
      expect(find.textContaining('INK SUPPLY'), findsWidgets);
      expect(find.textContaining('COLOSYNTH SUPPLY'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ZzzDualLedBanner supports reverse scrolling mode',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 44,
              child: ZzzDualLedBanner(
                label: 'PAINT SUPPLY',
                ledColor: Colors.pinkAccent,
                reverse: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(ZzzDualLedBanner), findsOneWidget);
      expect(find.textContaining('PAINT SUPPLY'), findsWidgets);
      expect(find.textContaining('COLOSYNTH SUPPLY'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ZzzExtrudedText builds solid isometric shadow stack',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ZzzExtrudedText(
              text: 'ZZZ TEST',
              fontSize: 24,
              depth: 4.0,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('ZZZ TEST'), findsOneWidget);
      final textWidget = tester.widget<Text>(find.text('ZZZ TEST'));
      expect(textWidget.style?.shadows, isNotEmpty);
      expect(textWidget.style?.shadows?.length, equals(7)); // 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0
      expect(tester.takeException(), isNull);
    });
  });
}


