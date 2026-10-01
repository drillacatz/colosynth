import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Zenless Zone Zero (ZZZ) Style 3D Extruded Flat Typography.
///
/// Produces an authentic blocky 3D isometric extrusion using a multi-layered
/// solid shadow stack, remaining 100% vector and visually flat.
class ZzzExtrudedText extends StatelessWidget {
  const ZzzExtrudedText({
    super.key,
    required this.text,
    this.fontSize = 18.0,
    this.textColor = Colors.white,
    this.shadowColor = const Color(0xFF1A1A1A),
    this.letterSpacing = 1.8,
    this.depth = 4.0,
    this.fontFamily = 'Bangers',
    this.maxLines = 1,
    this.overflow,
    this.softWrap = false,
  });

  final String text;
  final double fontSize;
  final Color textColor;
  final Color shadowColor;
  final double letterSpacing;
  final double depth;
  final String fontFamily;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool softWrap;

  static List<Shadow> buildShadows({
    double depth = 4.0,
    Color shadowColor = const Color(0xFF1A1A1A),
  }) {
    final shadows = <Shadow>[];
    for (double d = 1.0; d <= depth; d += 0.5) {
      shadows.add(Shadow(offset: Offset(d, d), color: shadowColor));
    }
    return shadows;
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      style: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize,
        letterSpacing: letterSpacing,
        color: textColor,
        shadows: buildShadows(depth: depth, shadowColor: shadowColor),
      ),
    );
  }
}

/// Reusable ZZZ-style continuous/entrance ticker banner.
class ZzzTickerBanner extends StatefulWidget {
  const ZzzTickerBanner({
    super.key,
    required this.text,
    this.fontSize = 17.0,
    this.textColor = Colors.white,
    this.shadowColor = const Color(0xFF1A1A1A),
    this.bannerColor = const Color(0xFFFFD500),
    this.height = 38.0,
    this.reverse = false,
    this.crawlSpeed = 35.0,
    this.hasEntranceRush = true,
  });

  final String text;
  final double fontSize;
  final Color textColor;
  final Color shadowColor;
  final Color bannerColor;
  final double height;
  final bool reverse;
  final double crawlSpeed;
  final bool hasEntranceRush;

  @override
  State<ZzzTickerBanner> createState() => _ZzzTickerBannerState();
}

class _ZzzTickerBannerState extends State<ZzzTickerBanner>
    with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final AnimationController _tickerCtrl;
  double? _unitWidth;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _tickerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );

    if (widget.hasEntranceRush) {
      _entranceCtrl.forward();
    } else {
      _entranceCtrl.value = 1.0;
    }
    _tickerCtrl.repeat();
  }

  @override
  void didUpdateWidget(covariant ZzzTickerBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.fontSize != widget.fontSize) {
      _unitWidth = null;
    }
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _tickerCtrl.dispose();
    super.dispose();
  }

  double _getUnitWidth() {
    if (_unitWidth != null) return _unitWidth!;
    final tp = TextPainter(
      text: TextSpan(
        text: widget.text,
        style: TextStyle(
          fontFamily: 'Bangers',
          fontSize: widget.fontSize,
          letterSpacing: 2.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    _unitWidth = math.max(tp.width, 100.0);
    return _unitWidth!;
  }

  @override
  Widget build(BuildContext context) {
    final unitW = _getUnitWidth();

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.bannerColor,
        border: const Border.symmetric(
          horizontal: BorderSide(color: Color(0xFF1A1A1A), width: 2.5),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            offset: Offset(0, 4),
            blurRadius: 4,
          ),
        ],
      ),
      child: ClipRect(
        child: AnimatedBuilder(
          animation: Listenable.merge([_entranceCtrl, _tickerCtrl]),
          builder: (context, _) {
            final entranceP = Curves.easeOutCubic.transform(_entranceCtrl.value);
            final entranceOffset = (1.0 - entranceP) * 600.0;
            final steadyOffset = _tickerCtrl.value * (unitW * 3);

            final totalOffset = entranceOffset + steadyOffset;
            final modOffset = totalOffset % unitW;

            final dx = widget.reverse
                ? -unitW + modOffset
                : -modOffset;

            return Transform.translate(
              offset: Offset(dx, 0),
              child: OverflowBox(
                maxWidth: double.infinity,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(6, (i) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: ZzzExtrudedText(
                        text: widget.text,
                        fontSize: widget.fontSize,
                        textColor: widget.textColor,
                        shadowColor: widget.shadowColor,
                      ),
                    );
                  }),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Dual-direction ZZZ LED banner for the Store Screen items tab.
///
/// Contains two concurrent moving text streams:
/// 1. Foreground LED Title (e.g. `SYNTH CRATE`) scrolling in [reverse] direction
///    with neon glow.
/// 2. Background large grey ZZZ typography ticker (`/// COLOSYNTH SUPPLY // ... ///`)
///    scrolling in the OPPOSITE direction ([!reverse]).
class ZzzDualLedBanner extends StatefulWidget {
  const ZzzDualLedBanner({
    super.key,
    required this.label,
    this.ledColor = Colors.white,
    this.reverse = false,
    this.height = 44.0,
    this.backgroundZzzText =
        '/// COLOSYNTH SUPPLY // STREET DISTRIBUTOR // AUTHORIZED GOODS ///   ',
  });

  final String label;
  final Color ledColor;
  final bool reverse;
  final double height;
  final String backgroundZzzText;

  @override
  State<ZzzDualLedBanner> createState() => _ZzzDualLedBannerState();
}

class _ZzzDualLedBannerState extends State<ZzzDualLedBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  double _ledTileWidth = 200.0;
  double _zzzTileWidth = 400.0;

  static const double _kLedSpeedPxPerMs = 45.0 / 1000.0;
  static const double _kZzzSpeedPxPerMs = 35.0 / 1000.0;

  @override
  void initState() {
    super.initState();
    _calcMetrics();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
  }

  void _calcMetrics() {
    final ledText = '   ${widget.label}   ';
    final actualLedPainter = TextPainter(
      text: TextSpan(
        text: ledText,
        style: const TextStyle(
          fontSize: 16.0,
          fontFamily: 'Bangers',
          letterSpacing: 2.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    _ledTileWidth = math.max(actualLedPainter.width, 80.0);

    final zzzPainter = TextPainter(
      text: TextSpan(
        text: widget.backgroundZzzText,
        style: const TextStyle(
          fontSize: 26.0,
          fontFamily: 'Bangers',
          letterSpacing: 2.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    _zzzTileWidth = math.max(zzzPainter.width, 200.0);
  }

  @override
  void didUpdateWidget(covariant ZzzDualLedBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.label != widget.label ||
        oldWidget.backgroundZzzText != widget.backgroundZzzText) {
      _calcMetrics();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ledTileText = '   ${widget.label}   ';
    final zzzTileText = widget.backgroundZzzText;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : (MediaQuery.of(context).size.width * 2.5);
        final zzzCount = math.max(
          8,
          _zzzTileWidth > 0 ? (availWidth / _zzzTileWidth).ceil() + 4 : 8,
        );
        final ledCount = math.max(
          12,
          _ledTileWidth > 0 ? (availWidth / _ledTileWidth).ceil() + 4 : 12,
        );

        return Container(
          height: widget.height,
          color: const Color(0xFF0D0D0D),
          alignment: Alignment.center,
          child: ClipRect(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) {
                final tMs = _ctrl.value * 40000.0;

                // 1. Background Large Grey ZZZ Ticker (scrolling in OPPOSITE direction: !widget.reverse)
                final zzzTotalPx = tMs * _kZzzSpeedPxPerMs;
                final zzzMod = zzzTotalPx % _zzzTileWidth;
                final zzzDx = !widget.reverse
                    ? -_zzzTileWidth + zzzMod
                    : -zzzMod;

                // 2. Foreground Bright LED Ticker (scrolling in widget.reverse direction)
                final ledTotalPx = tMs * _kLedSpeedPxPerMs;
                final ledMod = ledTotalPx % _ledTileWidth;
                final ledDx = widget.reverse
                    ? -_ledTileWidth + ledMod
                    : -ledMod;

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Layer 1: Background Large Grey 3D Extruded ZZZ Typography
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.center,
                        child: Transform.translate(
                          offset: Offset(zzzDx, 0),
                          child: OverflowBox(
                            maxWidth: double.infinity,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(zzzCount, (i) {
                                return ZzzExtrudedText(
                                  text: zzzTileText,
                                  fontSize: 26.0,
                                  textColor: const Color(0xFF383838),
                                  shadowColor: const Color(0xFF141414),
                                  letterSpacing: 2.0,
                                  depth: 3.0,
                                );
                              }),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Layer 2: Foreground Neon LED Section Banner
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.center,
                        child: Transform.translate(
                          offset: Offset(ledDx, 0),
                          child: OverflowBox(
                            maxWidth: double.infinity,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(ledCount, (i) {
                                return Text(
                                  ledTileText,
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    fontFamily: 'Bangers',
                                    letterSpacing: 2.5,
                                    color: widget.ledColor,
                                    shadows: [
                                      Shadow(
                                        color: widget.ledColor
                                            .withValues(alpha: 0.65),
                                        blurRadius: 4,
                                      ),
                                      const Shadow(
                                        color: Colors.black,
                                        offset: Offset(1, 1),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
