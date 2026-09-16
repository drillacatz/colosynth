import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide Image;
import 'package:colosynth/game_settings.dart';
import 'package:colosynth/services/audio_service.dart';


import 'package:colosynth/game/logic/skill_meter.dart';

class ActiveSkillMeterWidget extends StatefulWidget {
  const ActiveSkillMeterWidget({
    super.key,
    required this.activeSkill,
    required this.onActivate,
  });

  final ActiveSkillMeter activeSkill;
  final VoidCallback onActivate;

  @override
  State<ActiveSkillMeterWidget> createState() => _ActiveSkillMeterWidgetState();
}

class _ActiveSkillMeterWidgetState extends State<ActiveSkillMeterWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerCtrl;
  bool _wasFull = false;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _wasFull = widget.activeSkill.isFull;
    widget.activeSkill.chargeNotifier.addListener(_onChargeChanged);
  }

  void _onChargeChanged() {
    final nowFull = widget.activeSkill.isFull;
    if (nowFull && !_wasFull) {
      AudioService.instance.playSfx(SfxEvent.activeskillCharged);
    }
    _wasFull = nowFull;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.activeSkill.chargeNotifier.removeListener(_onChargeChanged);
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ratio = widget.activeSkill.ratio.clamp(0.0, 1.0);
    final isFull = widget.activeSkill.isFull;
    final canActivate = widget.activeSkill.canActivate;

    return GestureDetector(
      onTap: canActivate ? widget.onActivate : null,
      child: AnimatedBuilder(
        animation: _shimmerCtrl,
        builder: (_, __) {
          final scale = isFull
              ? 1.0 + 0.06 * math.sin(_shimmerCtrl.value * 2 * math.pi)
              : 1.0;
          return Transform.scale(
            scale: scale,
            child: SizedBox(
              width: 76,
              height: 76,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(76, 76),
                    painter: _ActiveSkillCirclePainter(
                      ratio: ratio,
                      isFull: isFull,
                      shimmerPhase: _shimmerCtrl.value,
                    ),
                  ),
                  Text(
                    isFull ? '★' : 'S',
                    style: TextStyle(
                      fontFamily: 'Bangers',
                      fontSize: isFull ? 26 : 20,
                      color: isFull
                          ? const Color(0xFF00E5FF)
                          : const Color(0xFF998855),
                      shadows: isFull
                          ? const [
                              Shadow(color: Color(0xFFFF9800), blurRadius: 12),
                              Shadow(color: Color(0xFF00E5FF), blurRadius: 6),
                            ]
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ActiveSkillCirclePainter extends CustomPainter {
  const _ActiveSkillCirclePainter({
    required this.ratio,
    required this.isFull,
    required this.shimmerPhase,
  });

  final double ratio;
  final bool isFull;
  final double shimmerPhase;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final baseR = size.width / 2 - 10.0;
    const sw = 7.0;

    if (isFull) {
      final phaseAngle = shimmerPhase * 2 * math.pi;

      for (int i = 0; i < 3; i++) {
        final wave = (shimmerPhase + i * 0.33) % 1.0;
        final auraRadius = baseR + 2 + wave * 14;
        final auraAlpha = (1.0 - wave) * 0.45;

        canvas.drawCircle(
          c,
          auraRadius,
          Paint()
            ..color = Color.fromARGB((auraAlpha * 255).round(), 0xFF, 0xC1, 0x07)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3 + (1.0 - wave) * 4
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 + wave * 8),
        );
      }

      final glowAlpha = 0.50 + 0.25 * math.sin(phaseAngle);
      canvas.drawCircle(
        c,
        baseR + 6,
        Paint()
          ..color = Color.fromARGB((glowAlpha * 255).round(), 0xFF, 0x98, 0x00)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );

      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(phaseAngle);
      canvas.translate(-c.dx, -c.dy);

      final sweepPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw + 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
        ..shader = ui.Gradient.sweep(
          c,
          const [
            Color(0x00FFD700),
            Color(0xFF00E5FF),
            Color(0xFFFF9800),
            Color(0xFFFFFFFF),
            Color(0x00FFD700),
          ],
          const [0.0, 0.25, 0.50, 0.75, 1.0],
        );
      canvas.drawCircle(c, baseR, sweepPaint);

      for (int p = 0; p < 4; p++) {
        final pAngle = (p * math.pi / 2) + phaseAngle * 1.5;
        final px = c.dx + (baseR + 4) * math.cos(pAngle);
        final py = c.dy + (baseR + 4) * math.sin(pAngle);
        canvas.drawCircle(
          Offset(px, py),
          3.0,
          Paint()
            ..color = const Color(0xFFFFFFFF)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }

      canvas.restore();
    }

    canvas.drawCircle(
        c,
        baseR,
        Paint()
          ..color = const Color(0xFF0D0800)
          ..style = PaintingStyle.fill);

    canvas.drawCircle(
        c,
        baseR,
        Paint()
          ..color = const Color(0xFF2E2A1A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw);

    if (ratio > 0) {
      final fillColor =
          Color.lerp(const Color(0xFF666644), const Color(0xFF00E5FF), ratio)!;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: baseR),
        -math.pi / 2,
        2 * math.pi * ratio,
        false,
        Paint()
          ..color = fillColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw
          ..strokeCap = StrokeCap.round,
      );
    }

    if (isFull) {
      canvas.drawCircle(
        c,
        baseR * 0.56,
        Paint()
          ..color = Color.fromARGB(
            (0.35 * 255 + 0.15 * math.sin(shimmerPhase * 4 * math.pi) * 255)
                .round()
                .clamp(0, 255),
            0xFF,
            0xD7,
            0x00,
          )
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    } else {
      canvas.drawCircle(
        c,
        baseR * 0.50,
        Paint()
          ..color = const Color(0xFF181200)
          ..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(_ActiveSkillCirclePainter old) =>
      old.ratio != ratio ||
      old.isFull != isFull ||
      old.shimmerPhase != shimmerPhase;
}
