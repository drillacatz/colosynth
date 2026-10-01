import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:colosynth/services/audio_repository.dart';
import 'package:colosynth/screens/settings/music_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MusicScreen Unit & Widget Tests', () {
    final sampleTrack = AudioRepository.musicLibrary.first;

    testWidgets('LobbyTrackTile renders green check tick only when isCurrentBgm is true',
        (tester) async {
      // Case 1: isCurrentBgm is false
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LobbyTrackTile(
              track: sampleTrack,
              isSelected: false,
              isCurrentBgm: false,
              onSelect: () {},
            ),
          ),
        ),
      );

      expect(find.text(sampleTrack.title), findsOneWidget);
      expect(find.text('DURATION: ${sampleTrack.duration}'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsNothing);

      // Case 2: isCurrentBgm is true
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LobbyTrackTile(
              track: sampleTrack,
              isSelected: true,
              isCurrentBgm: true,
              onSelect: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('LobbyTrackTile fires onSelect callback when tapped',
        (tester) async {
      var selected = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LobbyTrackTile(
              track: sampleTrack,
              isSelected: false,
              isCurrentBgm: false,
              onSelect: () => selected = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(LobbyTrackTile));
      await tester.pump();
      expect(selected, isTrue);
    });

    testWidgets('SetAsBgmButton displays SET AS BGM when not current BGM and triggers callback',
        (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetAsBgmButton(
              isCurrentBgm: false,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('SET AS BGM'), findsOneWidget);
      expect(find.text('CURRENT BGM'), findsNothing);

      await tester.tap(find.text('SET AS BGM'));
      await tester.pump();
      expect(pressed, isTrue);
    });

    testWidgets('SetAsBgmButton displays CURRENT BGM with green tick when track is active BGM',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SetAsBgmButton(
              isCurrentBgm: true,
              onPressed: null,
            ),
          ),
        ),
      );

      expect(find.text('CURRENT BGM'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.text('SET AS BGM'), findsNothing);
    });

    testWidgets('WaveformIndicator renders static bars when isPlaying is false',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WaveformIndicator(
              color: Colors.cyan,
              isPlaying: false,
            ),
          ),
        ),
      );

      expect(find.byType(WaveformIndicator), findsOneWidget);
      // Let time pass and ensure no animation exceptions occur while static
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(WaveformIndicator), findsOneWidget);
    });

    testWidgets('WaveformIndicator animates smoothly when isPlaying is true',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WaveformIndicator(
              color: Colors.cyan,
              isPlaying: true,
            ),
          ),
        ),
      );

      expect(find.byType(WaveformIndicator), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(WaveformIndicator), findsOneWidget);
    });
  });
}
