import 'dart:math' as math;
import 'package:colosynth/game_settings.dart';

/// Metadata for a music track in the centralized library.
class MusicTrack {
  final LobbyBgmType type;
  final String title;
  final String filename;
  final String duration;

  const MusicTrack({
    required this.type,
    required this.title,
    required this.filename,
    required this.duration,
  });
}

/// Single source of truth for all audio asset file names, pool sizes,
/// and display labels. Nothing else in the codebase should hard-code
/// audio file paths.
abstract final class AudioRepository {
  static final math.Random _rng = math.Random();

  /// Boss fight tracks used randomly during battle screen audio.
  static const List<String> bossFightTracks = [
    'boss_fight_1.wav',
    'boss_fight_2.wav',
    'boss_fight_3.mp3',
  ];

  static const Map<BgmTrack, String> bgmFiles = {
    BgmTrack.splash: 'splash.mp3',
    BgmTrack.title: 'title.mp3',
    BgmTrack.home: 'lobby.wav',
    BgmTrack.ready: 'ready_screen.wav',
    BgmTrack.battle: 'boss_fight_1.wav',
  };

  /// Lobby track files that the user can choose between.
  static const Map<LobbyBgmType, String> lobbyFiles = {
    LobbyBgmType.default_: 'lobby.wav',
    LobbyBgmType.groovy: 'lobby2.wav',
    LobbyBgmType.ready: 'ready_screen.wav',
    LobbyBgmType.boss1: 'boss_fight_1.wav',
    LobbyBgmType.boss2: 'boss_fight_2.wav',
    LobbyBgmType.boss3: 'boss_fight_3.mp3',
  };

  /// Centralized library of music tracks for settings/mixer display.
  static const List<MusicTrack> musicLibrary = [
    MusicTrack(
      type: LobbyBgmType.default_,
      title: 'Colosynth Theme',
      filename: 'lobby.wav',
      duration: '2:52',
    ),
    MusicTrack(
      type: LobbyBgmType.groovy,
      title: 'Lobby Beat 2',
      filename: 'lobby2.wav',
      duration: '0:16',
    ),
    MusicTrack(
      type: LobbyBgmType.ready,
      title: 'Ready Theme',
      filename: 'ready_screen.wav',
      duration: '0:14',
    ),
    MusicTrack(
      type: LobbyBgmType.boss1,
      title: 'Boss Fight Track 1',
      filename: 'boss_fight_1.wav',
      duration: '2:54',
    ),
    MusicTrack(
      type: LobbyBgmType.boss2,
      title: 'Boss Fight Track 2',
      filename: 'boss_fight_2.wav',
      duration: '3:01',
    ),
    MusicTrack(
      type: LobbyBgmType.boss3,
      title: 'Boss Fight Track 3',
      filename: 'boss_fight_3.mp3',
      duration: '4:34',
    ),
  ];

  static const Map<SfxEvent, String> sfxFiles = {
    SfxEvent.button: 'button.wav',
    SfxEvent.navigate: 'button.wav',
    SfxEvent.slash: 'slash.mp3',
    SfxEvent.hit: 'hit.mp3',
    SfxEvent.playerHurt: 'player_hurt.mp3',
    SfxEvent.parry: 'parry1.mp3',
    SfxEvent.block: 'block.mp3',
    SfxEvent.dodge: 'dodge.mp3',
    SfxEvent.activeskillCharged: 'skill_done.mp3',
    SfxEvent.victory: 'victory.wav',
    SfxEvent.defeat: 'defeat.wav',
    SfxEvent.reward: 'reward.wav',
    SfxEvent.combo: 'hit.mp3',
  };

  /// Set of verified audio assets physically present on disk.
  static const Set<String> bundledAudioFiles = {
    'boss_fight_1.wav',
    'boss_fight_2.wav',
    'boss_fight_3.mp3',
    'button.wav',
    'lobby.wav',
    'lobby2.wav',
    'parry1.mp3',
    'parry2.mp3',
    'parry3.mp3',
    'parry4.mp3',
    'ready_screen.wav',
    'skill_done.mp3',
    'splash.mp3',
    'title.mp3',
    'undefined.wav',
  };

  /// Fallbacks for SFX whose primary audio stem is not yet bundled.
  static const Map<SfxEvent, String> sfxFallbacks = {
    SfxEvent.slash: 'parry2.mp3',
    SfxEvent.hit: 'parry3.mp3',
    SfxEvent.playerHurt: 'parry4.mp3',
    SfxEvent.block: 'parry1.mp3',
    SfxEvent.dodge: 'parry2.mp3',
    SfxEvent.activeskillCharged: 'skill_done.mp3',
    SfxEvent.victory: 'ready_screen.wav',
    SfxEvent.defeat: 'undefined.wav',
    SfxEvent.reward: 'skill_done.mp3',
    SfxEvent.combo: 'parry3.mp3',
  };

  /// Resolves the audio file to load for an SFX event, using an available bundled asset fallback.
  static String resolveSfxFile(SfxEvent event) {
    final primary = sfxFiles[event];
    if (primary != null && bundledAudioFiles.contains(primary)) {
      return primary;
    }
    return sfxFallbacks[event] ?? 'button.wav';
  }

  /// Number of concurrent instances allowed per SFX event.
  static const Map<SfxEvent, int> sfxPoolSizes = {
    SfxEvent.button: 2,
    SfxEvent.navigate: 2,
    SfxEvent.slash: 3,
    SfxEvent.hit: 3,
    SfxEvent.playerHurt: 3,
    SfxEvent.parry: 3,
    SfxEvent.block: 3,
    SfxEvent.dodge: 3,
    SfxEvent.activeskillCharged: 2,
    SfxEvent.victory: 1,
    SfxEvent.defeat: 1,
    SfxEvent.reward: 1,
    SfxEvent.combo: 2,
  };


  /// Human-readable display names for lobby track tiles in [MusicScreen].
  static const Map<LobbyBgmType, String> lobbyDisplayNames = {
    LobbyBgmType.default_: 'COLOSYNTH THEME',
    LobbyBgmType.groovy: 'LOBBY BEAT 2',
    LobbyBgmType.ready: 'READY THEME',
    LobbyBgmType.boss1: 'BOSS FIGHT 1',
    LobbyBgmType.boss2: 'BOSS FIGHT 2',
    LobbyBgmType.boss3: 'BOSS FIGHT 3',
  };

  /// Resolve the file name for a [BgmTrack], taking into account the user's
  /// chosen lobby variant when the track is [BgmTrack.home], and picking a random
  /// boss fight audio track when the track is [BgmTrack.battle].
  static String resolveFile(BgmTrack track, LobbyBgmType lobbyType) {
    if (track == BgmTrack.battle) {
      return bossFightTracks[_rng.nextInt(bossFightTracks.length)];
    }
    if (track == BgmTrack.home) {
      return lobbyFiles[lobbyType] ?? bgmFiles[BgmTrack.home]!;
    }
    return bgmFiles[track]!;
  }
}

