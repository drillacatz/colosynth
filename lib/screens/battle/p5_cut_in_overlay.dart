import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:colosynth/game_settings.dart';
import 'package:colosynth/services/audio_service.dart';
import 'package:colosynth/services/sprite_repository.dart';

/// A Persona 5 Royal-style cinematic "Eye Banner" cut-in overlay.
///
/// Features:
/// - Angled diagonal comic banner (-9° slant) with heavy ink borders.
/// - Speed-lines background stream with character accent color.
/// - Focused eye gaze crop from the character's portrait.
/// - Dynamic slide-in (220ms) -> focus hold (320ms) -> slash exit (160ms).
/// - Automatically triggers onComplete when the sequence finishes.
class P5CutInOverlay extends StatefulWidget {
  const P5CutInOverlay({
    super.key,
    required this.characterId,
    required this.characterName,
    required this.skillName,
    required this.accentColor,
    required this.onComplete,
    this.duration = const Duration(milliseconds: 1400),
  });

  final String characterId;
  final String characterName;
  final String skillName;
  final Color accentColor;
  final VoidCallback onComplete;
  final Duration duration;

  @override
  State<P5CutInOverlay> createState() => _P5CutInOverlayState();
}

class _P5CutInOverlayState extends State<P5CutInOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _lineSlideX;
  late final Animation<double> _verticalExpand;
  late final Animation<double> _scale;
  late final Animation<double> _exitSlash;
  late final Animation<double> _dimOpacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);

    // Dark backdrop opacity: fades in 0.0 -> 0.25, holds at 0.65 until 0.86, fades out
    _dimOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.65)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0.65),
        weight: 61,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.65, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 14,
      ),
    ]).animate(_ctrl);

    // Phase 1: Tiny laser line slides in from left (-1.2 to 0.0) during 0.0..0.25 (0-350ms)
    _lineSlideX = Tween<double>(begin: -1.2, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.25, curve: Curves.easeOutCubic),
      ),
    );

    // Phase 2: Vertical bloom upward & downward (0.02 to 1.0) during 0.25..0.43 (350-600ms)
    _verticalExpand = Tween<double>(begin: 0.02, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.25, 0.43, curve: Curves.easeOutBack),
      ),
    );

    // Phase 3: Slight focus zoom during hold during 0.43..0.86 (600-1200ms)
    _scale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.43, 0.86, curve: Curves.linear),
      ),
    );

    // Phase 4: Slash exit to right (0.0 to 1.4) during 0.86..1.0 (1200-1400ms)
    _exitSlash = Tween<double>(begin: 0.0, end: 1.4).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.86, 1.0, curve: Curves.easeInCubic),
      ),
    );

    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });

    // Play high-impact cut-in audio cue
    AudioService.instance.playSfx(SfxEvent.activeskillCharged);

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bannerHeight = (size.height * 0.22).clamp(130.0, 180.0);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Stack(
          children: [
            // 1. Dark comic vignette backdrop
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.black.withValues(alpha: _dimOpacity.value),
                ),
              ),
            ),

            // 2A. Phase 1: Tiny glowing laser line/stroke slides in across screen
            if (_ctrl.value < 0.25)
              Positioned(
                left: 0,
                right: 0,
                top: (size.height - bannerHeight) / 2 - 20,
                height: bannerHeight,
                child: Transform.translate(
                  offset: Offset(_lineSlideX.value * size.width, 0),
                  child: Center(
                    child: ClipPath(
                      clipper: const _SlantedBannerClipper(slantY: 20),
                      child: Container(
                        height: 5.0,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: widget.accentColor,
                              blurRadius: 18,
                              spreadRadius: 3,
                            ),
                            const BoxShadow(
                              color: Colors.white,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // 2B. Phase 2-4: Expanding & full eye banner with exit slash
            if (_ctrl.value >= 0.25)
              Positioned(
                left: 0,
                right: 0,
                top: (size.height - bannerHeight) / 2 - 20,
                height: bannerHeight,
                child: Transform.translate(
                  offset: Offset(
                    _ctrl.value >= 0.86 ? _exitSlash.value * size.width : 0.0,
                    0,
                  ),
                  child: Transform.scale(
                    scale: _scale.value,
                    child: Transform.scale(
                      scaleY: _verticalExpand.value,
                      alignment: Alignment.center,
                      child: ClipPath(
                        clipper: const _SlantedBannerClipper(slantY: 20),
                        child: Container(
                      decoration: BoxDecoration(
                        color: widget.accentColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Animated comic speed-lines in background
                          CustomPaint(
                            painter: _SpeedLinesPainter(
                              color: Colors.black.withValues(alpha: 0.25),
                              phase: _ctrl.value * 8,
                            ),
                          ),

                          // Focused eye gaze crop
                          Align(
                            alignment: const Alignment(-0.25, 0.0),
                            child: SizedBox(
                              width: size.width * 0.85,
                              height: bannerHeight * 3.2,
                              child: OverflowBox(
                                maxHeight: bannerHeight * 3.8,
                                minHeight: bannerHeight * 3.8,
                                alignment: const Alignment(0.0, -0.45),
                                child: Image.asset(
                                  SpriteRepository.characterFullBody(widget.characterId),
                                  fit: BoxFit.cover,
                                  alignment: const Alignment(0.0, -0.45),
                                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                ),
                              ),
                            ),
                          ),

                          // Comic halftone dot overlay
                          CustomPaint(
                            painter: _HalftoneDotPainter(
                              dotColor: Colors.black.withValues(alpha: 0.12),
                            ),
                          ),

                          // Diagonal comic slash borders (outer #1A1A1A + accent line)
                          const Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: _SlantedBorderPainter(slantY: 20),
                              ),
                            ),
                          ),

                          // Character & Skill badge in Bangers comic font
                          Positioned(
                            right: 24,
                            bottom: 14,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.characterName.toUpperCase(),
                                  style: TextStyle(
                                    fontFamily: 'Bangers',
                                    fontSize: 16,
                                    letterSpacing: 2,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    shadows: const [
                                      Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2, 2)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A1A1A),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: widget.accentColor, width: 1.5),
                                  ),
                                  child: Text(
                                    widget.skillName.toUpperCase(),
                                    style: const TextStyle(
                                      fontFamily: 'Bangers',
                                      fontSize: 18,
                                      letterSpacing: 1.5,
                                      color: Color(0xFFFFD700),
                                      shadows: [
                                        Shadow(color: Colors.black, blurRadius: 3, offset: Offset(1, 1)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Dynamic flash streak during slash exit
                          if (_ctrl.value >= 0.76)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: Container(
                                  color: Colors.white.withValues(
                                    alpha: (1.0 - (_ctrl.value - 0.76) / 0.24).clamp(0.0, 0.7),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        );
      },
    );
  }
}

/// Slanted trapezoid clipper creating the Persona 5 dynamic angle.
class _SlantedBannerClipper extends CustomClipper<Path> {
  const _SlantedBannerClipper({required this.slantY});
  final double slantY;

  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0, slantY)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - slantY)
      ..lineTo(0, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant _SlantedBannerClipper oldClipper) =>
      oldClipper.slantY != slantY;
}

/// Custom painter for top and bottom heavy comic ink outlines on slanted banner.
class _SlantedBorderPainter extends CustomPainter {
  const _SlantedBorderPainter({required this.slantY});
  final double slantY;

  @override
  void paint(Canvas canvas, Size size) {
    final penBlack = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke;

    final penWhite = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Top border
    canvas.drawLine(Offset(0, slantY), Offset(size.width, 0), penBlack);
    canvas.drawLine(Offset(0, slantY + 2), Offset(size.width, 2), penWhite);

    // Bottom border
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height - slantY), penBlack);
    canvas.drawLine(Offset(0, size.height - 2), Offset(size.width, size.height - slantY - 2), penWhite);
  }

  @override
  bool shouldRepaint(covariant _SlantedBorderPainter oldDelegate) =>
      oldDelegate.slantY != slantY;
}

/// Speedlines streaming horizontally behind the character.
class _SpeedLinesPainter extends CustomPainter {
  const _SpeedLinesPainter({required this.color, required this.phase});
  final Color color;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (var y = 8.0; y < size.height; y += 14.0) {
      final offset = (math.sin(y * 13.0 + phase) * 40.0);
      final xStart = (size.width * 0.1) + offset;
      final xEnd = size.width + offset;
      canvas.drawLine(Offset(xStart, y), Offset(xEnd, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpeedLinesPainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.color != color;
}

/// Halftone dot grid overlay.
class _HalftoneDotPainter extends CustomPainter {
  const _HalftoneDotPainter({required this.dotColor});
  final Color dotColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = dotColor;
    const spacing = 16.0;
    const radius = 2.0;

    for (var x = spacing / 2; x < size.width; x += spacing) {
      for (var y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HalftoneDotPainter oldDelegate) =>
      oldDelegate.dotColor != dotColor;
}
