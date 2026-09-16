import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:colosynth/services/save_manager.dart';
import 'package:colosynth/game_settings.dart';
import 'package:colosynth/services/audio_service.dart';
import 'package:colosynth/providers/auth_provider.dart';

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, GameSettings>(SettingsNotifier.new);

class SettingsNotifier extends AsyncNotifier<GameSettings> {
  Timer? _sfxVolumeDebounce;
  Timer? _bgmVolumeDebounce;

  @override
  Future<GameSettings> build() async {
    ref.watch(authStateProvider);
    ref.onDispose(() {
      _sfxVolumeDebounce?.cancel();
      _bgmVolumeDebounce?.cancel();
    });
    final settings = await ref.watch(saveManagerProvider).loadSettings();
    _applySettings(settings);
    return settings;
  }

  void _applySettings(GameSettings s) {
    AudioService.instance.applySettings(s);
  }

  Future<void> toggleSfx() =>
      _update((s) => s.copyWith(sfxEnabled: !s.sfxEnabled));
  Future<void> toggleBgm() =>
      _update((s) => s.copyWith(bgmEnabled: !s.bgmEnabled));

  Future<void> setSfx(bool enabled) =>
      _update((s) => s.copyWith(sfxEnabled: enabled));
  Future<void> setBgm(bool enabled) =>
      _update((s) => s.copyWith(bgmEnabled: enabled));


  void setSfxVolume(int volume) {
    final current = state.value;
    if (current == null) return;
    final updated = current.copyWith(sfxVolume: volume.clamp(0, 100));
    state = AsyncData(updated);
    _applySettings(updated);
    _sfxVolumeDebounce?.cancel();
    _sfxVolumeDebounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(saveManagerProvider).saveSettings(updated);
    });
  }


  void setBgmVolume(int volume) {
    final current = state.value;
    if (current == null) return;
    final updated = current.copyWith(bgmVolume: volume.clamp(0, 100));
    state = AsyncData(updated);
    _applySettings(updated);
    _bgmVolumeDebounce?.cancel();
    _bgmVolumeDebounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(saveManagerProvider).saveSettings(updated);
    });
  }

  Future<void> setLobbyBgm(LobbyBgmType type) =>
      _update((s) => s.copyWith(selectedLobbyBgm: type));

  Future<void> _update(GameSettings Function(GameSettings) fn) async {
    final current = state.value;
    if (current == null) return;
    final updated = fn(current);
    state = AsyncData(updated);
    _applySettings(updated);
    await ref.read(saveManagerProvider).saveSettings(updated);
  }
}
