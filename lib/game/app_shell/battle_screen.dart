import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flame/game.dart';
import 'package:flame/flame.dart';
import 'package:colosynth/providers/battle_provider.dart';

import 'package:colosynth/services/rewarded_ad_service.dart';
import 'package:colosynth/game/scenes/battle_scene.dart';
import 'package:colosynth/game/widgets/battle_hud_widget.dart';
import 'package:colosynth/game/widgets/battle_pause_widget.dart';
import 'package:colosynth/game/widgets/battle_overlays.dart';

import 'package:colosynth/game/app_shell/battle_models.dart';
import 'package:colosynth/game/app_shell/battle_game.dart';

export 'battle_models.dart';
export 'battle_game.dart';

class BattleScreen extends ConsumerStatefulWidget {
  const BattleScreen({
    super.key,
    required this.params,
    required this.tournamentStage,
    required this.tournamentTier,
    this.onGameReady,
  });

  final BattleGameParams params;
  final String tournamentStage;
  final int tournamentTier;
  final VoidCallback? onGameReady;

  @override
  ConsumerState<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends ConsumerState<BattleScreen> {
  late final BattleScene _scene;
  BattleGameApi? _api;
  bool _paused = false;
  bool _exiting = false;
  BattleResult? _finalResult;
  AppLifecycleListener? _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _scene = BattleSceneFactory.forTier(widget.tournamentTier);

    _lifecycleListener = AppLifecycleListener(
      onStateChange: _handleLifecycleState,
    );
  }

  void _handleLifecycleState(AppLifecycleState state) {
    if (_exiting || !mounted) return;
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        _setPaused(true);
      case AppLifecycleState.resumed:

        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    _lifecycleListener?.dispose();

    _api?.battleResultNotifier.removeListener(_onResultChanged);
    _scene.dispose();

    try {
      Flame.images.clearCache();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _onResultChanged() async {
    if (_exiting || !mounted) return;
    final result = _api?.battleResultNotifier.value;
    if (result == null) return;

    setState(() => _finalResult = result);



    if (result.outcome == BattleOutcome.quit) {
      _exiting = true;
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(result);
      }
    }
  }

  void _setPaused(bool value) {
    if (_paused == value) return;
    setState(() => _paused = value);
    final game = ref.read(battleGameProvider(widget.params));
    if (value) {
      game.pauseEngine();
    } else {
      game.resumeEngine();
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(battleStatsProvider);

    if (statsAsync.hasError) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Error loading stats: ${statsAsync.error}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    if (statsAsync.isLoading || !statsAsync.hasValue || statsAsync.value == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
        ),
      );
    }

    final game = ref.watch(battleGameProvider(widget.params));

    if (_api != game) {
      _api?.battleResultNotifier.removeListener(_onResultChanged);
      _api = game;
      _api!.battleResultNotifier.addListener(_onResultChanged);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onGameReady?.call();
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_finalResult != null) return;
        _setPaused(true);
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(
                child: _SceneBackground(scene: _scene),
              ),

              if (_api != null)
                RepaintBoundary(child: GameWidget(game: _api! as BattleFlameGame)),
              const IgnorePointer(child: _VignetteOverlay()),
              if (_finalResult == null && _api != null)
                RepaintBoundary(
                  child: BattleHudWidget(
                    game: _api!,
                    onPause: () => _setPaused(true),
                  ),
                ),
              if (_paused && _finalResult == null && _api != null)
                RepaintBoundary(
                  child: BattlePauseWidget(
                    game: _api! as BattleFlameGame,
                    onResume: () => _setPaused(false),
                    onRestart: () {
                      _setPaused(false);
                      _api!.resetBattle();
                    },
                  ),
                ),
              if (_finalResult?.outcome == BattleOutcome.defeat)
                RepaintBoundary(
                  child: DefeatOverlay(
                    reviveAvailable: ref.read(rewardedAdServiceProvider).isReady,
                    onRevive: () {
                      ref.read(rewardedAdServiceProvider).showAd(
                        onRewarded: () {
                          if (!mounted) return;
                          setState(() => _finalResult = null);
                          _api?.revive();
                        },
                        onDismissed: () {

                        },
                      );
                    },
                    onRestart: () {
                      setState(() => _finalResult = null);
                      _api?.resetBattle();
                    },
                    onQuit: () {
                      _exiting = true;
                      Navigator.of(context, rootNavigator: true)
                          .pop(_finalResult);
                    },
                  ),
                ),
              if (_finalResult?.outcome == BattleOutcome.victory)
                RepaintBoundary(
                  child: VictoryOverlay(
                    result: _finalResult!,
                    onContinue: () {
                      _exiting = true;
                      Navigator.of(context, rootNavigator: true)
                          .pop(_finalResult);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SceneBackground extends StatelessWidget {
  const _SceneBackground({required this.scene});

  final BattleScene scene;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      scene.imagePath,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        return Container(color: const Color(0xFF08020F));
      },
    );
  }
}

class _VignetteOverlay extends StatefulWidget {
  const _VignetteOverlay();

  @override
  State<_VignetteOverlay> createState() => _VignetteOverlayState();
}

class _VignetteOverlayState extends State<_VignetteOverlay> {
  @override
  void dispose() {
    _VignettePainter.disposeCache();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(
      child: SizedBox.expand(
        child: CustomPaint(
          painter: _VignettePainter(),
        ),
      ),
    );
  }
}

class _VignettePainter extends CustomPainter {
  const _VignettePainter();

  static Size? _lastSize;
  static ui.Picture? _cachedPicture;

  static void disposeCache() {
    _cachedPicture?.dispose();
    _cachedPicture = null;
    _lastSize = null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_cachedPicture == null || _lastSize != size) {
      _lastSize = size;
      _cachedPicture?.dispose();
      final recorder = ui.PictureRecorder();
      final recordCanvas = Canvas(recorder);

      final rect = Offset.zero & size;
      final vignettePaint = Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.15),
            Colors.black.withValues(alpha: 0.75),
          ],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(rect);
      recordCanvas.drawRect(rect, vignettePaint);

      final path = Path();
      for (double i = 0; i < size.height; i += 4.0) {
        path.moveTo(0, i);
        path.lineTo(size.width, i);
      }
      recordCanvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.02)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke,
      );

      _cachedPicture = recorder.endRecording();
    }

    if (_cachedPicture != null) {
      canvas.drawPicture(_cachedPicture!);
    }
  }

  @override
  bool shouldRepaint(covariant _VignettePainter oldDelegate) => false;
}
