import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:colosynth/database/synth/synth_definition.dart';
import 'package:colosynth/game/logic/direction.dart';
import 'package:colosynth/screens/overlays/synth_crate_opening_overlay.dart';
import 'package:colosynth/services/sensor_tilt_service.dart';

/// A 3D interactive holographic Trading Card representing a Synth.
///
/// Inspired by Pokebox & Simey's holographic Pokémon cards:
/// - Smooth 3D perspective matrix transform via touch drag + device gyroscope.
/// - Dynamic holographic rainbow iridescence, specular glare hotspot, and star glitter.
/// - Minimalist manga martial arts combo silhouette centerpiece.
/// - Rarity-tiered metallic frames and authentic card metadata.
class SynthHoloCard extends StatefulWidget {
  const SynthHoloCard({
    super.key,
    required this.definition,
    this.level = 1,
    this.width = 280,
    this.height = 420,
    this.isInteractive = true,
  });

  final SynthDefinition definition;
  final int level;
  final double width;
  final double height;
  final bool isInteractive;

  @override
  State<SynthHoloCard> createState() => _SynthHoloCardState();
}

class _SynthHoloCardState extends State<SynthHoloCard>
    with SingleTickerProviderStateMixin {
  double _touchPitch = 0.0;
  double _touchRoll = 0.0;
  bool _isDragging = false;

  late final AnimationController _springCtrl;
  late Animation<double> _springPitch;
  late Animation<double> _springRoll;

  @override
  void initState() {
    super.initState();
    _springCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..addListener(() {
        if (!_isDragging) {
          setState(() {
            _touchPitch = _springPitch.value;
            _touchRoll = _springRoll.value;
          });
        }
      });

    _springPitch = const AlwaysStoppedAnimation(0.0);
    _springRoll = const AlwaysStoppedAnimation(0.0);

    if (widget.isInteractive) {
      SensorTiltService.instance.start();
    }
  }

  @override
  void dispose() {
    if (widget.isInteractive) {
      SensorTiltService.instance.stop();
    }
    _springCtrl.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails _) {
    if (!widget.isInteractive) return;
    _springCtrl.stop();
    _isDragging = true;
    HapticFeedback.selectionClick();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.isInteractive) return;
    // Map pan delta to rotation angles
    // Horizontal drag rotates around Y axis (roll)
    // Vertical drag rotates around X axis (pitch)
    const sensitivity = 0.007;
    setState(() {
      _touchRoll = (_touchRoll - details.delta.dx * sensitivity)
          .clamp(-0.45, 0.45);
      _touchPitch = (_touchPitch + details.delta.dy * sensitivity)
          .clamp(-0.40, 0.40);
    });
  }

  void _onPanEnd(DragEndDetails _) {
    if (!widget.isInteractive) return;
    _isDragging = false;
    _springPitch = Tween<double>(begin: _touchPitch, end: 0.0).animate(
      CurvedAnimation(parent: _springCtrl, curve: Curves.easeOutBack),
    );
    _springRoll = Tween<double>(begin: _touchRoll, end: 0.0).animate(
      CurvedAnimation(parent: _springCtrl, curve: Curves.easeOutBack),
    );
    _springCtrl.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final rarity = SynthRarity.fromDefinitionId(widget.definition.id);

    return ValueListenableBuilder<SensorTiltData>(
      valueListenable: SensorTiltService.instance.tiltNotifier,
      builder: (context, sensorData, child) {
        final totalPitch = (_touchPitch + (widget.isInteractive ? sensorData.pitch : 0.0))
            .clamp(-0.48, 0.48);
        final totalRoll = (_touchRoll + (widget.isInteractive ? sensorData.roll : 0.0))
            .clamp(-0.48, 0.48);

        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.0014)
          ..rotateX(totalPitch)
          ..rotateY(totalRoll);

        return GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: Transform(
            transform: transform,
            alignment: Alignment.center,
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    offset: Offset(-totalRoll * 35, totalPitch * 35 + 8),
                    blurRadius: 22,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: rarity.color.withValues(alpha: 0.25),
                    offset: Offset(-totalRoll * 20, totalPitch * 20),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 1. Base Card Content (Manga Collectible Card)
                    _BaseCardContent(
                      definition: widget.definition,
                      level: widget.level,
                      rarity: rarity,
                    ),

                    // 2. Holographic Foil & Specular Glare Overlay
                    CustomPaint(
                      painter: _HoloFoilPainter(
                        pitch: totalPitch,
                        roll: totalRoll,
                        rarity: rarity,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The physical base card structure and layout.
class _BaseCardContent extends StatelessWidget {
  const _BaseCardContent({
    required this.definition,
    required this.level,
    required this.rarity,
  });

  final SynthDefinition definition;
  final int level;
  final SynthRarity rarity;

  @override
  Widget build(BuildContext context) {
    final borderThemeColor = rarity.color;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF14131C),
        border: Border.all(color: const Color(0xFF1A1A1A), width: 3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1D2A),
          border: Border.all(color: borderThemeColor.withValues(alpha: 0.85), width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: Name & Rarity Emblem
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        definition.name.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Bangers',
                          fontSize: 18,
                          letterSpacing: 1.2,
                          color: Colors.white,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'SYNTH // ${definition.id.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: borderThemeColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: borderThemeColor,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: const [
                      BoxShadow(color: Color(0xFF1A1A1A), offset: Offset(1, 1)),
                    ],
                  ),
                  child: Text(
                    '+$level',
                    style: const TextStyle(
                      fontFamily: 'Bangers',
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Artwork Frame: Minimalist Manga Martial Arts Combo Diagram
            Expanded(
              flex: 5,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFBFBF9),
                  border: Border.all(color: const Color(0xFF1A1A1A), width: 2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Halftone Paper Shading
                      const _HalftonePaperPattern(),

                      // Manga Martial Arts Silhouette Painter
                      CustomPaint(
                        painter: _MartialArtsSilhouettePainter(
                          sequence: definition.effectiveSequence,
                          themeColor: borderThemeColor,
                        ),
                      ),

                      // Rarity Watermark Tag
                      Positioned(
                        right: 6,
                        bottom: 4,
                        child: Text(
                          rarity.label,
                          style: TextStyle(
                            fontFamily: 'Bangers',
                            fontSize: 10,
                            letterSpacing: 1.5,
                            color: const Color(0xFF1A1A1A).withValues(alpha: 0.25),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 6),

            // Directional Combo Sequence Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF111018),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white12, width: 1),
              ),
              child: Row(
                children: [
                  const Text(
                    'COMBO: ',
                    style: TextStyle(
                      fontFamily: 'Bangers',
                      fontSize: 10,
                      color: Colors.white54,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (int i = 0; i < definition.effectiveSequence.length; i++) ...[
                            _CardDirectionBadge(
                              direction: definition.effectiveSequence[i],
                              accentColor: borderThemeColor,
                            ),
                            if (i < definition.effectiveSequence.length - 1)
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 2),
                                child: Icon(
                                  Icons.chevron_right,
                                  size: 11,
                                  color: Colors.white30,
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Stats Matrix Box
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF262436),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF1A1A1A), width: 1.8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatRow(
                      label: 'STAMINA DMG',
                      value: '+${definition.counterStaminaDamage}',
                      accent: const Color(0xFFFF5252),
                    ),
                    const Divider(color: Colors.white12, height: 1),
                    _StatRow(
                      label: 'DAMAGE MULT',
                      value: '×${definition.bonusDamageMult.toStringAsFixed(1)}',
                      accent: const Color(0xFF00E5FF),
                    ),
                    const Divider(color: Colors.white12, height: 1),
                    _StatRow(
                      label: 'SKILL CHARGE',
                      value: '+${definition.activeSkillChargeBonus}%',
                      accent: const Color(0xFFFFD54F),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 4),

            // Card Footer: Authenticity Holo Seal & Edition Stamp
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'COLOSYNTH TCG // CORE SER. 01',
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: Colors.white38,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: borderThemeColor.withValues(alpha: 0.8),
                        border: Border.all(color: Colors.white70, width: 1),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      rarity.label,
                      style: TextStyle(
                        fontFamily: 'Bangers',
                        fontSize: 8,
                        letterSpacing: 1,
                        color: borderThemeColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            color: Colors.white70,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Bangers',
            fontSize: 11,
            color: accent,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _CardDirectionBadge extends StatelessWidget {
  const _CardDirectionBadge({
    required this.direction,
    required this.accentColor,
  });

  final AttackDirection direction;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 17,
      height: 17,
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFB),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: const Color(0xFF1A1A1A), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Color(0xFF1A1A1A), offset: Offset(1, 1)),
        ],
      ),
      child: Center(
        child: Text(
          direction.arrow,
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

/// Draws subtle comic halftone screentone dots in the artwork frame.
class _HalftonePaperPattern extends StatelessWidget {
  const _HalftonePaperPattern();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HalftonePatternPainter(),
    );
  }
}

class _HalftonePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF1A1A1A).withValues(alpha: 0.05);
    const spacing = 7.0;
    for (double x = 3; x < size.width; x += spacing) {
      for (double y = 3; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.9, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Minimalist Manga Martial Arts Combo Diagram.
///
/// Draws a stylized combatant silhouette executing the combo motion:
/// - Directional strike posture (kick, punch, slash, aerial leap).
/// - Dynamic action brush lines and impact burst speedlines.
class _MartialArtsSilhouettePainter extends CustomPainter {
  const _MartialArtsSilhouettePainter({
    required this.sequence,
    required this.themeColor,
  });

  final List<AttackDirection> sequence;
  final Color themeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Determine primary motion archetype from the first and last attack directions
    final firstDir = sequence.isNotEmpty ? sequence.first : AttackDirection.n;

    // 1. Comic Action Speedlines in background
    final speedLinePaint = Paint()
      ..color = themeColor.withValues(alpha: 0.18)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final rng = math.Random(sequence.hashCode);
    for (int i = 0; i < 14; i++) {
      final angle = rng.nextDouble() * math.pi * 2;
      final dist1 = 25.0 + rng.nextDouble() * 20.0;
      final dist2 = dist1 + 30.0 + rng.nextDouble() * 40.0;
      canvas.drawLine(
        Offset(cx + math.cos(angle) * dist1, cy + math.sin(angle) * dist1),
        Offset(cx + math.cos(angle) * dist2, cy + math.sin(angle) * dist2),
        speedLinePaint,
      );
    }

    // 2. Dynamic Impact Arc / Motion Slash
    final arcPaint = Paint()
      ..color = themeColor.withValues(alpha: 0.6)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final arcPath = Path();
    if (firstDir == AttackDirection.n || firstDir == AttackDirection.ne) {
      // Upward rising sweep arc
      arcPath.moveTo(cx - 35, cy + 25);
      arcPath.quadraticBezierTo(cx - 15, cy - 35, cx + 38, cy - 25);
    } else if (firstDir == AttackDirection.s || firstDir == AttackDirection.sw) {
      // Downward ground strike arc
      arcPath.moveTo(cx - 40, cy - 20);
      arcPath.quadraticBezierTo(cx + 10, cy - 10, cx + 35, cy + 30);
    } else {
      // Forward thrust arc
      arcPath.moveTo(cx - 45, cy);
      arcPath.lineTo(cx + 45, cy);
    }
    canvas.drawPath(arcPath, arcPaint);

    // 3. Manga Combatant Silhouette (Bold #1A1A1A Ink with dynamic pose)
    final inkPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.fill;

    // Head
    final headOffset = (firstDir == AttackDirection.n)
        ? Offset(cx - 6, cy - 28)
        : Offset(cx - 14, cy - 22);
    canvas.drawCircle(headOffset, 6.5, inkPaint);

    // Torso & Limbs
    final bodyPath = Path();
    if (firstDir == AttackDirection.n) {
      // Flying high kick pose
      bodyPath.moveTo(cx - 6, cy - 22);
      bodyPath.lineTo(cx - 14, cy - 2);   // Torso
      bodyPath.lineTo(cx + 32, cy - 28);  // High kicking leg
      bodyPath.lineTo(cx + 35, cy - 22);
      bodyPath.lineTo(cx - 8, cy + 6);
      bodyPath.lineTo(cx - 20, cy + 26);  // Support leg
      bodyPath.lineTo(cx - 26, cy + 22);
      bodyPath.lineTo(cx - 16, cy);
      bodyPath.close();

      // Extended guard arm
      final armPath = Path()
        ..moveTo(cx - 10, cy - 16)
        ..lineTo(cx - 28, cy - 8)
        ..lineTo(cx - 26, cy - 4)
        ..lineTo(cx - 8, cy - 12)
        ..close();
      canvas.drawPath(armPath, inkPaint);
    } else if (firstDir == AttackDirection.s) {
      // Low sweep slide pose
      bodyPath.moveTo(cx - 14, cy - 16);
      bodyPath.lineTo(cx - 6, cy + 4);
      bodyPath.lineTo(cx + 38, cy + 18);  // Sweeping extended leg
      bodyPath.lineTo(cx + 36, cy + 24);
      bodyPath.lineTo(cx - 10, cy + 12);
      bodyPath.lineTo(cx - 28, cy + 20);  // Bent back knee
      bodyPath.lineTo(cx - 24, cy + 8);
      bodyPath.close();

      // Ground brace arm
      final armPath = Path()
        ..moveTo(cx - 10, cy - 8)
        ..lineTo(cx - 16, cy + 16)
        ..lineTo(cx - 12, cy + 17)
        ..lineTo(cx - 6, cy - 6)
        ..close();
      canvas.drawPath(armPath, inkPaint);
    } else {
      // Forward lunging dash punch / dual blade pose
      bodyPath.moveTo(cx - 14, cy - 16);
      bodyPath.lineTo(cx + 4, cy - 4);
      bodyPath.lineTo(cx + 36, cy - 4);   // Thrusting strike arm
      bodyPath.lineTo(cx + 34, cy + 2);
      bodyPath.lineTo(cx, cy + 4);
      bodyPath.lineTo(cx + 18, cy + 26);  // Forward lunge leg
      bodyPath.lineTo(cx + 12, cy + 28);
      bodyPath.lineTo(cx - 6, cy + 8);
      bodyPath.lineTo(cx - 28, cy + 22);  // Back anchor leg
      bodyPath.lineTo(cx - 30, cy + 16);
      bodyPath.close();
    }
    canvas.drawPath(bodyPath, inkPaint);

    // 4. Energy impact spark starburst
    final starPaint = Paint()..color = themeColor;
    final starCenter = (firstDir == AttackDirection.n)
        ? Offset(cx + 32, cy - 25)
        : (firstDir == AttackDirection.s)
            ? Offset(cx + 38, cy + 20)
            : Offset(cx + 38, cy - 2);

    for (int i = 0; i < 4; i++) {
      final a = (i * math.pi / 2);
      canvas.drawLine(
        starCenter - Offset(math.cos(a) * 8, math.sin(a) * 8),
        starCenter + Offset(math.cos(a) * 8, math.sin(a) * 8),
        Paint()
          ..color = starPaint.color
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.drawCircle(starCenter, 2.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_MartialArtsSilhouettePainter old) =>
      old.sequence != sequence || old.themeColor != themeColor;
}

/// Holographic Foil Shader Painter.
///
/// Implements Pokebox / Simey's rainbow holographic iridescence and specular glare:
/// - Glare highlight tracking opposite to viewer angle.
/// - Spectral sweep rainbow gradient rotated by tilt.
/// - Procedural star glitter particles for Epic and Legendary rarities.
class _HoloFoilPainter extends CustomPainter {
  const _HoloFoilPainter({
    required this.pitch,
    required this.roll,
    required this.rarity,
  });

  final double pitch;
  final double roll;
  final SynthRarity rarity;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Specular Glare Center (Opposite to tilt direction)
    // roll < 0 (tilted left) -> light reflects on right (gx > 0.5)
    final gx = (0.5 - roll * 1.5).clamp(0.05, 0.95) * w;
    final gy = (0.5 + pitch * 1.5).clamp(0.05, 0.95) * h;
    final glareCenter = Offset(gx, gy);

    // 1. Specular Glare Hotspot (Pure white soft reflection)
    final glareRadius = math.max(w, h) * 0.7;
    final glareOpacity = (rarity == SynthRarity.legendary)
        ? 0.35
        : (rarity == SynthRarity.epic)
            ? 0.28
            : (rarity == SynthRarity.rare)
                ? 0.22
                : 0.16;

    final glarePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          (glareCenter.dx / w) * 2 - 1,
          (glareCenter.dy / h) * 2 - 1,
        ),
        radius: 0.75,
        colors: [
          Colors.white.withValues(alpha: glareOpacity),
          Colors.white.withValues(alpha: glareOpacity * 0.4),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..blendMode = BlendMode.screen;

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), glarePaint);

    // Common cards only feature sleek specular glare
    if (rarity == SynthRarity.common) return;

    // 2. Rare: Diagonal Spectral Prism Diffraction Lines (Reverse-holo sheen)
    if (rarity == SynthRarity.rare) {
      final diagAngle = math.atan2(pitch, roll) + math.pi / 4;
      final shift = (roll + pitch) * 1.5;

      // Base linear prism sheen across card
      final prismPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment(math.cos(diagAngle), math.sin(diagAngle)),
          end: Alignment(-math.cos(diagAngle), -math.sin(diagAngle)),
          colors: SynthRarity.rainbowColors
              .map((c) => c.withValues(alpha: 0.20))
              .toList(),
        ).createShader(Rect.fromLTWH(0, 0, w, h))
        ..blendMode = BlendMode.colorDodge;
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), prismPaint);

      // Diagonal diffraction micro-lines
      final linePaint = Paint()
        ..blendMode = BlendMode.screen
        ..style = PaintingStyle.stroke;

      const bandCount = 14;
      for (int i = 0; i < bandCount; i++) {
        final phase = ((i / bandCount) + shift) % 1.0;
        final colorIndex =
            (phase * (SynthRarity.rainbowColors.length - 1)).floor();
        final c1 = SynthRarity.rainbowColors[colorIndex];
        final c2 = SynthRarity.rainbowColors[
            (colorIndex + 1) % SynthRarity.rainbowColors.length];
        final t = (phase * (SynthRarity.rainbowColors.length - 1)) - colorIndex;
        final bandColor = Color.lerp(c1, c2, t)!.withValues(alpha: 0.30);

        final yOffset = phase * (h + w * 0.8) - w * 0.4;
        linePaint.color = bandColor;
        linePaint.strokeWidth = 2.0 + math.sin(phase * math.pi) * 3.5;
        canvas.drawLine(
          Offset(-20, yOffset),
          Offset(w + 20, yOffset - w * 0.55),
          linePaint,
        );
      }
      return;
    }

    // 3. Epic: Shattered Crystal / Geometric Prismatic Diffraction Mesh
    if (rarity == SynthRarity.epic) {
      const epicColors = [
        Color(0xFFE040FB), // Magenta Orchid
        Color(0xFF7C4DFF), // Deep Violet
        Color(0xFF00E5FF), // Electric Cyan
        Color(0xFFFF4081), // Neon Pink
        Color(0xFFE040FB),
      ];

      final holoAngle = math.atan2(pitch, roll) + math.pi / 4;
      final foilPaint = Paint()
        ..shader = SweepGradient(
          center: Alignment(
            (glareCenter.dx / w) * 2 - 1,
            (glareCenter.dy / h) * 2 - 1,
          ),
          startAngle: holoAngle,
          endAngle: holoAngle + math.pi * 2,
          colors: epicColors.map((c) => c.withValues(alpha: 0.35)).toList(),
        ).createShader(Rect.fromLTWH(0, 0, w, h))
        ..blendMode = BlendMode.colorDodge;
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), foilPaint);

      // Crystalline shattered facet grid
      final facetPaint = Paint()..blendMode = BlendMode.screen;
      const cols = 5;
      const rows = 8;
      final colW = w / cols;
      final rowH = h / rows;

      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          final fx = c * colW;
          final fy = r * rowH;
          final facetCenter = Offset(fx + colW / 2, fy + rowH / 2);
          final dist = (facetCenter - glareCenter).distance;
          final proximity = (1.0 - (dist / glareRadius)).clamp(0.0, 1.0);

          if (proximity > 0.08) {
            final intensity = math.pow(proximity, 1.8).toDouble();
            final colorIdx = (r * 2 + c) % epicColors.length;
            facetPaint.color = epicColors[colorIdx].withValues(
              alpha: (0.12 + intensity * 0.50).clamp(0.0, 1.0),
            );

            final path = Path()
              ..moveTo(fx + 2, fy + 2)
              ..lineTo(fx + colW - 2, fy + rowH * 0.35)
              ..lineTo(fx + colW * 0.65, fy + rowH - 2)
              ..lineTo(fx + 2, fy + rowH - 2)
              ..close();
            canvas.drawPath(path, facetPaint);
          }
        }
      }

      _drawStarGlitter(canvas, w, h, glareCenter, glareRadius,
          count: 24, baseColor: const Color(0xFFE040FB));
      return;
    }

    // 4. Legendary: Cosmic Starlight + Intense Rainbow Sweep + Chromatic Edge Glow
    if (rarity == SynthRarity.legendary) {
      final holoAngle = math.atan2(pitch, roll) + math.pi / 4;
      final foilPaint = Paint()
        ..shader = SweepGradient(
          center: Alignment(
            (glareCenter.dx / w) * 2 - 1,
            (glareCenter.dy / h) * 2 - 1,
          ),
          startAngle: holoAngle,
          endAngle: holoAngle + math.pi * 2,
          colors: SynthRarity.rainbowColors
              .map((c) => c.withValues(alpha: 0.50))
              .toList(),
        ).createShader(Rect.fromLTWH(0, 0, w, h))
        ..blendMode = BlendMode.colorDodge;
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), foilPaint);

      // Chromatic perimeter edge reflection
      final edgePaint = Paint()
        ..shader = SweepGradient(
          center: Alignment.center,
          startAngle: holoAngle * 1.5,
          endAngle: holoAngle * 1.5 + math.pi * 2,
          colors: SynthRarity.rainbowColors
              .map((c) => c.withValues(alpha: 0.65))
              .toList(),
        ).createShader(Rect.fromLTWH(0, 0, w, h))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..blendMode = BlendMode.screen;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(2, 2, w - 4, h - 4),
          const Radius.circular(12),
        ),
        edgePaint,
      );

      _drawStarGlitter(canvas, w, h, glareCenter, glareRadius,
          count: 48, baseColor: const Color(0xFFFFD500));
    }
  }

  void _drawStarGlitter(
    Canvas canvas,
    double w,
    double h,
    Offset glareCenter,
    double glareRadius, {
    required int count,
    required Color baseColor,
  }) {
    final glitterRng = math.Random(1337);
    final starPaint = Paint()..blendMode = BlendMode.screen;

    for (int i = 0; i < count; i++) {
      final sx = glitterRng.nextDouble() * w;
      final sy = glitterRng.nextDouble() * h;
      final dist = (Offset(sx, sy) - glareCenter).distance;
      final proximity = (1.0 - (dist / glareRadius)).clamp(0.0, 1.0);

      if (proximity > 0.15) {
        final intensity = math.pow(proximity, 2.5).toDouble();
        final starSize = 1.2 + glitterRng.nextDouble() * 2.8 * intensity;

        starPaint.color = (glitterRng.nextBool() ? Colors.white : baseColor)
            .withValues(alpha: (0.4 + intensity * 0.6).clamp(0.0, 1.0));

        // Draw micro 4-point sparkle cross
        canvas.drawLine(
          Offset(sx - starSize * 2, sy),
          Offset(sx + starSize * 2, sy),
          starPaint..strokeWidth = 0.8,
        );
        canvas.drawLine(
          Offset(sx, sy - starSize * 2),
          Offset(sx, sy + starSize * 2),
          starPaint..strokeWidth = 0.8,
        );
        canvas.drawCircle(Offset(sx, sy), starSize * 0.5, starPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_HoloFoilPainter old) =>
      old.pitch != pitch || old.roll != roll || old.rarity != rarity;
}
