import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io' show Platform;
import 'package:model_viewer_plus/model_viewer_plus.dart';

import 'package:colosynth/character_viewer/character_model_registry.dart';
import 'package:colosynth/character_viewer/character_viewer_providers.dart';
import 'package:colosynth/services/sprite_repository.dart';
import 'package:colosynth/screens/theme/tokens.dart';

class CharacterModelViewer extends ConsumerStatefulWidget {
  final String characterId;
  final bool isLocked;
  final bool autoRotate;
  final bool allowUserControl;
  final String? initialAnimation;
  final double height;
  final bool showActionBar;

  const CharacterModelViewer({
    super.key,
    required this.characterId,
    this.isLocked = false,
    this.autoRotate = true,
    this.allowUserControl = true,
    this.initialAnimation,
    this.height = 320,
    this.showActionBar = true,
  });

  @override
  ConsumerState<CharacterModelViewer> createState() => _CharacterModelViewerState();
}

class _CharacterModelViewerState extends ConsumerState<CharacterModelViewer> {
  Timer? _animResetTimer;
  final bool _hasError = false;

  String _resolveUriScheme(String path) {
    if (path.startsWith('http://') ||
        path.startsWith('https://') ||
        path.startsWith('file://')) {
      return path;
    }
    if (kIsWeb) {
      return path;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'file:///android_asset/flutter_assets/$path';
    }
    return 'file:///$path';
  }

  @override
  void dispose() {
    _animResetTimer?.cancel();
    super.dispose();
  }

  void _triggerAnimation(String animName) {
    ref.read(characterAnimationProvider(widget.characterId).notifier).state = animName;

    if (animName != 'idle') {
      _animResetTimer?.cancel();
      _animResetTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) {
          ref.read(characterAnimationProvider(widget.characterId).notifier).state = 'idle';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final asset = CharacterModelRegistry.resolve(widget.characterId);
    final currentAnim = ref.watch(characterAnimationProvider(widget.characterId));

    final isBundled = CharacterModelRegistry.isModelBundled(widget.characterId);
    final isTest = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (asset == null || _hasError || !isBundled || isTest) {
      return _build2DFallback();
    }

    final resolvedSrc = _resolveUriScheme(asset.glbPath);
    final resolvedPoster = asset.posterPath != null ? _resolveUriScheme(asset.posterPath!) : null;

    Widget viewerWidget = ModelViewer(
      backgroundColor: Colors.transparent,
      src: resolvedSrc,
      poster: resolvedPoster,
      alt: 'ColoSynth 3D Character ${widget.characterId}',
      autoRotate: false,
      cameraControls: widget.allowUserControl,
      disableZoom: !widget.allowUserControl,
      cameraOrbit: asset.cameraOrbit,
      fieldOfView: asset.fieldOfView,
      exposure: 1.05,
      shadowIntensity: 1.2,
      shadowSoftness: 0.1,
      animationName: currentAnim,
      autoPlay: true,
      ar: false,
      loading: Loading.eager,
    );

    if (widget.isLocked) {
      viewerWidget = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0,      0,      0,      1, 0,
        ]),
        child: Opacity(
          opacity: 0.60,
          child: viewerWidget,
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 12,
            left: 20,
            right: 20,
            height: 44,
            child: _ComicToyPedestal(characterId: widget.characterId),
          ),
          GestureDetector(
            onTap: () {
              _triggerAnimation('reaction');
            },
            child: viewerWidget,
          ),
          if (widget.isLocked)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.70),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock, color: Colors.white70, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'LOCKED',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _build2DFallback() {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.paperWhite.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            SpriteRepository.characterPortrait(widget.characterId),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.person,
              color: Colors.white54,
              size: 64,
            ),
          ),
        ),
      ),
    );
  }
}

class _ComicToyPedestal extends StatelessWidget {
  final String characterId;
  const _ComicToyPedestal({required this.characterId});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ComicToyPedestalPainter(characterId: characterId),
    );
  }
}

class _ComicToyPedestalPainter extends CustomPainter {
  final String characterId;
  _ComicToyPedestalPainter({required this.characterId});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rx = size.width * 0.44;
    final ry = size.height * 0.38;

    // Hard comic shadow offset
    final shadowRect = Rect.fromCenter(
      center: center + const Offset(4, 5),
      width: rx * 2,
      height: ry * 2,
    );
    canvas.drawOval(
      shadowRect,
      Paint()..color = AppColors.shadow.withValues(alpha: 0.65),
    );

    // Main base pedestal surface
    final baseRect = Rect.fromCenter(
      center: center,
      width: rx * 2,
      height: ry * 2,
    );
    canvas.drawOval(
      baseRect,
      Paint()..color = AppColors.paperWhite,
    );

    // Inner accent ring (monochrome ink accent)
    final innerRect = Rect.fromCenter(
      center: center,
      width: rx * 1.74,
      height: ry * 1.74,
    );
    canvas.drawOval(
      innerRect,
      Paint()
        ..color = AppColors.ink.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Ink contour outline
    canvas.drawOval(
      baseRect,
      Paint()
        ..color = AppColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );

    // Halftone dots across the front perimeter
    final dotPaint = Paint()..color = AppColors.ink.withValues(alpha: 0.20);
    for (int i = -4; i <= 4; i++) {
      final angle = (i * 14.0) * (math.pi / 180.0);
      final dx = center.dx + (rx * 0.74) * math.sin(angle);
      final dy = center.dy + (ry * 0.74) * math.cos(angle);
      canvas.drawCircle(Offset(dx, dy), 1.6, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_ComicToyPedestalPainter old) => old.characterId != characterId;
}
