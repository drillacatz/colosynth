import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/widgets.dart';

import 'package:colosynth/game_settings.dart';
import 'package:colosynth/services/audio_repository.dart';

/// Cross-fade duration used when switching BGM tracks.
const Duration _kCrossFadeDuration = Duration(milliseconds: 500);

/// Tick interval for the volume-fade timer.
const Duration _kFadeTick = Duration(milliseconds: 50);

/// Centralized audio service for Colosynth.
///
/// Responsibilities:
///   • Single BGM channel (FlameAudio.bgm) with cross-fade transitions.
///   • SFX pool management via FlameAudio.createPool.
///   • Lobby-track preview channel (separate AudioPlayer, pauses main BGM).
///   • Lifecycle pause/resume handling.
///   • Settings application (volume, mute, lobby-bgm selection).
///
/// Usage:
///   ```dart
///   await AudioService.instance.init();
///   AudioService.instance.playBgm(BgmTrack.home);
///   AudioService.instance.playSfx(SfxEvent.button);
///   ```
class AudioService {
  AudioService._();

  static final AudioService instance = AudioService._();


  bool _initialized = false;
  bool _bgmInitialized = false;
  Completer<void>? _bgmInitCompleter;

  /// Returns a future that completes when init finishes (used for awaiting readiness).
  Future<void> get _bgmReady {
    if (_bgmInitialized) return Future.value();
    if (_bgmInitCompleter == null) {
      _bgmInitCompleter = Completer<void>();
      unawaited(init());
    }
    return _bgmInitCompleter!.future;
  }

  bool _sfxEnabled = true;
  bool _bgmEnabled = true;
  double _sfxVolume = 0.80;
  double _bgmVolume = 0.80;
  double _currentBgmVolume = 0.80;
  LobbyBgmType _selectedLobbyBgm = LobbyBgmType.default_;

  BgmTrack? _currentTrack;
  String? _currentFile;


  Timer? _fadeTimer;
  bool _isFading = false;


  final Map<LobbyBgmType, AudioPlayer> _previewPlayers = {};
  LobbyBgmType? _previewingType;
  bool _previewActive = false;

  /// Returns the active preview player if a track is currently being previewed.
  AudioPlayer? get activePreviewPlayer => _previewActive && _previewingType != null ? _previewPlayers[_previewingType] : null;


  final Map<SfxEvent, AudioPool> _sfxPools = {};


  /// Initialise the audio service.
  ///
  /// Call once during app startup (before any playback requests).
  /// Subsequent calls are no-ops.
  Future<void> init() async {
    if (_initialized) return;
    try {
      await FlameAudio.bgm.initialize();
      _bgmInitialized = true;
      if (_bgmInitCompleter != null && !_bgmInitCompleter!.isCompleted) {
        _bgmInitCompleter!.complete();
      }

      final futures = <Future<void>>[];
      for (final entry in AudioRepository.sfxFiles.entries) {
        final event = entry.key;
        final file = AudioRepository.resolveSfxFile(event);
        final maxPlayers = AudioRepository.sfxPoolSizes[event] ?? 1;
        futures.add(
          FlameAudio.createPool(file, maxPlayers: maxPlayers).then((pool) {
            _sfxPools[event] = pool;
          }).catchError((_) {}),
        );
      }

      await Future.wait(futures);
    } catch (e) {
      _bgmInitialized = true;
      if (_bgmInitCompleter != null && !_bgmInitCompleter!.isCompleted) {
        _bgmInitCompleter!.complete();
      }
    }
    _initialized = true;
  }


  /// Play [track] as the main BGM.
  ///
  /// If [crossFade] is true (default) the current track fades out while the
  /// new one fades in. Set to false for an instant cut.
  Future<void> playBgm(BgmTrack track, {bool crossFade = true}) async {
    final BgmTrack? previousTrack = _currentTrack;
    _currentTrack = track;

    if (!_bgmEnabled) {
      return;
    }
    if (!_bgmInitialized) await _bgmReady;
    if (!_bgmEnabled) return;

    final file = AudioRepository.resolveFile(track, _selectedLobbyBgm);

    if (file == _currentFile && _isPlaying()) return;

    _currentFile = file;

    final targetVolume = _targetBgmVolume(track);

    if (crossFade && _isPlaying()) {
      final startVolume = _isFading 
          ? _currentBgmVolume 
          : (previousTrack != null ? _targetBgmVolume(previousTrack) : _bgmVolume);
      await _crossFadeTo(file, startVolume, targetVolume);
    } else {
      _cancelFade();
      try {
        await FlameAudio.bgm.stop();
      } catch (_) {}
      try {
        await FlameAudio.bgm.audioPlayer.setReleaseMode(ReleaseMode.loop);
        await FlameAudio.bgm.play(file, volume: targetVolume);
        _currentBgmVolume = targetVolume;
      } catch (_) {}
    }
  }

  /// Stop the main BGM, optionally fading out first.
  Future<void> stopBgm({bool fade = true}) async {
    if (!_bgmInitialized) return;
    if (fade && _isPlaying()) {
      await _fadeOut();
    }
    _cancelFade();
    try {
      await FlameAudio.bgm.stop();
    } catch (_) {}
    _currentFile = null;
  }

  /// Pause the main BGM (and the preview if active).
  Future<void> pauseBgm() async {
    if (_previewActive && _previewingType != null) {
      try {
        await _previewPlayers[_previewingType]?.pause();
      } catch (_) {}
    }
    if (_bgmInitialized) {
      try {
        await FlameAudio.bgm.pause();
      } catch (_) {}
    }
  }

  /// Resume the main BGM (and the preview if active).
  Future<void> resumeBgm() async {
    if (_previewActive && _previewingType != null) {
      try {
        await _previewPlayers[_previewingType]?.resume();
      } catch (_) {}
      return;
    }
    if (!_bgmEnabled) return;
    if (_bgmInitialized) {
      try {
        await FlameAudio.bgm.resume();
      } catch (_) {}
    }
  }


  /// Start previewing [type] in the secondary player.
  ///
  /// The main BGM is paused while the preview is active.
  /// Call [stopPreview] to stop and optionally resume main BGM.
  Future<void> previewLobbyTrack(LobbyBgmType type) async {
    if (_previewingType == type) {
      await stopPreview(resumeMain: true);
      return;
    }

    if (_previewActive && _previewingType != null) {
      try {
        await _previewPlayers[_previewingType]?.stop();
      } catch (_) {}
    } else {
      await pauseBgm();
    }

    _previewingType = type;
    _previewActive = true;

    try {
      var player = _previewPlayers[type];
      if (player == null) {
        final file = AudioRepository.lobbyFiles[type];
        if (file != null) {
          player = AudioPlayer();
          await player.setSource(AssetSource('audio/$file'));
          await player.setReleaseMode(ReleaseMode.loop);
          _previewPlayers[type] = player;
        }
      }
      if (player != null) {
        await player.setVolume(_bgmVolume);
        await player.resume();
      }
    } catch (_) {}
  }

  /// Stop the preview player.
  ///
  /// If [resumeMain] is true, the main BGM is resumed afterwards.
  Future<void> stopPreview({bool resumeMain = true}) async {
    if (!_previewActive || _previewingType == null) return;
    try {
      await _previewPlayers[_previewingType]?.stop();
    } catch (_) {}
    _previewActive = false;
    _previewingType = null;
    if (resumeMain) {
      await resumeBgm();
    }
  }

  /// Update the preview player volume when the user moves the slider.
  void updatePreviewVolume(double volume) {
    if (!_previewActive || _previewingType == null) return;
    try {
      _previewPlayers[_previewingType]?.setVolume(volume);
    } catch (_) {}
  }

  /// Release non-essential audio resources under system memory pressure.
  void trimMemory() {
    if (!_previewActive) {
      for (final player in _previewPlayers.values) {
        try {
          player.dispose();
        } catch (_) {}
      }
      _previewPlayers.clear();
    }
  }


  /// Play a sound effect. Safe to call even before [init] completes.
  void playSfx(SfxEvent event) {
    if (!_sfxEnabled) return;
    if (!_initialized) {
      unawaited(init());
      return;
    }
    try {
      _sfxPools[event]?.start(volume: _sfxVolume);
    } catch (_) {}
  }


  /// Apply a [GameSettings] snapshot.
  ///
  /// Called by [SettingsNotifier] whenever settings change. Handles
  /// muting/unmuting, volume changes, and lobby BGM selection.
  void applySettings(GameSettings settings) {
    _sfxEnabled = settings.sfxEnabled;
    _sfxVolume = settings.sfxVolume / 100.0;

    final bool wasBgmEnabled = _bgmEnabled;
    final double oldBgmVolume = _bgmVolume;
    final LobbyBgmType oldLobbyBgm = _selectedLobbyBgm;

    _bgmEnabled = settings.bgmEnabled;
    _bgmVolume = settings.bgmVolume / 100.0;
    _selectedLobbyBgm = settings.selectedLobbyBgm;

    if (_previewActive) {
      updatePreviewVolume(_bgmVolume);
    }

    if (!wasBgmEnabled && _bgmEnabled) {
      if (_currentTrack != null) {
        unawaited(playBgm(_currentTrack!, crossFade: false));
      }
    } else if (wasBgmEnabled && !_bgmEnabled) {
      if (!_previewActive) unawaited(stopBgm(fade: false));
    } else if (_bgmEnabled) {
      if (_currentTrack == BgmTrack.home && oldLobbyBgm != _selectedLobbyBgm) {
        _currentFile = null;
        unawaited(playBgm(BgmTrack.home));
      } else if (oldBgmVolume != _bgmVolume) {
        _applyLiveVolume();
      }
    }
  }


  /// Forward Flutter app lifecycle events to the audio service.
  void handleLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        pauseBgm();
      case AppLifecycleState.resumed:
        resumeBgm();
      default:
        break;
    }
  }


  bool _isPlaying() {
    try {
      return FlameAudio.bgm.audioPlayer.state == PlayerState.playing;
    } catch (_) {
      return false;
    }
  }

  /// Target BGM volume for [track], respecting [_bgmVolume].
  ///
  /// Splash/title tracks get full user volume (no more hardcoded 0.85).
  /// Battle track gets 75% of user volume to match the previous convention.
  double _targetBgmVolume(BgmTrack track) {
    return switch (track) {
      BgmTrack.battle => _bgmVolume * 0.75,
      _ => _bgmVolume,
    };
  }


  Future<void> _crossFadeTo(String newFile, double startVolume, double targetVolume) async {
    _cancelFade();
    _isFading = true;

    final totalTicks = _kCrossFadeDuration.inMilliseconds ~/ _kFadeTick.inMilliseconds;
    int tick = 0;

    final fadeOutCompleter = Completer<void>();
    _fadeTimer = Timer.periodic(_kFadeTick, (timer) {
      tick++;
      final progress = tick / totalTicks;
      final vol = startVolume * (1.0 - progress).clamp(0.0, 1.0);
      try {
        FlameAudio.bgm.audioPlayer.setVolume(vol);
        _currentBgmVolume = vol;
      } catch (_) {}
      if (progress >= 1.0) {
        timer.cancel();
        if (!fadeOutCompleter.isCompleted) fadeOutCompleter.complete();
      }
    });

    await fadeOutCompleter.future;
    if (!_isFading) return;

    _cancelFade();
    try {
      await FlameAudio.bgm.stop();
      await FlameAudio.bgm.audioPlayer.setReleaseMode(ReleaseMode.loop);
      await FlameAudio.bgm.play(newFile, volume: 0.0);
      _currentBgmVolume = 0.0;
    } catch (_) {
      _isFading = false;
      return;
    }

    tick = 0;
    final fadeInCompleter = Completer<void>();
    _fadeTimer = Timer.periodic(_kFadeTick, (timer) {
      tick++;
      final progress = tick / totalTicks;
      final vol = (targetVolume * progress).clamp(0.0, targetVolume);
      try {
        FlameAudio.bgm.audioPlayer.setVolume(vol);
        _currentBgmVolume = vol;
      } catch (_) {}
      if (progress >= 1.0) {
        timer.cancel();
        if (!fadeInCompleter.isCompleted) fadeInCompleter.complete();
      }
    });

    await fadeInCompleter.future;
    _isFading = false;
  }

  Future<void> _fadeOut() async {
    _cancelFade();
    _isFading = true;

    final totalTicks = _kCrossFadeDuration.inMilliseconds ~/ _kFadeTick.inMilliseconds;
    int tick = 0;

    final startVol = _currentBgmVolume > 0.0 
        ? _currentBgmVolume 
        : (_currentTrack != null ? _targetBgmVolume(_currentTrack!) : _bgmVolume);

    final completer = Completer<void>();
    _fadeTimer = Timer.periodic(_kFadeTick, (timer) {
      tick++;
      final progress = tick / totalTicks;
      final vol = startVol * (1.0 - progress).clamp(0.0, 1.0);
      try {
        FlameAudio.bgm.audioPlayer.setVolume(vol);
        _currentBgmVolume = vol;
      } catch (_) {}
      if (progress >= 1.0) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete();
      }
    });

    await completer.future;
    _isFading = false;
  }

  Completer<void>? _activeFadeCompleter;

  void _cancelFade() {
    _fadeTimer?.cancel();
    _fadeTimer = null;
    _isFading = false;
    if (_activeFadeCompleter != null && !_activeFadeCompleter!.isCompleted) {
      _activeFadeCompleter!.complete();
    }
    _activeFadeCompleter = null;
  }

  void _applyLiveVolume() {
    if (!_bgmInitialized || _currentTrack == null) return;
    final vol = _targetBgmVolume(_currentTrack!);
    try {
      FlameAudio.bgm.audioPlayer.setVolume(vol);
      _currentBgmVolume = vol;
    } catch (_) {}
  }
}
