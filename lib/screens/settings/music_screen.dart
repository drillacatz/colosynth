import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flame_audio/flame_audio.dart';

import 'package:colosynth/game_settings.dart';
import 'package:colosynth/providers/save_provider.dart';
import 'package:colosynth/services/audio_service.dart';
import 'package:colosynth/services/audio_repository.dart';
import 'package:colosynth/screens/theme/background.dart';

class MusicScreen extends ConsumerStatefulWidget {
  const MusicScreen({super.key});

  @override
  ConsumerState<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends ConsumerState<MusicScreen> {
  LobbyBgmType? _previewingLobbyType;

  static const _kInk = Color(0xFF1A1A1A);

  @override
  void dispose() {
    _stopPreviewAndResume();
    super.dispose();
  }

  void _stopPreviewAndResume() {
    if (_previewingLobbyType != null) {
      AudioService.instance.stopPreview(resumeMain: true);
      _previewingLobbyType = null;
    }
  }

  Future<void> _onLobbyTrackSelect(
      LobbyBgmType type, SettingsNotifier notifier) async {
    await notifier.setLobbyBgm(type);
    if (_previewingLobbyType != type) {
      setState(() => _previewingLobbyType = type);
      await AudioService.instance.previewLobbyTrack(type);
    }
  }

  Future<void> _onLobbyTrackPreview(LobbyBgmType type) async {
    final isToggleOff = _previewingLobbyType == type;
    setState(() => _previewingLobbyType = isToggleOff ? null : type);
    await AudioService.instance.previewLobbyTrack(type);
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    settingsAsync.whenData((s) {
      AudioService.instance.updatePreviewVolume(s.bgmVolume / 100.0);
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _kInk, size: 18),
          onPressed: () {
            _stopPreviewAndResume();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Music Settings',
          style: TextStyle(
            fontFamily: 'Bangers',
            fontSize: 22,
            letterSpacing: 4,
            color: _kInk,
          ),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: NotebookBackground()),
          settingsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
            data: (settings) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 7,
                      child: _StudioConsolePanel(
                        title: 'BGM Tracks',
                        child: IgnorePointer(
                          ignoring: !settings.bgmEnabled,
                          child: Opacity(
                            opacity: settings.bgmEnabled ? 1.0 : 0.38,
                            child: ScrollConfiguration(
                              behavior: const ScrollBehavior().copyWith(
                                scrollbars: false,
                                overscroll: false,
                              ),
                              child: ListView.builder(
                                physics: const ClampingScrollPhysics(),
                                itemCount: AudioRepository.musicLibrary.length,
                                itemBuilder: (context, index) {
                                  final track = AudioRepository.musicLibrary[index];
                                  final isSelected =
                                      (_previewingLobbyType ?? settings.selectedLobbyBgm) ==
                                          track.type;
                                  return _LobbyTrackTile(
                                    track: track,
                                    isSelected: isSelected,
                                    onSelect: () =>
                                        _onLobbyTrackSelect(track.type, notifier),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 5,
                      child: _StudioConsolePanel(
                        title: 'Volume',
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _VerticalVolumeControl(
                              label: 'SFX',
                              iconEnabled: Icons.volume_up_rounded,
                              iconDisabled: Icons.volume_off_rounded,
                              enabled: settings.sfxEnabled,
                              volume: settings.sfxVolume,
                              onToggle: notifier.setSfx,
                              onVolumeChanged: notifier.setSfxVolume,
                            ),
                            _VerticalVolumeControl(
                              label: 'Music',
                              iconEnabled: Icons.music_note_rounded,
                              iconDisabled: Icons.music_off_rounded,
                              enabled: settings.bgmEnabled,
                              volume: settings.bgmVolume,
                              onToggle: notifier.setBgm,
                              onVolumeChanged: notifier.setBgmVolume,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: settingsAsync.when(
        loading: () => null,
        error: (_, __) => null,
        data: (settings) => _BottomMusicPlayerBar(
          previewingType: _previewingLobbyType,
          selectedType: settings.selectedLobbyBgm,
          onTogglePreview: (type) => _onLobbyTrackPreview(type),
        ),
      ),
    );
  }
}


class _StudioConsolePanel extends StatelessWidget {
  const _StudioConsolePanel({required this.child, this.title});
  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1A1A1A),
          width: 2.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFD0C8C0),
            offset: Offset(4, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(
                fontFamily: 'Bangers',
                fontSize: 16,
                letterSpacing: 3,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(color: Color(0xFF1A1A1A), thickness: 1.5),
            const SizedBox(height: 12),
          ],
          Expanded(child: child),
        ],
      ),
    );
  }
}


class _LobbyTrackTile extends StatelessWidget {
  const _LobbyTrackTile({
    required this.track,
    required this.isSelected,
    required this.onSelect,
  });

  final MusicTrack track;
  final bool isSelected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF1A1A1A),
          width: 1.5,
        ),
        boxShadow: isSelected
            ? const [
                BoxShadow(
                  color: Color(0x29000000),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ]
            : [],
      ),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                track.title,
                style: TextStyle(
                  fontFamily: 'Bangers',
                  fontSize: 16,
                  letterSpacing: 2.5,
                  color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'DURATION: ${track.duration}',
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.white70 : const Color(0xFF888888),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



class _WaveformIndicator extends StatefulWidget {
  const _WaveformIndicator({required this.color});
  final Color color;

  @override
  State<_WaveformIndicator> createState() => _WaveformIndicatorState();
}

class _WaveformIndicatorState extends State<_WaveformIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(4, (i) {
            final phase = (i * 0.3 + _ctrl.value) % 1.0;
            final h = 6.0 + 12.0 * (0.5 + 0.5 * (phase * 2 - 1).abs());
            return Container(
              width: 3,
              height: h,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}


class _VerticalVolumeControl extends StatelessWidget {
  const _VerticalVolumeControl({
    required this.label,
    required this.iconEnabled,
    required this.iconDisabled,
    required this.enabled,
    required this.volume,
    required this.onToggle,
    required this.onVolumeChanged,
  });

  final String label;
  final IconData iconEnabled;
  final IconData iconDisabled;
  final bool enabled;
  final int volume;
  final ValueChanged<bool> onToggle;
  final ValueChanged<int> onVolumeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 12,
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => onToggle(!enabled),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: enabled ? const Color(0xFF1A1A1A) : Colors.white,
              borderRadius: BorderRadius.circular(21),
              border: Border.all(
                color: const Color(0xFF1A1A1A),
                width: 1.5,
              ),
              boxShadow: enabled
                  ? [
                      const BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              enabled ? iconEnabled : iconDisabled,
              color: enabled ? Colors.white : const Color(0xFF888888),
              size: 18,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: IgnorePointer(
            ignoring: !enabled,
            child: Opacity(
              opacity: enabled ? 1.0 : 0.38,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  thumbColor: const Color(0xFF1A1A1A),
                  activeTrackColor: const Color(0xFF1A1A1A),
                  inactiveTrackColor: const Color(0xFFE5E5E5),
                  overlayColor: const Color(0xFF1A1A1A).withValues(alpha: 0.1),
                  trackHeight: 4.0,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 7),
                ),
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Slider(
                    min: 0,
                    max: 100,
                    value: volume.toDouble(),
                    onChanged: (v) => onVolumeChanged(v.round()),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '$volume%',
          style: TextStyle(
            color: enabled ? const Color(0xFF1A1A1A) : const Color(0xFFAAAAAA),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}


class _BottomMusicPlayerBar extends StatefulWidget {
  const _BottomMusicPlayerBar({
    required this.previewingType,
    required this.selectedType,
    required this.onTogglePreview,
  });

  final LobbyBgmType? previewingType;
  final LobbyBgmType selectedType;
  final ValueChanged<LobbyBgmType> onTogglePreview;

  @override
  State<_BottomMusicPlayerBar> createState() => _BottomMusicPlayerBarState();
}

class _BottomMusicPlayerBarState extends State<_BottomMusicPlayerBar> {
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isDragging = false;
  double _dragValue = 0.0;

  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _stateSub;
  bool _isPlaying = true;

  AudioPlayer get _activePlayer {
    if (widget.previewingType != null) {
      return AudioService.instance.activePreviewPlayer ??
          FlameAudio.bgm.audioPlayer;
    }
    return FlameAudio.bgm.audioPlayer;
  }

  @override
  void initState() {
    super.initState();
    _initStreams();
  }

  @override
  void didUpdateWidget(_BottomMusicPlayerBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.previewingType != widget.previewingType ||
        oldWidget.selectedType != widget.selectedType) {
      _cancelStreams();
      _initStreams();
    }
  }

  void _cancelStreams() {
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
  }

  void _initStreams() {
    final player = _activePlayer;
    _isPlaying = player.state == PlayerState.playing;

    player.getCurrentPosition().then((p) {
      if (mounted && !_isDragging) {
        setState(() => _position = p ?? Duration.zero);
      }
    });
    player.getDuration().then((d) {
      if (mounted) {
        setState(() => _duration = d ?? Duration.zero);
      }
    });

    _posSub = player.onPositionChanged.listen((p) {
      if (mounted && !_isDragging) {
        setState(() => _position = p);
      }
    });
    _durSub = player.onDurationChanged.listen((d) {
      if (mounted) {
        setState(() => _duration = d);
      }
    });
    _stateSub = player.onPlayerStateChanged.listen((s) {
      if (mounted) {
        setState(() => _isPlaying = s == PlayerState.playing);
      }
    });
  }

  @override
  void dispose() {
    _cancelStreams();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Duration _parseTrackDuration(String s) {
    try {
      final parts = s.split(':');
      if (parts.length == 2) {
        return Duration(
          minutes: int.parse(parts[0]),
          seconds: int.parse(parts[1]),
        );
      }
    } catch (_) {}
    return Duration.zero;
  }

  Future<void> _togglePlayPause() async {
    final player = _activePlayer;
    if (_isPlaying) {
      await player.pause();
      if (mounted) setState(() => _isPlaying = false);
    } else {
      if (player.state == PlayerState.paused) {
        await player.resume();
        if (mounted) setState(() => _isPlaying = true);
      } else {
        final activeType = widget.previewingType ?? widget.selectedType;
        widget.onTogglePreview(activeType);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeType = widget.previewingType ?? widget.selectedType;
    final track = AudioRepository.musicLibrary.firstWhere(
      (t) => t.type == activeType,
      orElse: () => AudioRepository.musicLibrary.first,
    );

    final effectiveDuration = _duration > Duration.zero
        ? _duration
        : _parseTrackDuration(track.duration);
    final totalMs = effectiveDuration.inMilliseconds.toDouble();
    final currentMs = _position.inMilliseconds.toDouble();
    final sliderVal = _isDragging
        ? _dragValue
        : (totalMs > 0 ? (currentMs / totalMs).clamp(0.0, 1.0) : 0.0);

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1F1F1F),
        border: Border(
          top: BorderSide(color: Color(0xFF00E5FF), width: 2.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(16, 8, 16, 6 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          track.title,
                          style: const TextStyle(
                            fontFamily: 'Bangers',
                            fontSize: 15,
                            letterSpacing: 2.0,
                            color: Colors.white,
                          ),
                        ),
                        if (widget.previewingType != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
                                  width: 0.8),
                            ),
                            child: const Text(
                              'PREVIEW',
                              style: TextStyle(
                                color: Color(0xFF00E5FF),
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Bangers',
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_formatDuration(_isDragging ? Duration(milliseconds: (_dragValue * totalMs).round()) : _position)} / ${_formatDuration(effectiveDuration)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white60,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _WaveformIndicator(
                color: _isPlaying ? const Color(0xFF00E5FF) : Colors.white24,
              ),
              const SizedBox(width: 14),
              GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF),
                    borderRadius: BorderRadius.circular(19),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x40000000),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: const Color(0xFF1F1F1F),
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4.0,
              activeTrackColor: const Color(0xFF00E5FF),
              inactiveTrackColor: Colors.white24,
              thumbColor: const Color(0xFF00E5FF),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: sliderVal.clamp(0.0, 1.0),
              onChanged: (val) {
                setState(() {
                  _isDragging = true;
                  _dragValue = val;
                });
              },
              onChangeEnd: (val) async {
                final targetMs = (val * totalMs).round();
                await _activePlayer.seek(Duration(milliseconds: targetMs));
                setState(() {
                  _isDragging = false;
                  _position = Duration(milliseconds: targetMs);
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
