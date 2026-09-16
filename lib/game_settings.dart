enum BgmTrack { splash, title, home, ready, battle }
enum LobbyBgmType { default_, groovy, ready, boss1, boss2, boss3 }

enum SfxEvent {
  button,
  navigate,
  slash,
  hit,
  playerHurt,
  parry,
  block,
  dodge,
  activeskillCharged,
  victory,
  defeat,
  reward,
  combo,
}


class GameSettings {
  final bool sfxEnabled;
  final bool bgmEnabled;
  final int sfxVolume;
  final int bgmVolume;
  final LobbyBgmType selectedLobbyBgm;
  final bool showFps;

  const GameSettings({
    this.sfxEnabled = true,
    this.bgmEnabled = true,
    this.sfxVolume = 80,
    this.bgmVolume = 80,
    this.selectedLobbyBgm = LobbyBgmType.default_,
    this.showFps = false,
  });

  static const defaults = GameSettings();

  GameSettings copyWith({
    bool? sfxEnabled,
    bool? bgmEnabled,
    int? sfxVolume,
    int? bgmVolume,
    LobbyBgmType? selectedLobbyBgm,
    bool? showFps,
  }) {
    return GameSettings(
      sfxEnabled: sfxEnabled ?? this.sfxEnabled,
      bgmEnabled: bgmEnabled ?? this.bgmEnabled,
      sfxVolume: sfxVolume ?? this.sfxVolume,
      bgmVolume: bgmVolume ?? this.bgmVolume,
      selectedLobbyBgm: selectedLobbyBgm ?? this.selectedLobbyBgm,
      showFps: showFps ?? this.showFps,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameSettings &&
        other.sfxEnabled == sfxEnabled &&
        other.bgmEnabled == bgmEnabled &&
        other.sfxVolume == sfxVolume &&
        other.bgmVolume == bgmVolume &&
        other.selectedLobbyBgm == selectedLobbyBgm &&
        other.showFps == showFps;
  }

  @override
  int get hashCode => Object.hash(
        sfxEnabled,
        bgmEnabled,
        sfxVolume,
        bgmVolume,
        selectedLobbyBgm,
        showFps,
      );

  @override
  String toString() =>
      'GameSettings(sfx: $sfxEnabled/$sfxVolume%, bgm: $bgmEnabled/$bgmVolume%, lobbyBgm: $selectedLobbyBgm, showFps: $showFps)';
}

