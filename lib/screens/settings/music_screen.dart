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
              // Main layout: 3D vinyl disc carousel + Slingshot volume game
              Column(
                children: [
                  Expanded(
                    flex: 6,
                    child: _SurroundVinylCarousel(
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

// ─────────────────────── _SurroundVinylCarousel ──────────────────────────────
//
// 3D amphitheater carousel presenting comic album sleeve cards with vinyl discs.
// Discs rotate in real-time when the user scrolls/swipes horizontally, and also
// spin smoothly while audio preview/playback is active.
//

class _SurroundVinylCarousel extends StatefulWidget {
  const _SurroundVinylCarousel({
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
  State<_SurroundVinylCarousel> createState() => _SurroundVinylCarouselState();
}

class _SurroundVinylCarouselState extends State<_SurroundVinylCarousel>
    with TickerProviderStateMixin {
  late double _scroll;
  double _scrollAngle = 0.0; // Dynamic turntable rotation on swipe/drag
  double _playbackAngle = 0.0; // Continuous rotation during playback

  late AnimationController _snapCtrl;
  Animation<double>? _snapAnim;
  double _snapFrom = 0.0;
  double _snapTo = 0.0;

  late Ticker _spinTicker;
  Duration _prevElapsed = Duration.zero;

  static const double _kRadPerSec = 33.3 / 60.0 * 2.0 * math.pi;

  @override
  void initState() {
    super.initState();
    final initialIdx = AudioRepository.musicLibrary.indexWhere(
        (t) => t.type == widget.activeTrackType);
    _scroll = (initialIdx >= 0 ? initialIdx : 0).toDouble();

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
  }

  void _onSpinTick(Duration elapsed) {
    final dt = (elapsed - _prevElapsed).inMicroseconds / 1e6;
    _prevElapsed = elapsed;

    final isPreviewing = widget.previewingType != null;
    final player = AudioService.instance.activePreviewPlayer;
    final isPlaying = isPreviewing &&
        (player == null || player.state == PlayerState.playing);

    if (isPlaying) {
      setState(() {
        _playbackAngle += dt * _kRadPerSec;
      });
    }
  }

  @override
  void didUpdateWidget(covariant _SurroundVinylCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeTrackType != widget.activeTrackType) {
      final targetIdx = AudioRepository.musicLibrary
          .indexWhere((t) => t.type == widget.activeTrackType);
      if (targetIdx >= 0 && targetIdx != _scroll.round() && !_snapCtrl.isAnimating) {
        _animateTo(targetIdx.toDouble());
      }
    }
  }

  @override
  void dispose() {
    _spinTicker.dispose();
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

  void _onPanUpdate(DragUpdateDetails details, double stepX) {
    if (stepX <= 0) return;
    final total = AudioRepository.musicLibrary.length;
    final delta = details.delta.dx;
    final dScroll = delta / stepX;

    setState(() {
      _scroll = (_scroll - dScroll).clamp(0.0, (total - 1).toDouble());
      // Dynamic vinyl rotation in response to horizontal finger drag
      _scrollAngle += -delta * 0.024;
    });
  }

  void _onPanEnd(DragEndDetails details, double stepX) {
    final total = AudioRepository.musicLibrary.length;
    if (total == 0) return;

    final velocity = details.velocity.pixelsPerSecond.dx;
    double target = _scroll;
    if (velocity.abs() > 320) {
      target = velocity > 0 ? (_scroll - 0.4).floorToDouble() : (_scroll + 0.4).ceilToDouble();
    } else {
      target = _scroll.roundToDouble();
    }
    _animateTo(target.clamp(0.0, (total - 1).toDouble()));
  }

  @override
  Widget build(BuildContext context) {
    final tracks = AudioRepository.musicLibrary;
    final total = tracks.length;
    final selectedIdx = _scroll.round().clamp(0, total - 1);
    final selectedTrack = tracks[selectedIdx];
    final isSelectedBgm = selectedTrack.type == widget.currentBgmType;

    return LayoutBuilder(
      builder: (context, constraints) {
        final W = constraints.maxWidth;
        final H = constraints.maxHeight;
        final centerX = W / 2;
        // Carousel cards centered horizontally in the upper region
        final centerY = H * 0.38;

        final cardWidth = math.min(W * 0.50, 185.0);
        final cardHeight = math.min(H * 0.64, 215.0);
        final stepX = cardWidth * 0.88;

        // Build sorted card entries so center card paints on top
        final entries = <_CardEntry>[];
        for (int i = 0; i < total; i++) {
          final delta = i - _scroll;
          if (delta.abs() > 2.6) continue;
          final dist = delta.abs();
          final scale = (1.0 - (dist * 0.18)).clamp(0.64, 1.0);
          final opacity = (1.0 - (dist * 0.38)).clamp(0.0, 1.0);
          final dx = centerX + delta * stepX;
          final yRotation = -delta * 0.28;

          entries.add(_CardEntry(
            index: i,
            dist: dist,
            dx: dx,
            scale: scale,
            opacity: opacity,
            yRotation: yRotation,
            track: tracks[i],
          ));
        }

        // Draw further cards first
        entries.sort((a, b) => b.dist.compareTo(a.dist));

        return GestureDetector(
          onPanUpdate: (d) => _onPanUpdate(d, stepX),
          onPanEnd: (d) => _onPanEnd(d, stepX),
          behavior: HitTestBehavior.opaque,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 3D Carousel Cards
              for (final entry in entries)
                Positioned(
                  left: entry.dx - cardWidth / 2,
                  top: centerY - cardHeight / 2,
                  width: cardWidth,
                  height: cardHeight,
                  child: Opacity(
                    opacity: entry.opacity,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0016)
                        ..rotateY(entry.yRotation)
                        ..scaleByDouble(entry.scale, entry.scale, 1.0, 1.0),
                      child: _ComicVinylCard(
                        track: entry.track,
                        cardWidth: cardWidth,
                        cardHeight: cardHeight,
                        isFocused: entry.index == selectedIdx,
                        isCurrentBgm: entry.track.type == widget.currentBgmType,
                        isPreviewing: widget.previewingType == entry.track.type,
                        scrollAngle: _scrollAngle,
                        playbackAngle: _playbackAngle,
                        onTapCard: () {
                          ComicButton.playButtonSfx();
                          if (entry.index != selectedIdx) {
                            _animateTo(entry.index.toDouble());
                          } else {
                            widget.onTogglePreview(entry.track.type);
                          }
                        },
                      ),
                    ),
                  ),
                ),

              // Bottom control strip: Page dots + Set as BGM button
              Positioned(
                left: 16,
                right: 16,
                bottom: 8,
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
                    const SizedBox(height: 7),
                    // Action button
                    SizedBox(
                      width: math.min(W * 0.65, 230.0),
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
          ),
        );
      },
    );
  }
}

class _CardEntry {
  final int index;
  final double dist;
  final double dx;
  final double scale;
  final double opacity;
  final double yRotation;
  final MusicTrack track;

  _CardEntry({
    required this.index,
    required this.dist,
    required this.dx,
    required this.scale,
    required this.opacity,
    required this.yRotation,
    required this.track,
  });
}

// ─────────────────────────── _ComicVinylCard ─────────────────────────────────

class _ComicVinylCard extends StatelessWidget {
  const _ComicVinylCard({
    required this.track,
    required this.cardWidth,
    required this.cardHeight,
    required this.isFocused,
    required this.isCurrentBgm,
    required this.isPreviewing,
    required this.scrollAngle,
    required this.playbackAngle,
    required this.onTapCard,
  });

  final MusicTrack track;
  final double cardWidth;
  final double cardHeight;
  final bool isFocused;
  final bool isCurrentBgm;
  final bool isPreviewing;
  final double scrollAngle;
  final double playbackAngle;
  final VoidCallback onTapCard;

  @override
  Widget build(BuildContext context) {
    final color = _trackColor(track.type);
    final discSize = math.min(cardWidth * 0.62, 104.0);
    // Combine swipe scrub rotation with continuous playback rotation
    final discAngle = scrollAngle + (isPreviewing ? playbackAngle : 0.0);

    return GestureDetector(
      onTap: onTapCard,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isFocused ? _kInk : _kInk.withValues(alpha: 0.60),
            width: isFocused ? 2.2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isFocused ? color.withValues(alpha: 0.45) : const Color(0x33000000),
              offset: const Offset(3, 4),
              blurRadius: isFocused ? 8 : 4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Comic sleeve header banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: color.withValues(alpha: 0.18),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: _kInk, width: 1),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        track.type.name.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Bangers',
                          fontSize: 10,
                          letterSpacing: 1.2,
                          color: _kInk.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                    if (isCurrentBgm)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF00E676),
                        size: 13,
                      ),
                  ],
                ),
              ),

              // Vinyl disc container
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: discSize,
                    height: discSize,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Spinning PNG Vinyl Disc
                        Transform.rotate(
                          angle: discAngle,
                          child: Image.asset(
                            'assets/images/vinyl_disc.png',
                            width: discSize,
                            height: discSize,
                            fit: BoxFit.contain,
                          ),
                        ),

                        // Center track label inside vinyl disc hole
                        Container(
                          width: discSize * 0.31,
                          height: discSize * 0.31,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                            border: Border.all(color: _kInk, width: 1.2),
                          ),
                          child: Center(
                            child: Icon(
                              isPreviewing
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: discSize * 0.20,
                              color: _kInk,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Sleeve footer with track title and duration
              Container(
                padding: const EdgeInsets.fromLTRB(6, 2, 6, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      track.title.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Bangers',
                        fontSize: 13,
                        letterSpacing: 1.2,
                        color: _kInk,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        WaveformIndicator(
                          color: color,
                          isPlaying: isPreviewing,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          track.duration,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF777777),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────── _SlingshotVolumeGame ───────────────────────────
//
// Slingshot volume minigame:
//   • Shifted UP by 80px and ENLARGED by 40%.
//   • Arcade button placed directly beside the slingshot toggles target (BGM vs SFX).
//   • Loaded bullet in slingshot reflects active target (Cyan vs Gold).
//   • On hitting the volume bar: triggers comic snap/hit impact burst effect
//     and recoil punch on the volume bar. Left is 0%, right is 100%, default 80%.
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

  // Impact burst state & animation controller
  late AnimationController _impactCtrl;
  Offset _impactPos = Offset.zero;
  bool _impactTargetIsBgm = true;

  // Cached bar rects and slingshot anchor
  Rect _bgmBarRect = Rect.zero;
  Rect _sfxBarRect = Rect.zero;
  Offset _slingshotAnchor = Offset.zero;

  // Slingshot 40% enlarged parameters
  static const double _maxPull = 100.0; // Scaled from 74.0
  static const double _arcHeight = 65.0;

  @override
  void initState() {
    super.initState();
    // Default 80% volume positions
    _bgmBallFrac = widget.bgmVolume / 100.0;
    _sfxBallFrac = widget.sfxVolume / 100.0;

    _flightCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    )
      ..addListener(() => setState(() {}))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _onBallLanded();
      });

    _impactCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    )..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _flightCtrl.dispose();
    _impactCtrl.dispose();
    super.dispose();
  }

  void _onBallLanded() {
    final barRect = _targetIsBgm ? _bgmBarRect : _sfxBarRect;
    if (barRect.isEmpty) return;

    // Left is 0%, right is 100%
    final frac =
        ((_flightEnd.dx - barRect.left) / barRect.width).clamp(0.0, 1.0);
    final vol = (frac * 100).round();

    setState(() {
      _ballInFlight = false;
      if (_targetIsBgm) {
        _bgmBallFrac = frac;
      } else {
        _sfxBallFrac = frac;
      }

      // Trigger comic snap/hit burst effect
      _impactPos = _flightEnd;
      _impactTargetIsBgm = _targetIsBgm;
    });

    _impactCtrl.forward(from: 0.0);
    ComicButton.playButtonSfx();

    if (_targetIsBgm) {
      widget.notifier.setBgmVolume(vol);
    } else {
      widget.notifier.setSfxVolume(vol);
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

  void _launchBall() {
    final barRect = _targetIsBgm ? _bgmBarRect : _sfxBarRect;
    if (barRect.isEmpty || _slingshotAnchor == Offset.zero) return;

    // Pull left -> launches right; pull right -> launches left.
    final pullFrac = (-_dragOffset.dx / _maxPull).clamp(-1.0, 1.0);
    final landingFrac = ((pullFrac + 1.0) / 2.0).clamp(0.0, 1.0);
    final landingX = barRect.left + landingFrac * barRect.width;

    _flightStart = _slingshotAnchor;
    _flightEnd = Offset(landingX, barRect.center.dy);

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

  Offset _ballPos(double t) {
    final p0 = _flightStart;
    final p2 = _flightEnd;
    final p1 = Offset(
      (p0.dx + p2.dx) / 2,
      math.min(p0.dy, p2.dy) - _arcHeight,
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
      const double labelW = 54.0;
      const double barH = 14.0;
      const double bar1RowTop = 18.0;
      const double bar2RowTop = 80.0;
      const double barTrackOffset = 16.0;

      final barLeft = padH + labelW;
      final barWidth = W - barLeft - padH;

      _bgmBarRect = Rect.fromLTWH(
          barLeft, bar1RowTop + barTrackOffset, barWidth, barH);
      _sfxBarRect = Rect.fromLTWH(
          barLeft, bar2RowTop + barTrackOffset, barWidth, barH);

      // Slingshot shifted UP by 80px (H - 96 instead of H - 16)
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
                  ),
                ),
              ),
            ),

          // ── Aim switcher button placed BESIDE the slingshot ──────────────
          Positioned(
            left: _slingshotAnchor.dx + 44,
            top: _slingshotAnchor.dy - 46,
            child: GestureDetector(
              onTap: () {
                ComicButton.playButtonSfx();
                setState(() => _targetIsBgm = !_targetIsBgm);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _kInk,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ballColor, width: 2.0),
                  boxShadow: [
                    BoxShadow(
                      color: ballColor.withValues(alpha: 0.45),
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
              behavior: HitTestBehavior.opaque,
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
    // Dynamic punch bounce when ball hits this volume bar
    final bounceScale = bounceProgress > 0.0
        ? (1.0 + 0.08 * math.sin(bounceProgress * math.pi))
        : 1.0;

    return Transform.scale(
      scale: bounceScale,
      alignment: Alignment.center,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Toggle icon button
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
          // Label
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
          // Bar + value
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
//
// Enlarged by 40% (1.4x scale factor) and rendered at the elevated anchor.
//

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
    // 40% enlarged fork geometry
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

    const ballRadius = 15.5; // 40% enlarged ball (up from 11)

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
//
// Comic starburst rays + expanding shockwave ring + pop particles on hit.
//

class _ImpactBurstPainter extends CustomPainter {
  const _ImpactBurstPainter({
    required this.position,
    required this.progress,
    required this.color,
  });

  final Offset position;
  final double progress;
  final Color color;

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
  }

  @override
  bool shouldRepaint(_ImpactBurstPainter old) =>
      progress != old.progress ||
      position != old.position ||
      color != old.color;
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
