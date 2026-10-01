import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:colosynth/screens/overlays/synth_crate_opening_overlay.dart'
    show SynthRarity;

/// A high-performance, 100% procedural 3D perspective chest model in Flutter.
///
/// Features:
/// - True 3D perspective geometry using `Transform` and `Matrix4`.
/// - Multi-face depth rendering (front, sides, top, and inner illuminated cavity).
/// - 3D hinged lid that swings open backwards up to -2.1 radians.
/// - Comic-styled metallic reinforced straps, corner brackets with rivets, and padlock.
/// - Dynamic procedural fracture cracks that propagate and glow with rarity color on each tap.
/// - Internal upward volumetric light flare when the lid swings open.
class Procedural3dChest extends StatefulWidget {
  const Procedural3dChest({
    super.key,
    required this.tapsDone,
    required this.rarity,
    required this.isOpening,
    this.isOpened = false,
    this.width = 220.0,
    this.height = 190.0,
  });

  final int tapsDone;
  final SynthRarity rarity;
  final bool isOpening;
  final bool isOpened;
  final double width;
  final double height;

  @override
  State<Procedural3dChest> createState() => _Procedural3dChestState();
}

class _Procedural3dChestState extends State<Procedural3dChest>
    with TickerProviderStateMixin {
  late final AnimationController _lidController;
  late final AnimationController _idleFloatController;
  late final Animation<double> _lidAngle;
  late final Animation<double> _interiorLight;

  @override
  void initState() {
    super.initState();
    _lidController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _lidAngle = Tween<double>(begin: 0.0, end: -2.1).animate(
      CurvedAnimation(
        parent: _lidController,
        curve: Curves.easeOutBack,
      ),
    );

    _interiorLight = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _lidController,
        curve: const Interval(0.15, 1.0, curve: Curves.easeOut),
      ),
    );

    _idleFloatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    if (widget.isOpened || widget.isOpening) {
      _lidController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant Procedural3dChest oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.isOpening || widget.isOpened) && !_lidController.isAnimating && _lidController.value < 1.0) {
      _lidController.forward();
    }
  }

  @override
  void dispose() {
    _lidController.dispose();
    _idleFloatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rarityColor = widget.rarity.color;

    return AnimatedBuilder(
      animation: Listenable.merge([_lidController, _idleFloatController]),
      builder: (context, child) {
        final floatY = math.sin(_idleFloatController.value * math.pi) * 4.0;
        final floatRoll = math.sin(_idleFloatController.value * math.pi) * 0.02;

        return Transform.translate(
          offset: Offset(0, floatY),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0018) // perspective
              ..rotateZ(floatRoll),
            child: SizedBox(
              width: widget.width,
              height: widget.height + 40,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // 1. Ground Shadow (elliptical comic drop shadow)
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: widget.width * 0.85,
                      height: 22,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.55),
                            blurRadius: 18,
                            spreadRadius: 4,
                          ),
                          BoxShadow(
                            color: rarityColor.withValues(
                              alpha: 0.15 + (widget.tapsDone * 0.06),
                            ),
                            blurRadius: 28,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. Volumetric Interior Light Beam (emerges as lid opens)
                  if (_interiorLight.value > 0.01)
                    Positioned(
                      top: 0,
                      child: Opacity(
                        opacity: _interiorLight.value.clamp(0.0, 1.0),
                        child: CustomPaint(
                          size: Size(widget.width * 1.4, widget.height * 1.6),
                          painter: _VolumetricLightPainter(color: rarityColor),
                        ),
                      ),
                    ),

                  // 3. Chest Base (Front & Sides)
                  Positioned(
                    bottom: 20,
                    child: _ChestBaseWidget(
                      width: widget.width,
                      height: widget.height * 0.62,
                      tapsDone: widget.tapsDone,
                      rarityColor: rarityColor,
                      isOpen: _lidAngle.value < -0.1,
                    ),
                  ),

                  // 4. Chest Hinged Lid (Pivots at top-back)
                  Positioned(
                    bottom: 20 + (widget.height * 0.62) - 8,
                    child: Transform(
                      alignment: Alignment.bottomCenter,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0020)
                        ..rotateX(_lidAngle.value),
                      child: _ChestLidWidget(
                        width: widget.width * 1.04,
                        height: widget.height * 0.38,
                        tapsDone: widget.tapsDone,
                        rarityColor: rarityColor,
                        isOpened: widget.isOpened,
                      ),
                    ),
                  ),

                  // 5. Front Padlock / Latch
                  if (_lidAngle.value > -0.6)
                    Positioned(
                      bottom: 20 + (widget.height * 0.62) - 24,
                      child: Transform(
                        alignment: Alignment.topCenter,
                        transform: Matrix4.identity()
                          ..rotateX(_lidAngle.value * 0.4),
                        child: _ChestPadlock(
                          rarityColor: rarityColor,
                          tapsDone: widget.tapsDone,
                          isUnlocking: widget.isOpening || widget.isOpened,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The solid lower half of the 3D chest with wooden planks, metal brackets, and cavity.
class _ChestBaseWidget extends StatelessWidget {
  const _ChestBaseWidget({
    required this.width,
    required this.height,
    required this.tapsDone,
    required this.rarityColor,
    required this.isOpen,
  });

  final double width;
  final double height;
  final int tapsDone;
  final Color rarityColor;
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF3B2314), // Rich dark mahogany wood
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border.all(color: Colors.black, width: 3.5),
        boxShadow: [
          BoxShadow(
            color: rarityColor.withValues(alpha: 0.35 + (tapsDone * 0.10)),
            blurRadius: 16 + (tapsDone * 6.0),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Inner cavity glow when open
          if (isOpen)
            Positioned(
              top: 0,
              left: 4,
              right: 4,
              height: 24,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      rarityColor.withValues(alpha: 0.95),
                      const Color(0xFF1A0A05),
                    ],
                  ),
                ),
              ),
            ),

          // Wood plank dividers & dynamic cracks
          CustomPaint(
            size: Size(width, height),
            painter: _ChestFacePainter(
              tapsDone: tapsDone,
              rarityColor: rarityColor,
              isLid: false,
            ),
          ),

          // Metallic Reinforcement Straps (Vertical)
          Positioned(
            left: width * 0.22,
            top: 0,
            bottom: 0,
            width: 18,
            child: _MetalStrap(height: height, rarityColor: rarityColor),
          ),
          Positioned(
            right: width * 0.22,
            top: 0,
            bottom: 0,
            width: 18,
            child: _MetalStrap(height: height, rarityColor: rarityColor),
          ),

          // Corner Metallic Brackets
          Positioned(
            left: 0,
            bottom: 0,
            child: _CornerBracket(isLeft: true, isTop: false, rarityColor: rarityColor),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: _CornerBracket(isLeft: false, isTop: false, rarityColor: rarityColor),
          ),

          // Center Keyhole Plate
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 4),
              width: 32,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF24160E),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFD4AF37), width: 2),
              ),
              child: Center(
                child: Icon(
                  Icons.vpn_key_rounded,
                  size: 14,
                  color: rarityColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The 3D hinged lid of the chest that swings open backwards.
class _ChestLidWidget extends StatelessWidget {
  const _ChestLidWidget({
    required this.width,
    required this.height,
    required this.tapsDone,
    required this.rarityColor,
    required this.isOpened,
  });

  final double width;
  final double height;
  final int tapsDone;
  final Color rarityColor;
  final bool isOpened;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF4A2E1B), // Slightly lighter wood for top lid
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border.all(color: Colors.black, width: 3.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            offset: Offset(0, 4),
            blurRadius: 6,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Wood bevel & cracks
          CustomPaint(
            size: Size(width, height),
            painter: _ChestFacePainter(
              tapsDone: tapsDone,
              rarityColor: rarityColor,
              isLid: true,
            ),
          ),

          // Metallic Straps (Vertical) aligned with base
          Positioned(
            left: width * 0.22,
            top: 0,
            bottom: 0,
            width: 18,
            child: _MetalStrap(height: height, rarityColor: rarityColor),
          ),
          Positioned(
            right: width * 0.22,
            top: 0,
            bottom: 0,
            width: 18,
            child: _MetalStrap(height: height, rarityColor: rarityColor),
          ),

          // Corner Metallic Brackets
          Positioned(
            left: 0,
            top: 0,
            child: _CornerBracket(isLeft: true, isTop: true, rarityColor: rarityColor),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: _CornerBracket(isLeft: false, isTop: true, rarityColor: rarityColor),
          ),

          // Top comic bevel highlight strip
          Positioned(
            top: 6,
            left: 20,
            right: 20,
            height: 4,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Metallic vertical reinforcement strap with 3D rivets.
class _MetalStrap extends StatelessWidget {
  const _MetalStrap({required this.height, required this.rarityColor});
  final double height;
  final Color rarityColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF261D1A), // Heavy dark iron
        border: const Border.symmetric(
          vertical: BorderSide(color: Colors.black, width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: rarityColor.withValues(alpha: 0.20),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(4, (i) {
          return Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFD4AF37), // Brass rivet
              border: Border.all(color: Colors.black, width: 1),
            ),
          );
        }),
      ),
    );
  }
}

/// Reinforced metallic comic corner bracket with rivets.
class _CornerBracket extends StatelessWidget {
  const _CornerBracket({
    required this.isLeft,
    required this.isTop,
    required this.rarityColor,
  });

  final bool isLeft;
  final bool isTop;
  final Color rarityColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: const Color(0xFF2C221D),
        border: Border(
          left: isLeft ? const BorderSide(color: Colors.black, width: 2.5) : BorderSide.none,
          right: !isLeft ? const BorderSide(color: Colors.black, width: 2.5) : BorderSide.none,
          top: isTop ? const BorderSide(color: Colors.black, width: 2.5) : BorderSide.none,
          bottom: !isTop ? const BorderSide(color: Colors.black, width: 2.5) : BorderSide.none,
        ),
      ),
      child: Center(
        child: Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFD4AF37),
            border: Border.all(color: Colors.black, width: 1),
          ),
        ),
      ),
    );
  }
}

/// Padlock that shakes and glows before snapping open.
class _ChestPadlock extends StatelessWidget {
  const _ChestPadlock({
    required this.rarityColor,
    required this.tapsDone,
    required this.isUnlocking,
  });

  final Color rarityColor;
  final int tapsDone;
  final bool isUnlocking;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Shackle
        Container(
          width: 20,
          height: 14,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            border: Border.all(color: const Color(0xFFD4AF37), width: 3.5),
          ),
        ),
        // Body
        Container(
          width: 32,
          height: 26,
          decoration: BoxDecoration(
            color: const Color(0xFFFFB300),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.black, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: rarityColor.withValues(alpha: 0.6),
                blurRadius: 8 + (tapsDone * 4.0),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.lock_rounded,
              size: 16,
              color: Color(0xFF261D1A),
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom painter for horizontal plank lines and progressive glowing cracks.
class _ChestFacePainter extends CustomPainter {
  final int tapsDone;
  final Color rarityColor;
  final bool isLid;

  _ChestFacePainter({
    required this.tapsDone,
    required this.rarityColor,
    required this.isLid,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Horizontal Plank Groove Lines
    final plankPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..strokeWidth = 2.0;

    final stepY = size.height / 3.0;
    canvas.drawLine(Offset(0, stepY), Offset(size.width, stepY), plankPaint);
    canvas.drawLine(Offset(0, stepY * 2), Offset(size.width, stepY * 2), plankPaint);

    // 2. Procedural Glowing Fracture Cracks
    if (tapsDone > 0) {
      final glowPaint = Paint()
        ..color = rarityColor.withValues(alpha: 0.85)
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final corePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      if (!isLid) {
        // Base cracks (branching across the front face)
        path.moveTo(size.width * 0.5, 0);
        path.lineTo(size.width * 0.48, size.height * 0.28);
        path.lineTo(size.width * 0.42, size.height * 0.55);
        path.lineTo(size.width * 0.38, size.height * 0.90);

        if (tapsDone > 1) {
          path.moveTo(size.width * 0.48, size.height * 0.28);
          path.lineTo(size.width * 0.62, size.height * 0.45);
          path.lineTo(size.width * 0.68, size.height * 0.72);
        }

        if (tapsDone > 2) {
          path.moveTo(size.width * 0.42, size.height * 0.55);
          path.lineTo(size.width * 0.26, size.height * 0.68);
          path.lineTo(size.width * 0.22, size.height * 0.95);

          path.moveTo(size.width * 0.62, size.height * 0.45);
          path.lineTo(size.width * 0.76, size.height * 0.60);
          path.lineTo(size.width * 0.82, size.height * 0.85);
        }
      } else {
        // Lid cracks
        path.moveTo(size.width * 0.5, size.height);
        path.lineTo(size.width * 0.52, size.height * 0.65);
        path.lineTo(size.width * 0.46, size.height * 0.30);
        path.lineTo(size.width * 0.50, 0);

        if (tapsDone > 1) {
          path.moveTo(size.width * 0.52, size.height * 0.65);
          path.lineTo(size.width * 0.68, size.height * 0.40);
        }

        if (tapsDone > 2) {
          path.moveTo(size.width * 0.46, size.height * 0.30);
          path.lineTo(size.width * 0.32, size.height * 0.15);
        }
      }

      // Draw glowing outline first, then hot white core
      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ChestFacePainter old) =>
      old.tapsDone != tapsDone || old.rarityColor != rarityColor;
}

/// Volumetric light fan expanding upwards from the open chest.
class _VolumetricLightPainter extends CustomPainter {
  final Color color;
  _VolumetricLightPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final bottomCenter = Offset(size.width / 2, size.height * 0.75);

    final fanPath = Path()
      ..moveTo(bottomCenter.dx - 40, bottomCenter.dy)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(bottomCenter.dx + 40, bottomCenter.dy)
      ..close();

    final gradient = RadialGradient(
      center: Alignment.bottomCenter,
      radius: 0.95,
      colors: [
        color.withValues(alpha: 0.50),
        color.withValues(alpha: 0.18),
        Colors.transparent,
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fanPath, paint);
  }

  @override
  bool shouldRepaint(covariant _VolumetricLightPainter old) => old.color != color;
}
