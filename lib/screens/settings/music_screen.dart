import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flame_audio/flame_audio.dart';

import 'package:colosynth/game_settings.dart';
import 'package:colosynth/providers/save_provider.dart';
import 'package:colosynth/services/audio_service.dart';
import 'package:colosynth/services/audio_repository.dart';
import 'package:colosynth/screens/theme/background.dart';
import 'package:colosynth/screens/theme/tokens.dart';

// ─────────────────────────────── Palette ─────────────────────────────────────

const _kInk = Color(0xFF1A1A1A);

const Map<LobbyBgmType, Color> _kTrackColors = {
  LobbyBgmType.default_: Color(0xFF00E5FF),
  LobbyBgmType.groovy: Color(0xFF7C4DFF),
  LobbyBgmType.ready: Color(0xFF00E676),
  LobbyBgmType.boss1: Color(0xFFFF5252),
  LobbyBgmType.boss2: Color(0xFFFF6D00),
  LobbyBgmType.boss3: Color(0xFFFFD600),
};

Color _trackColor(LobbyBgmType t) =>
    _kTrackColors[t] ?? const Color(0xFF00E5FF);

// ─────────────────────────────── MusicScreen ─────────────────────────────────

class MusicScreen extends ConsumerStatefulWidget {
  const MusicScreen({super.key});

  @override
  ConsumerState<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends ConsumerState<MusicScreen> {
  LobbyBgmType? _selectedTrackType;
  LobbyBgmType? _previewingLobbyType;

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

  Future<void> _onLobbyTrackSelect(LobbyBgmType type) async {
    setState(() => _selectedTrackType = type);
  }

  Future<void> _onLobbyTrackTogglePreview(LobbyBgmType type) async {
    if (_previewingLobbyType == type) {
      final player = AudioService.instance.activePreviewPlayer;
      if (player != null && player.state == PlayerState.playing) {
        await player.pause();
        if (mounted) setState(() {});
      } else if (player != null && player.state == PlayerState.paused) {
        await player.resume();
        if (mounted) setState(() {});
      } else {
        await AudioService.instance.previewLobbyTrack(type);
      }
    } else {
      setState(() {
        _selectedTrackType = type;
        _previewingLobbyType = type;
      });
      await AudioService.instance.previewLobbyTrack(type);
    }
  }

  Future<void> _setAsBgm(
      LobbyBgmType type, SettingsNotifier notifier) async {
    await notifier.setLobbyBgm(type);
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
            ComicButton.playButtonSfx();
            _stopPreviewAndResume();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'MUSIC & SOUND',
          style: TextStyle(
            fontFamily: 'Bangers',
            fontSize: 22,
            letterSpacing: 2.5,
            color: _kInk,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.5),
          child: Container(color: _kInk, height: 1.5),
        ),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const SizedBox.shrink(),
        data: (settings) {
          final activeTrackType =
              _selectedTrackType ?? settings.selectedLobbyBgm;
          return Stack(
            children: [
              const Positioned.fill(child: NotebookBackground()),
              // Main layout: Center Vinyl Player + Slingshot Volume Game
              Column(
                children: [
                  Expanded(
                    flex: 6,
                    child: _TurntableVinylPlayer(
                      activeTrackType: activeTrackType,
                      currentBgmType: settings.selectedLobbyBgm,
                      previewingType: _previewingLobbyType,
                      bgmEnabled: settings.bgmEnabled,
                      onTrackSelect: _onLobbyTrackSelect,
                      onTogglePreview: _onLobbyTrackTogglePreview,
                      onSetAsBgm: () => _setAsBgm(activeTrackType, notifier),
                    ),
                  ),
                  Container(height: 1.5, color: _kInk),
                  Expanded(
                    flex: 6,
                    child: _SlingshotVolumeGame(
                      bgmVolume: settings.bgmVolume,
                      sfxVolume: settings.sfxVolume,
                      bgmEnabled: settings.bgmEnabled,
                      sfxEnabled: settings.sfxEnabled,
                      notifier: notifier,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────── _TurntableVinylPlayer ───────────────────────────────
//
// Central vinyl player deck with standalone sliding vinyl discs (no cards).
// Swiping moves discs smoothly in and out of the turntable.
// Stylus tonearm is mounted at the TOP of the vinyl player, angling onto the record
// strictly when playing, and lifting up to a top rest post when paused.
// Interactive progress bar below the player shows elapsed/duration with scrub support.
//

class _TurntableVinylPlayer extends StatefulWidget {
  const _TurntableVinylPlayer({
    required this.activeTrackType,
    required this.currentBgmType,
    required this.previewingType,
    required this.bgmEnabled,
    required this.onTrackSelect,
    required this.onTogglePreview,
    required this.onSetAsBgm,
  });

  final LobbyBgmType activeTrackType;
  final LobbyBgmType currentBgmType;
  final LobbyBgmType? previewingType;
  final bool bgmEnabled;
  final ValueChanged<LobbyBgmType> onTrackSelect;
  final ValueChanged<LobbyBgmType> onTogglePreview;
  final VoidCallback onSetAsBgm;

  @override
  State<_TurntableVinylPlayer> createState() => _TurntableVinylPlayerState();
}

class _TurntableVinylPlayerState extends State<_TurntableVinylPlayer>
    with TickerProviderStateMixin {
  late double _scroll;
  double _scrollAngle = 0.0;
  double _playbackAngle = 0.0;

  late AnimationController _snapCtrl;
  Animation<double>? _snapAnim;
  double _snapFrom = 0.0;
  double _snapTo = 0.0;

  // Stylus controller: 0.0 = on record (playing), 1.0 = lifted/parked (paused)
  late AnimationController _stylusCtrl;

  late Ticker _spinTicker;
  Duration _prevElapsed = Duration.zero;

  // Audio streams & state
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  bool _isScrubbing = false;
  StreamSubscription? _posSub, _durSub, _stateSub;

  static const double _kRadPerSec = 33.3 / 60.0 * 2.0 * math.pi;

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
    final initialIdx = AudioRepository.musicLibrary.indexWhere(
        (t) => t.type == widget.activeTrackType);
    _scroll = (initialIdx >= 0 ? initialIdx : 0).toDouble();

    // Start with stylus parked (1.0 = paused/lifted)
    _stylusCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: 1.0,
    );

    _snapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )
      ..addListener(() {
        if (_snapAnim != null) {
          final oldScroll = _scroll;
          setState(() {
            _scroll = _snapAnim!.value;
            _scrollAngle += (_scroll - oldScroll) * 1.5;
          });
        }
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          final total = AudioRepository.musicLibrary.length;
          final normIdx = _scroll.round().clamp(0, total - 1);
          if (normIdx >= 0 && normIdx < total) {
            widget.onTrackSelect(AudioRepository.musicLibrary[normIdx].type);
          }
        }
      });

    _spinTicker = createTicker(_onSpinTick)..start();
    _initStreams();
  }

  void _initStreams() {
    final player = _activePlayer;
    _isPlaying = player.state == PlayerState.playing;
    _syncStylusToPlayState(_isPlaying, animate: false);

    player.getCurrentPosition().then((p) {
      if (mounted) setState(() => _position = p ?? Duration.zero);
    });
    player.getDuration().then((d) {
      if (mounted) setState(() => _duration = d ?? Duration.zero);
    });

    _posSub = player.onPositionChanged.listen((p) {
      if (mounted && !_isScrubbing) setState(() => _position = p);
    });
    _durSub = player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });

    // Strictly follow play/pause to render stylus properly
    _stateSub = player.onPlayerStateChanged.listen((s) {
      if (!mounted) return;
      final playing = s == PlayerState.playing;
      setState(() => _isPlaying = playing);
      _syncStylusToPlayState(playing, animate: true);
    });
  }

  void _syncStylusToPlayState(bool playing, {required bool animate}) {
    if (playing) {
      if (animate) {
        _stylusCtrl.animateTo(0.0,
            curve: Curves.easeOutBack,
            duration: const Duration(milliseconds: 340));
      } else {
        _stylusCtrl.value = 0.0;
      }
    } else {
      if (animate) {
        _stylusCtrl.animateTo(1.0,
            curve: Curves.easeOutCubic,
            duration: const Duration(milliseconds: 280));
      } else {
        _stylusCtrl.value = 1.0;
      }
    }
  }

  void _cancelStreams() {
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
  }

  void _onSpinTick(Duration elapsed) {
    final dt = (elapsed - _prevElapsed).inMicroseconds / 1e6;
    _prevElapsed = elapsed;

    if (_isPlaying) {
      setState(() {
        _playbackAngle += dt * _kRadPerSec;
      });
    }
  }

  @override
  void didUpdateWidget(covariant _TurntableVinylPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeTrackType != widget.activeTrackType) {
      final targetIdx = AudioRepository.musicLibrary
          .indexWhere((t) => t.type == widget.activeTrackType);
      if (targetIdx >= 0 && targetIdx != _scroll.round() && !_snapCtrl.isAnimating) {
        _animateTo(targetIdx.toDouble());
      }
    }
    if (oldWidget.previewingType != widget.previewingType) {
      _cancelStreams();
      _initStreams();
    }
  }

  @override
  void dispose() {
    _cancelStreams();
    _spinTicker.dispose();
    _stylusCtrl.dispose();
    _snapCtrl.dispose();
    super.dispose();
  }

  void _animateTo(double targetIndex) {
    final total = AudioRepository.musicLibrary.length;
    if (total == 0) return;

    _snapFrom = _scroll;
    _snapTo = targetIndex.clamp(0.0, (total - 1).toDouble());
    _snapAnim = Tween<double>(begin: _snapFrom, end: _snapTo).animate(
      CurvedAnimation(parent: _snapCtrl, curve: Curves.easeOutCubic),
    );
    _snapCtrl.forward(from: 0.0);
  }

  void _onPanStart(DragStartDetails _) {
    // Lift stylus while dragging between tracks
    _syncStylusToPlayState(false, animate: true);
  }

  void _onPanUpdate(DragUpdateDetails details, double stepX) {
    if (stepX <= 0) return;
    final total = AudioRepository.musicLibrary.length;
    final delta = details.delta.dx;
    final dScroll = delta / stepX;

    setState(() {
      _scroll = (_scroll - dScroll).clamp(0.0, (total - 1).toDouble());
      _scrollAngle += -delta * 0.024;
    });
  }

  void _onPanEnd(DragEndDetails details, double stepX) {
    final total = AudioRepository.musicLibrary.length;
    if (total == 0) return;

    final velocity = details.velocity.pixelsPerSecond.dx;
    double target = _scroll;
    if (velocity.abs() > 300) {
      target = velocity > 0 ? (_scroll - 0.4).floorToDouble() : (_scroll + 0.4).ceilToDouble();
    } else {
      target = _scroll.roundToDouble();
    }
    _animateTo(target.clamp(0.0, (total - 1).toDouble()));
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Duration _parseDuration(String s) {
    try {
      final parts = s.split(':');
      if (parts.length == 2) {
        return Duration(
            minutes: int.parse(parts[0]), seconds: int.parse(parts[1]));
      }
    } catch (_) {}
    return Duration.zero;
  }

  void _seekTo(double frac) {
    final tracks = AudioRepository.musicLibrary;
    final selectedIdx = _scroll.round().clamp(0, tracks.length - 1);
    final track = tracks[selectedIdx];
    final effectiveDur = _duration > Duration.zero
        ? _duration
        : _parseDuration(track.duration);
    final totalMs = effectiveDur.inMilliseconds;
    if (totalMs > 0) {
      final targetMs = (totalMs * frac).round().clamp(0, totalMs);
      setState(() => _position = Duration(milliseconds: targetMs));
      _activePlayer.seek(Duration(milliseconds: targetMs));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tracks = AudioRepository.musicLibrary;
    final total = tracks.length;
    final selectedIdx = _scroll.round().clamp(0, total - 1);
    final selectedTrack = tracks[selectedIdx];
    final isSelectedBgm = selectedTrack.type == widget.currentBgmType;
    final activeColor = _trackColor(selectedTrack.type);

    final effectiveDur = _duration > Duration.zero
        ? _duration
        : _parseDuration(selectedTrack.duration);
    final totalMs = effectiveDur.inMilliseconds.toDouble();
    final progress =
        totalMs > 0 ? (_position.inMilliseconds / totalMs).clamp(0.0, 1.0) : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final W = constraints.maxWidth;
        final H = constraints.maxHeight;

        // Player layout dimensions
        final platterDia = (math.min(W * 0.44, H * 0.48)).clamp(115.0, 160.0);
        final platterR = platterDia / 2;
        // Turntable center in player area
        final platterCenter = Offset(W / 2, H * 0.36);

        final discSize = platterDia * 0.94;
        final stepX = discSize * 1.15; // Horizontal slide distance between standalone discs

        // Stylus mounted at the TOP of the vinyl player
        // Pivot is mounted at top-right above the platter
        final pivotX = platterCenter.dx + platterR * 0.45;
        final pivotY = platterCenter.dy - platterR - 16.0;
        final armLen = platterR * 1.12;

        // Strictly follows _stylusCtrl:
        // 0.0 (Playing) -> +0.28 rad (needle pointing down-left onto vinyl grooves)
        // 1.0 (Paused)  -> -0.40 rad (needle lifted and parked outward to the right)
        final stylusAngle = 0.28 - _stylusCtrl.value * 0.68;

        // Build standalone vinyl disc entries
        final discEntries = <_StandaloneDiscEntry>[];
        for (int i = 0; i < total; i++) {
          final delta = i - _scroll;
          if (delta.abs() > 2.2) continue; // Out of view
          final dist = delta.abs();
          final scale = (1.0 - (dist * 0.20)).clamp(0.68, 1.0);
          final opacity = (1.0 - (dist * 0.45)).clamp(0.0, 1.0);
          final dx = platterCenter.dx + delta * stepX;

          discEntries.add(_StandaloneDiscEntry(
            index: i,
            dist: dist,
            dx: dx,
            scale: scale,
            opacity: opacity,
            track: tracks[i],
          ));
        }

        // Draw furthest discs first
        discEntries.sort((a, b) => b.dist.compareTo(a.dist));

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Turntable Deck Platter Base ───────────────────────────────
            Positioned(
              left: platterCenter.dx - platterR - 6,
              top: platterCenter.dy - platterR - 6,
              width: platterDia + 12,
              height: platterDia + 12,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF222226),
                  border: Border.all(color: _kInk, width: 2.2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x44000000),
                      blurRadius: 8,
                      offset: Offset(2, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: platterDia - 10,
                    height: platterDia - 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Standalone Vinyl Discs (Conveyor in/out of player) ─────────
            Positioned(
              left: 0,
              right: 0,
              top: platterCenter.dy - platterR - 10,
              height: platterDia + 20,
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: (d) => _onPanUpdate(d, stepX),
                onPanEnd: (d) => _onPanEnd(d, stepX),
                behavior: HitTestBehavior.opaque,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    for (final entry in discEntries)
                      Positioned(
                        left: entry.dx - (discSize * entry.scale) / 2,
                        top: (platterDia + 20 - discSize * entry.scale) / 2,
                        width: discSize * entry.scale,
                        height: discSize * entry.scale,
                        child: Opacity(
                          opacity: entry.opacity,
                          child: GestureDetector(
                            onTap: () {
                              ComicButton.playButtonSfx();
                              if (entry.index != selectedIdx) {
                                _animateTo(entry.index.toDouble());
                              } else {
                                widget.onTogglePreview(entry.track.type);
                              }
                            },
                            child: _StandaloneVinylDisc(
                              track: entry.track,
                              size: discSize * entry.scale,
                              isCentered: entry.index == selectedIdx,
                              isPreviewing: widget.previewingType == entry.track.type && _isPlaying,
                              angle: _scrollAngle +
                                  (entry.index == selectedIdx && _isPlaying
                                      ? _playbackAngle
                                      : 0.0),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Center Spindle Hole Pin ───────────────────────────────────
            Positioned(
              left: platterCenter.dx - 4,
              top: platterCenter.dy - 4,
              child: IgnorePointer(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFCCCCCC),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black54, blurRadius: 2),
                    ],
                  ),
                ),
              ),
            ),

            // ── Top Stylus Rest Post (Parking Bracket) ────────────────────
            Positioned(
              left: pivotX + 16,
              top: pivotY + 12,
              child: IgnorePointer(
                child: Container(
                  width: 7,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF444444),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: _kInk, width: 1.2),
                  ),
                ),
              ),
            ),

            // ── Player Stylus Tonearm (Mounted at the TOP of Vinyl Player) ─
            Positioned(
              left: pivotX - 11,
              top: pivotY,
              child: GestureDetector(
                onTap: () {
                  ComicButton.playButtonSfx();
                  widget.onTogglePreview(selectedTrack.type);
                },
                behavior: HitTestBehavior.opaque,
                child: AnimatedBuilder(
                  animation: _stylusCtrl,
                  builder: (_, __) {
                    return Transform.rotate(
                      angle: stylusAngle,
                      alignment: Alignment.topCenter,
                      child: CustomPaint(
                        size: Size(22.0, armLen + 20.0),
                        painter: _TopStylusPainter(armLen: armLen),
                      ),
                    );
                  },
                ),
              ),
            ),

            // ── Track Title Banner & Equalizer ────────────────────────────
            Positioned(
              left: 20,
              right: 20,
              top: platterCenter.dy + platterR + 8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      WaveformIndicator(
                        color: activeColor,
                        isPlaying: _isPlaying,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          selectedTrack.title.toUpperCase(),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Bangers',
                            fontSize: 15,
                            letterSpacing: 1.8,
                            color: _kInk,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      WaveformIndicator(
                        color: activeColor,
                        isPlaying: _isPlaying,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_fmt(_position)} / ${_fmt(effectiveDur)}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF777777),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrubbable Progress Bar below Vinyl Player ────────────────
            Positioned(
              left: 36,
              right: 36,
              top: platterCenter.dy + platterR + 48,
              child: GestureDetector(
                onHorizontalDragStart: (_) => setState(() => _isScrubbing = true),
                onHorizontalDragUpdate: (d) {
                  final barWidth = W - 72;
                  if (barWidth > 0) {
                    final frac = (d.localPosition.dx / barWidth).clamp(0.0, 1.0);
                    _seekTo(frac);
                  }
                },
                onHorizontalDragEnd: (_) => setState(() => _isScrubbing = false),
                onTapDown: (d) {
                  final barWidth = W - 72;
                  if (barWidth > 0) {
                    final frac = (d.localPosition.dx / barWidth).clamp(0.0, 1.0);
                    _seekTo(frac);
                  }
                },
                child: Container(
                  height: 14,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  color: Colors.transparent,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      // Progress track background
                      Container(
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: _kInk.withValues(alpha: 0.4), width: 1.0),
                        ),
                      ),
                      // Progress fill
                      FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          height: 5,
                          decoration: BoxDecoration(
                            color: activeColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      // Scrubber knob
                      Positioned(
                        left: ((W - 72) * progress - 5).clamp(0.0, W - 72 - 10),
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: activeColor,
                            border: Border.all(color: _kInk, width: 1.5),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 2),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Bottom strip: Dots + Set as BGM Button ────────────────────
            Positioned(
              left: 20,
              right: 20,
              bottom: 6,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dot indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(total, (i) {
                      final isSel = i == selectedIdx;
                      final color = _trackColor(tracks[i].type);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isSel ? 16 : 6,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isSel ? color : _kInk.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: math.min(W * 0.62, 220.0),
                    child: SetAsBgmButton(
                      isCurrentBgm: isSelectedBgm,
                      onPressed: isSelectedBgm
                          ? null
                          : () {
                              ComicButton.playButtonSfx();
                              widget.onSetAsBgm();
                            },
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StandaloneDiscEntry {
  final int index;
  final double dist;
  final double dx;
  final double scale;
  final double opacity;
  final MusicTrack track;

  _StandaloneDiscEntry({
    required this.index,
    required this.dist,
    required this.dx,
    required this.scale,
    required this.opacity,
    required this.track,
  });
}

// ──────────────────────── _StandaloneVinylDisc ───────────────────────────────

class _StandaloneVinylDisc extends StatelessWidget {
  const _StandaloneVinylDisc({
    required this.track,
    required this.size,
    required this.isCentered,
    required this.isPreviewing,
    required this.angle,
  });

  final MusicTrack track;
  final double size;
  final bool isCentered;
  final bool isPreviewing;
  final double angle;

  @override
  Widget build(BuildContext context) {
    final color = _trackColor(track.type);
    final labelSize = size * 0.32;

    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Rotating PNG Vinyl Record (clean standalone disc)
            Transform.rotate(
              angle: angle,
              child: Image.asset(
                'assets/images/vinyl_disc.png',
                width: size,
                height: size,
                fit: BoxFit.contain,
              ),
            ),

            // Center Track Label inside Disc Hole
            Container(
              width: labelSize,
              height: labelSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(color: _kInk, width: 1.4),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.40),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  isPreviewing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: labelSize * 0.65,
                  color: _kInk,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── _TopStylusPainter ───────────────────────────────
//
// Mounted at the TOP of the vinyl player.
// Needle points down onto the record grooves when playing, and lifts to the parking post when paused.
//

class _TopStylusPainter extends CustomPainter {
  const _TopStylusPainter({required this.armLen});
  final double armLen;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    // Counterweight cylinder at top pivot
    canvas.drawCircle(
      Offset(cx, 6),
      6.5,
      Paint()..color = const Color(0xFF2B2B2E),
    );
    canvas.drawCircle(
      Offset(cx, 6),
      6.5,
      Paint()
        ..color = _kInk
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Chrome tonearm stem pointing down
    canvas.drawLine(
      Offset(cx, 6),
      Offset(cx, armLen),
      Paint()
        ..color = const Color(0xFF9E9E9E)
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round,
    );

    // Headshell cartridge bend angled toward center spindle
    canvas.drawLine(
      Offset(cx, armLen),
      Offset(cx - 9, armLen + 14),
      Paint()
        ..color = const Color(0xFFDDDDDD)
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round,
    );

    // Needle stylus tip
    canvas.drawCircle(
      Offset(cx - 9, armLen + 14),
      3.2,
      Paint()..color = const Color(0xFFFF5252),
    );
  }

  @override
  bool shouldRepaint(_TopStylusPainter old) => armLen != old.armLen;
}

// ──────────────────────────── _SlingshotVolumeGame ───────────────────────────
//
// Optimized Slingshot Minigame:
//   • True drag-and-release dynamic trajectory following gesture continuously (no snap).
//   • Snappy bullet speed (~200ms flight duration).
//   • Aim switcher button reliably receives taps.
//   • Calibrated volume bar: Left edge is 0%, Right edge is 100%.
//   • Shooting the mute button on the left toggles MUTE / UNMUTE with comic burst.
//   • Black animated dotted trajectory arc with live target preview badge.
//

class _SlingshotVolumeGame extends StatefulWidget {
  const _SlingshotVolumeGame({
    required this.bgmVolume,
    required this.sfxVolume,
    required this.bgmEnabled,
    required this.sfxEnabled,
    required this.notifier,
  });

  final int bgmVolume;
  final int sfxVolume;
  final bool bgmEnabled;
  final bool sfxEnabled;
  final SettingsNotifier notifier;

  @override
  State<_SlingshotVolumeGame> createState() => _SlingshotVolumeGameState();
}

class _SlingshotVolumeGameState extends State<_SlingshotVolumeGame>
    with TickerProviderStateMixin {
  bool _targetIsBgm = true;
  bool _isDragging = false;
  Offset _dragOffset = Offset.zero;

  bool _ballInFlight = false;
  double _bgmBallFrac = -1.0;
  double _sfxBallFrac = -1.0;

  late AnimationController _flightCtrl;
  Offset _flightStart = Offset.zero;
  Offset _flightEnd = Offset.zero;
  double _flightArcHeight = 65.0;

  // Impact burst state & animation controller
  late AnimationController _impactCtrl;
  Offset _impactPos = Offset.zero;
  bool _impactTargetIsBgm = true;
  bool _impactIsMute = false;

  // Dotted trajectory animation ticker
  late AnimationController _trajectoryCtrl;

  // Cached layout coordinates
  Rect _bgmBarRect = Rect.zero;
  Rect _sfxBarRect = Rect.zero;
  Rect _bgmMuteRect = Rect.zero;
  Rect _sfxMuteRect = Rect.zero;
  Offset _slingshotAnchor = Offset.zero;

  static const double _maxPull = 100.0;

  @override
  void initState() {
    super.initState();
    _bgmBallFrac = widget.bgmVolume / 100.0;
    _sfxBallFrac = widget.sfxVolume / 100.0;

    // Accelerated bullet flight speed (~200ms)
    _flightCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )
      ..addListener(() => setState(() {}))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _onBallLanded();
      });

    _impactCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    )..addListener(() => setState(() {}));

    _trajectoryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void dispose() {
    _flightCtrl.dispose();
    _impactCtrl.dispose();
    _trajectoryCtrl.dispose();
    super.dispose();
  }

  void _onBallLanded() {
    final barRect = _targetIsBgm ? _bgmBarRect : _sfxBarRect;
    final muteRect = _targetIsBgm ? _bgmMuteRect : _sfxMuteRect;
    if (barRect.isEmpty) return;

    final isMuteHit = _flightEnd.dx <= (muteRect.right + 4);

    setState(() {
      _ballInFlight = false;
      _impactPos = _flightEnd;
      _impactTargetIsBgm = _targetIsBgm;
      _impactIsMute = isMuteHit;
    });

    _impactCtrl.forward(from: 0.0);
    ComicButton.playButtonSfx();

    if (isMuteHit) {
      // Hit mute button -> toggle mute
      if (_targetIsBgm) {
        widget.notifier.setBgm(!widget.bgmEnabled);
      } else {
        widget.notifier.setSfx(!widget.sfxEnabled);
      }
    } else {
      // Hit volume bar -> left is 0%, right is 100%
      final frac =
          ((_flightEnd.dx - barRect.left) / barRect.width).clamp(0.0, 1.0);
      final vol = (frac * 100).round();

      setState(() {
        if (_targetIsBgm) {
          _bgmBallFrac = frac;
        } else {
          _sfxBallFrac = frac;
        }
      });

      if (_targetIsBgm) {
        widget.notifier.setBgmVolume(vol);
      } else {
        widget.notifier.setSfxVolume(vol);
      }
    }
  }

  void _onDragStart(DragStartDetails _) {
    if (_ballInFlight) return;
    setState(() {
      _isDragging = true;
      _dragOffset = Offset.zero;
    });
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (!_isDragging) return;
    setState(() {
      _dragOffset = Offset(
        (_dragOffset.dx + d.delta.dx).clamp(-_maxPull, _maxPull),
        (_dragOffset.dy + d.delta.dy).clamp(0.0, _maxPull),
      );
    });
  }

  void _onDragEnd(DragEndDetails _) {
    if (!_isDragging || _dragOffset.dy < 10.0) {
      setState(() {
        _isDragging = false;
        _dragOffset = Offset.zero;
      });
      return;
    }
    setState(() => _isDragging = false);
    _launchBall();
  }

  // True dynamic drag vector calculation (no snapping to discrete points)
  Offset _computeLandingPoint() {
    final barRect = _targetIsBgm ? _bgmBarRect : _sfxBarRect;
    final muteRect = _targetIsBgm ? _bgmMuteRect : _sfxMuteRect;
    if (barRect.isEmpty) return Offset.zero;

    final minX = muteRect.center.dx;
    final maxX = barRect.right;
    final centerTargetX = (minX + maxX) / 2;
    final span = maxX - minX;

    // Pull left -> shoots right; pull right -> shoots left
    // Fluid continuous linear projection directly from dragOffset.dx (no snap)
    final aimX = centerTargetX - (_dragOffset.dx / _maxPull) * (span * 0.65);
    final landingX = aimX.clamp(minX, maxX);

    return Offset(landingX, barRect.center.dy);
  }

  double _computeDynamicArcHeight() {
    // Dynamic trajectory arc height organically scales with pull depth
    return (35.0 + (_dragOffset.dy / _maxPull) * 55.0).clamp(35.0, 90.0);
  }

  void _launchBall() {
    if (_slingshotAnchor == Offset.zero) return;
    final landing = _computeLandingPoint();
    if (landing == Offset.zero) return;

    _flightStart = _slingshotAnchor;
    _flightEnd = landing;
    _flightArcHeight = _computeDynamicArcHeight();

    setState(() {
      _dragOffset = Offset.zero;
      _ballInFlight = true;
      if (_targetIsBgm) {
        _bgmBallFrac = -1.0;
      } else {
        _sfxBallFrac = -1.0;
      }
    });

    _flightCtrl.forward(from: 0);
  }

  Offset _ballPos(double t, [Offset? start, Offset? end, double? arcH]) {
    final p0 = start ?? _flightStart;
    final p2 = end ?? _flightEnd;
    final arc = arcH ?? _flightArcHeight;
    final p1 = Offset(
      (p0.dx + p2.dx) / 2,
      math.min(p0.dy, p2.dy) - arc,
    );
    final u = 1 - t;
    return Offset(
      u * u * p0.dx + 2 * u * t * p1.dx + t * t * p2.dx,
      u * u * p0.dy + 2 * u * t * p1.dy + t * t * p2.dy,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final W = constraints.maxWidth;
      final H = constraints.maxHeight;

      const double padH = 18.0;
      const double muteBtnW = 30.0;
      const double gapBeforeBar = 34.0; // 6 (gap) + 20 (label) + 8 (spacing)
      const double barH = 14.0;
      const double bar1RowTop = 18.0;
      const double bar2RowTop = 80.0;
      const double barTrackOffset = 16.0;

      final barLeft = padH + muteBtnW + gapBeforeBar;
      final barWidth = W - barLeft - padH;

      _bgmMuteRect = const Rect.fromLTWH(padH, bar1RowTop + barTrackOffset - 7, muteBtnW, muteBtnW);
      _sfxMuteRect = const Rect.fromLTWH(padH, bar2RowTop + barTrackOffset - 7, muteBtnW, muteBtnW);
      _bgmBarRect = Rect.fromLTWH(barLeft, bar1RowTop + barTrackOffset, barWidth, barH);
      _sfxBarRect = Rect.fromLTWH(barLeft, bar2RowTop + barTrackOffset, barWidth, barH);

      // Slingshot shifted UP by 80px
      _slingshotAnchor = Offset(W / 2, H - 96);

      final ballColor = _targetIsBgm
          ? const Color(0xFF00E5FF)
          : const Color(0xFFFFD600);
      final flightBallPos =
          _ballInFlight ? _ballPos(_flightCtrl.value) : null;

      final impactBurstProgress =
          _impactCtrl.isAnimating ? _impactCtrl.value : 0.0;
      final bgmBounce = (_impactCtrl.isAnimating && _impactTargetIsBgm)
          ? _impactCtrl.value
          : 0.0;
      final sfxBounce = (_impactCtrl.isAnimating && !_impactTargetIsBgm)
          ? _impactCtrl.value
          : 0.0;

      // Trajectory prediction calculation dynamically following gesture move
      Offset? predictedLanding;
      String? predictedBadgeText;
      double dynamicArc = 60.0;

      if (_isDragging && _dragOffset.dy >= 8.0) {
        predictedLanding = _computeLandingPoint();
        dynamicArc = _computeDynamicArcHeight();

        if (predictedLanding != Offset.zero) {
          final muteRect = _targetIsBgm ? _bgmMuteRect : _sfxMuteRect;
          if (predictedLanding.dx <= muteRect.right + 4) {
            final isCurrentlyMuted = _targetIsBgm ? !widget.bgmEnabled : !widget.sfxEnabled;
            predictedBadgeText = isCurrentlyMuted ? 'UNMUTE' : 'MUTE';
          } else {
            final frac = ((predictedLanding.dx - barLeft) / barWidth).clamp(0.0, 1.0);
            predictedBadgeText = '${(frac * 100).round()}%';
          }
        }
      }

      return Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // ── BGM volume bar ──────────────────────────────────────────────
          Positioned(
            left: padH,
            right: padH,
            top: bar1RowTop,
            child: _HorizontalVolumeBar(
              label: 'BGM',
              icon: Icons.music_note_rounded,
              volume: widget.bgmVolume,
              enabled: widget.bgmEnabled,
              isTarget: _targetIsBgm,
              ballFrac: _bgmBallFrac,
              color: const Color(0xFF00E5FF),
              barHeight: barH,
              bounceProgress: bgmBounce,
              onToggle: widget.notifier.setBgm,
            ),
          ),

          // ── SFX volume bar ──────────────────────────────────────────────
          Positioned(
            left: padH,
            right: padH,
            top: bar2RowTop,
            child: _HorizontalVolumeBar(
              label: 'SFX',
              icon: Icons.volume_up_rounded,
              volume: widget.sfxVolume,
              enabled: widget.sfxEnabled,
              isTarget: !_targetIsBgm,
              ballFrac: _sfxBallFrac,
              color: const Color(0xFFFFD600),
              barHeight: barH,
              bounceProgress: sfxBounce,
              onToggle: widget.notifier.setSfx,
            ),
          ),

          // ── Black Animated Dotted Line Trajectory & Preview Badge ───────
          if (_isDragging && predictedLanding != null)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _TrajectoryPainter(
                    start: _slingshotAnchor + _dragOffset,
                    end: predictedLanding,
                    arcHeight: dynamicArc,
                    badgeText: predictedBadgeText ?? '',
                    targetColor: ballColor,
                    phase: _trajectoryCtrl.value,
                  ),
                ),
              ),
            ),

          // ── Slingshot drawing (40% enlarged) + ball in flight ────────────
          Positioned.fill(
            child: CustomPaint(
              painter: _SlingshotPainter(
                anchor: _slingshotAnchor,
                dragOffset: _isDragging ? _dragOffset : null,
                ballInFlight: flightBallPos,
                ballColor: ballColor,
                targetIsBgm: _targetIsBgm,
              ),
            ),
          ),

          // ── Comic snap/hit impact burst effect ───────────────────────────
          if (_impactCtrl.isAnimating)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _ImpactBurstPainter(
                    position: _impactPos,
                    progress: impactBurstProgress,
                    color: _impactTargetIsBgm
                        ? const Color(0xFF00E5FF)
                        : const Color(0xFFFFD600),
                    isMute: _impactIsMute,
                  ),
                ),
              ),
            ),

          // ── Drag gesture zone around elevated slingshot ─────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: H * 0.52,
            child: GestureDetector(
              onPanStart: _onDragStart,
              onPanUpdate: _onDragUpdate,
              onPanEnd: _onDragEnd,
              behavior: HitTestBehavior.translucent,
            ),
          ),

          // ── Aim switcher button placed BESIDE the slingshot ──────────────
          // Placed AFTER the drag zone in the Stack so taps are reliably registered!
          Positioned(
            left: _slingshotAnchor.dx + 44,
            top: _slingshotAnchor.dy - 46,
            child: GestureDetector(
              onTap: () {
                ComicButton.playButtonSfx();
                setState(() => _targetIsBgm = !_targetIsBgm);
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _kInk,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ballColor, width: 2.0),
                  boxShadow: [
                    BoxShadow(
                      color: ballColor.withValues(alpha: 0.50),
                      blurRadius: 8,
                      offset: const Offset(1, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _targetIsBgm
                              ? Icons.music_note_rounded
                              : Icons.volume_up_rounded,
                          color: ballColor,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _targetIsBgm ? 'BGM' : 'SFX',
                          style: TextStyle(
                            fontFamily: 'Bangers',
                            fontSize: 14,
                            letterSpacing: 1.4,
                            color: ballColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'TAP TO SWITCH',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Hint label ──────────────────────────────────────────────────
          if (!_isDragging && !_ballInFlight)
            Positioned(
              bottom: 14,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'PULL ↓ & RELEASE TO SHOOT',
                  style: TextStyle(
                    fontSize: 9,
                    color: _kInk.withValues(alpha: 0.35),
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}

// ─────────────────────────── _TrajectoryPainter ──────────────────────────────
//
// Black animating dotted trajectory curve with live prediction badge.
// Follows gesture move fluidly in real-time without artificial snapping.
//

class _TrajectoryPainter extends CustomPainter {
  const _TrajectoryPainter({
    required this.start,
    required this.end,
    required this.arcHeight,
    required this.badgeText,
    required this.targetColor,
    required this.phase,
  });

  final Offset start;
  final Offset end;
  final double arcHeight;
  final String badgeText;
  final Color targetColor;
  final double phase; // 0.0 to 1.0

  @override
  void paint(Canvas canvas, Size size) {
    final p0 = start;
    final p2 = end;
    final p1 = Offset(
      (p0.dx + p2.dx) / 2,
      math.min(p0.dy, p2.dy) - arcHeight,
    );

    // Black comic dotted line along quadratic bezier
    const dotCount = 18;
    final dotPaint = Paint()
      ..color = _kInk
      ..style = PaintingStyle.fill;

    for (int i = 0; i < dotCount; i++) {
      // Marching ants animation flow towards target
      final t = ((i + phase) / dotCount) % 1.0;
      final u = 1 - t;
      final pt = Offset(
        u * u * p0.dx + 2 * u * t * p1.dx + t * t * p2.dx,
        u * u * p0.dy + 2 * u * t * p1.dy + t * t * p2.dy,
      );

      final r = 1.8 + t * 1.6;
      canvas.drawCircle(pt, r, dotPaint);
    }

    // Target crosshair at landing point
    final crosshairPaint = Paint()
      ..color = _kInk
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawCircle(p2, 6, crosshairPaint);
    canvas.drawLine(p2 - const Offset(9, 0), p2 + const Offset(9, 0), crosshairPaint);
    canvas.drawLine(p2 - const Offset(0, 9), p2 + const Offset(0, 9), crosshairPaint);

    // Live comic prediction badge above landing point
    if (badgeText.isNotEmpty) {
      final badgeCenter = p2 - const Offset(0, 24);
      final textSpan = TextSpan(
        text: badgeText,
        style: TextStyle(
          fontFamily: 'Bangers',
          fontSize: 12,
          letterSpacing: 1.2,
          color: targetColor,
        ),
      );
      final tp = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final badgeRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: badgeCenter,
          width: tp.width + 12,
          height: tp.height + 6,
        ),
        const Radius.circular(5),
      );

      // Badge background
      canvas.drawRRect(badgeRect, Paint()..color = _kInk);
      canvas.drawRRect(
        badgeRect,
        Paint()
          ..color = targetColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );

      tp.paint(canvas, badgeCenter - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_TrajectoryPainter old) =>
      start != old.start ||
      end != old.end ||
      arcHeight != old.arcHeight ||
      badgeText != old.badgeText ||
      phase != old.phase ||
      targetColor != old.targetColor;
}

// ─────────────────────────── _HorizontalVolumeBar ────────────────────────────

class _HorizontalVolumeBar extends StatelessWidget {
  const _HorizontalVolumeBar({
    required this.label,
    required this.icon,
    required this.volume,
    required this.enabled,
    required this.isTarget,
    required this.ballFrac,
    required this.color,
    required this.barHeight,
    required this.onToggle,
    this.bounceProgress = 0.0,
  });

  final String label;
  final IconData icon;
  final int volume;
  final bool enabled;
  final bool isTarget;
  final double ballFrac;
  final Color color;
  final double barHeight;
  final ValueChanged<bool> onToggle;
  final double bounceProgress;

  @override
  Widget build(BuildContext context) {
    final bounceScale = bounceProgress > 0.0
        ? (1.0 + 0.08 * math.sin(bounceProgress * math.pi))
        : 1.0;

    return Transform.scale(
      scale: bounceScale,
      alignment: Alignment.center,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Toggle icon button (30x30)
          GestureDetector(
            onTap: () => onToggle(!enabled),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: enabled ? _kInk : Colors.white,
                border: Border.all(color: _kInk, width: 1.5),
              ),
              child: Icon(
                icon,
                color: enabled ? Colors.white : const Color(0xFFAAAAAA),
                size: 14,
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Label (20px)
          SizedBox(
            width: 20,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: isTarget ? color : const Color(0xFF999999),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Bar + value (Expanded)
          Expanded(
            child: IgnorePointer(
              ignoring: !enabled,
              child: Opacity(
                opacity: enabled ? 1.0 : 0.40,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$volume%',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: enabled ? _kInk : const Color(0xFFAAAAAA),
                      ),
                    ),
                    const SizedBox(height: 3),
                    LayoutBuilder(
                      builder: (_, bc) {
                        final ballSize = barHeight * 2 + 4;
                        final ballR = ballSize / 2;
                        final bx = ballFrac >= 0 ? ballFrac * bc.maxWidth : 0.0;
                        final maxBallLeft =
                            (bc.maxWidth - ballSize).clamp(0.0, double.infinity);
                        final ballLeft = (bx - ballR).clamp(0.0, maxBallLeft);

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Track background
                            Container(
                              height: barHeight,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5E5E5),
                                borderRadius:
                                    BorderRadius.circular(barHeight / 2),
                                border: isTarget
                                    ? Border.all(color: color, width: 1.6)
                                    : Border.all(
                                        color: const Color(0xFFCCCCCC),
                                        width: 1.0),
                                boxShadow: isTarget
                                    ? [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.35),
                                          blurRadius: 6,
                                        )
                                      ]
                                    : null,
                              ),
                              child: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(barHeight / 2),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: volume / 100.0,
                                  child: Container(
                                    color: enabled
                                        ? color
                                        : const Color(0xFFCCCCCC),
                                  ),
                                ),
                              ),
                            ),
                            // Ball resting on bar
                            if (ballFrac >= 0)
                              Positioned(
                                left: ballLeft,
                                top: -(barHeight * 0.5 + 2),
                                child: Container(
                                  width: ballSize,
                                  height: ballSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: color,
                                    border:
                                        Border.all(color: _kInk, width: 1.5),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x44000000),
                                        blurRadius: 4,
                                        offset: Offset(1, 1),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────── _SlingshotPainter ──────────────────────────────

class _SlingshotPainter extends CustomPainter {
  const _SlingshotPainter({
    required this.anchor,
    required this.dragOffset,
    required this.ballInFlight,
    required this.ballColor,
    required this.targetIsBgm,
  });

  final Offset anchor;
  final Offset? dragOffset;
  final Offset? ballInFlight;
  final Color ballColor;
  final bool targetIsBgm;

  @override
  void paint(Canvas canvas, Size size) {
    // 40% enlarged geometry
    final leftFork = anchor + const Offset(-34, -76);
    final rightFork = anchor + const Offset(34, -76);
    final stem = anchor + const Offset(0, -50);

    final wood = Paint()
      ..color = const Color(0xFF8B5E3C)
      ..strokeWidth = 10.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Y-shape stem + forks
    canvas.drawLine(anchor, stem, wood);
    canvas.drawLine(stem, leftFork, wood);
    canvas.drawLine(stem, rightFork, wood);

    // Fork tip knobs
    canvas.drawCircle(leftFork, 7, Paint()..color = const Color(0xFF5C3A1E));
    canvas.drawCircle(rightFork, 7, Paint()..color = const Color(0xFF5C3A1E));

    // Base platform
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: anchor + const Offset(0, 11), width: 56, height: 11),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFF6B4423),
    );

    final bandPaint = Paint()
      ..color = const Color(0xFFCC88EE)
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const ballRadius = 15.5;

    if (dragOffset != null && dragOffset != Offset.zero) {
      final dragPt = anchor + dragOffset!;

      // Rubber bands
      canvas.drawLine(leftFork, dragPt, bandPaint);
      canvas.drawLine(rightFork, dragPt, bandPaint);

      // Ball in cradle
      _drawBullet(canvas, dragPt, ballRadius, ballColor);
    } else {
      // Slack rubber bands
      final slackL = leftFork + const Offset(0, 11);
      final slackR = rightFork + const Offset(0, 11);
      canvas.drawLine(leftFork, slackL, bandPaint);
      canvas.drawLine(rightFork, slackR, bandPaint);

      // Idle loaded bullet resting in sling
      final restPt = stem + const Offset(0, -18);
      _drawBullet(canvas, restPt, ballRadius * 0.9, ballColor);
    }

    // Flying ball
    if (ballInFlight != null) {
      _drawBullet(canvas, ballInFlight!, ballRadius, ballColor);
    }
  }

  void _drawBullet(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawCircle(center, radius, Paint()..color = color);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = _kInk
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
    // Shine reflection
    canvas.drawCircle(
      center + const Offset(-4, -4),
      radius * 0.30,
      Paint()..color = Colors.white.withValues(alpha: 0.45),
    );
  }

  @override
  bool shouldRepaint(_SlingshotPainter old) =>
      anchor != old.anchor ||
      dragOffset != old.dragOffset ||
      ballInFlight != old.ballInFlight ||
      ballColor != old.ballColor ||
      targetIsBgm != old.targetIsBgm;
}

// ─────────────────────────── _ImpactBurstPainter ─────────────────────────────

class _ImpactBurstPainter extends CustomPainter {
  const _ImpactBurstPainter({
    required this.position,
    required this.progress,
    required this.color,
    this.isMute = false,
  });

  final Offset position;
  final double progress;
  final Color color;
  final bool isMute;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0 || progress >= 1.0 || position == Offset.zero) return;

    final alpha = ((1.0 - progress) * 255).clamp(0, 255).toInt();
    final burstRadius = 10.0 + progress * 28.0;

    // Expanding shockwave ring
    final ringPaint = Paint()
      ..color = color.withAlpha(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (3.2 * (1.0 - progress)).clamp(1.0, 3.2);
    canvas.drawCircle(position, burstRadius, ringPaint);

    // Comic starburst rays
    final rayPaint = Paint()
      ..color = _kInk.withAlpha(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    const numRays = 8;
    for (int i = 0; i < numRays; i++) {
      final angle = (i * 2 * math.pi / numRays) + progress * 0.35;
      final inner = position +
          Offset(math.cos(angle) * (burstRadius * 0.45),
              math.sin(angle) * (burstRadius * 0.45));
      final outer = position +
          Offset(math.cos(angle) * (burstRadius * 1.35),
              math.sin(angle) * (burstRadius * 1.35));
      canvas.drawLine(inner, outer, rayPaint);
    }

    // Comic spark pop dots
    final sparkPaint = Paint()..color = color.withAlpha(alpha);
    for (int i = 0; i < 6; i++) {
      final sparkAngle = (i * 2 * math.pi / 6) + 0.25;
      final sparkDist = burstRadius * 0.95;
      final sparkPos = position +
          Offset(math.cos(sparkAngle) * sparkDist,
              math.sin(sparkAngle) * sparkDist);
      canvas.drawCircle(sparkPos, (3.0 * (1.0 - progress)).clamp(0.5, 3.0), sparkPaint);
    }

    // Comic text indicator on mute
    if (isMute) {
      final textSpan = TextSpan(
        text: 'MUTE',
        style: TextStyle(
          fontFamily: 'Bangers',
          fontSize: 16,
          letterSpacing: 1.5,
          color: Colors.redAccent.withAlpha(alpha),
        ),
      );
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, position - Offset(tp.width / 2, burstRadius + 14));
    }
  }

  @override
  bool shouldRepaint(_ImpactBurstPainter old) =>
      progress != old.progress ||
      position != old.position ||
      color != old.color ||
      isMute != old.isMute;
}

// ─────────────────────────── WaveformIndicator ──────────────────────────────

class WaveformIndicator extends StatefulWidget {
  const WaveformIndicator({
    super.key,
    required this.color,
    required this.isPlaying,
  });

  final Color color;
  final bool isPlaying;

  @override
  State<WaveformIndicator> createState() => _WaveformIndicatorState();
}

class _WaveformIndicatorState extends State<WaveformIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    if (widget.isPlaying) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(WaveformIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _ctrl.repeat(reverse: true);
      } else {
        _ctrl.stop();
      }
    }
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
            final double h;
            if (widget.isPlaying) {
              final phase = (i * 0.3 + _ctrl.value) % 1.0;
              h = 5.0 + 10.0 * (0.5 + 0.5 * (phase * 2 - 1).abs());
            } else {
              const restingHeights = [5.0, 9.0, 7.0, 5.0];
              h = restingHeights[i];
            }
            return Container(
              width: 2.5,
              height: h,
              margin: const EdgeInsets.symmetric(horizontal: 1.0),
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

// ─────────────────────────── SetAsBgmButton ──────────────────────────────────

class SetAsBgmButton extends StatelessWidget {
  const SetAsBgmButton({
    super.key,
    required this.isCurrentBgm,
    required this.onPressed,
  });

  final bool isCurrentBgm;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (isCurrentBgm) {
      return Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF00E676).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF00E676), width: 1.5),
        ),
        child: const Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded,
                    color: Color(0xFF00E676), size: 16),
                SizedBox(width: 5),
                Text(
                  'CURRENT BGM',
                  style: TextStyle(
                    fontFamily: 'Bangers',
                    fontSize: 13,
                    letterSpacing: 1.5,
                    color: Color(0xFF00C853),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFF00E5FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kInk, width: 1.8),
        boxShadow: const [BoxShadow(color: _kInk, offset: Offset(2, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.playlist_add_check_rounded,
                        color: _kInk, size: 17),
                    SizedBox(width: 5),
                    Text(
                      'SET AS BGM',
                      style: TextStyle(
                        fontFamily: 'Bangers',
                        fontSize: 13,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                        color: _kInk,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────── LobbyTrackTile ────────────────────────────────

class LobbyTrackTile extends StatelessWidget {
  const LobbyTrackTile({
    super.key,
    required this.track,
    required this.isSelected,
    required this.isCurrentBgm,
    required this.onSelect,
  });

  final MusicTrack track;
  final bool isSelected;
  final bool isCurrentBgm;
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Bangers',
                        fontSize: 16,
                        letterSpacing: 2.0,
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
              if (isCurrentBgm) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00E676),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Color(0xFF00E676),
                    size: 15,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
