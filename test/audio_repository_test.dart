import 'package:flutter_test/flutter_test.dart';
import 'package:colosynth/game_settings.dart';
import 'package:colosynth/services/audio_repository.dart';

void main() {
  group('AudioRepository Tests', () {
    test('resolveSfxFile returns bundled file for button event', () {
      final file = AudioRepository.resolveSfxFile(SfxEvent.button);
      expect(file, equals('button.wav'));
      expect(AudioRepository.bundledAudioFiles, contains(file));
    });

    test('resolveSfxFile returns safe fallback for unbundled stems', () {
      final slashFile = AudioRepository.resolveSfxFile(SfxEvent.slash);
      expect(AudioRepository.bundledAudioFiles, contains(slashFile));

      final hitFile = AudioRepository.resolveSfxFile(SfxEvent.hit);
      expect(AudioRepository.bundledAudioFiles, contains(hitFile));

      final victoryFile = AudioRepository.resolveSfxFile(SfxEvent.victory);
      expect(AudioRepository.bundledAudioFiles, contains(victoryFile));
    });

    test('resolveFile returns valid BGM audio files', () {
      final homeFile = AudioRepository.resolveFile(BgmTrack.home, LobbyBgmType.default_);
      expect(homeFile, equals('lobby.wav'));
      expect(AudioRepository.bundledAudioFiles, contains(homeFile));

      final battleFile = AudioRepository.resolveFile(BgmTrack.battle, LobbyBgmType.default_);
      expect(AudioRepository.bundledAudioFiles, contains(battleFile));
    });
  });
}
