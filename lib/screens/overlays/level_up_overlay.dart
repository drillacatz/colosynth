

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:colosynth/services/level_progress_service.dart';
import 'package:colosynth/screens/theme/tokens.dart';

class LevelUpOverlay extends StatefulWidget {
  const LevelUpOverlay({
    super.key,
    required this.newLevel,
    required this.newUnlocks,
    required this.onDismiss,
  });

  final int newLevel;
  final List<UnlockGate> newUnlocks;
  final VoidCallback onDismiss;

  static Future<void> show(
    BuildContext context, {
    required int newLevel,
    required List<UnlockGate> newUnlocks,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0xEE000000),
      builder: (ctx) => LevelUpOverlay(
        newLevel: newLevel,
        newUnlocks: newUnlocks,
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  State<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<LevelUpOverlay> {
  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _LevelUpPanel(
        newLevel: widget.newLevel,
        newUnlocks: widget.newUnlocks,
        onDismiss: widget.onDismiss,
      ),
    ).animate().fadeIn(duration: 300.ms).scale(
          begin: const Offset(0.4, 0.4),
          duration: 600.ms,
          curve: Curves.elasticOut,
        );
  }
}



class _LevelUpPanel extends StatelessWidget {
  const _LevelUpPanel({
    required this.newLevel,
    required this.newUnlocks,
    required this.onDismiss,
  });

  final int newLevel;
  final List<UnlockGate> newUnlocks;
  final VoidCallback onDismiss;

  static const _gold = AppColors.ink;
  static const _bg = AppColors.paperWhite;
  static const _divider = AppColors.lightGray;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 22),
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: _gold, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _gold.withValues(alpha: 0.55),
              blurRadius: 0,
              offset: const Offset(6, 6),
            ),
            BoxShadow(
              color: _gold.withValues(alpha: 0.22),
              blurRadius: 40,
              spreadRadius: 6,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            _LevelBadge(level: newLevel),
            const SizedBox(height: 10),


            const Text(
              'LEVEL UP!',
              style: TextStyle(
                fontFamily: 'Bangers',
                fontSize: 44,
                color: _gold,
                letterSpacing: 7,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'You reached Level $newLevel',
              style: TextStyle(
                color: _gold.withValues(alpha: 0.50),
                fontSize: 11,
                letterSpacing: 3,
              ),
            ),


            if (newUnlocks.isNotEmpty) ...[
              const SizedBox(height: 22),
              Container(height: 1, color: _divider),
              const SizedBox(height: 14),
              const Text(
                '✧  NEWLY UNLOCKED  ✧',
                style: TextStyle(
                  color: AppColors.sketchGray,
                  fontSize: 9,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(newUnlocks.length, (i) {
                return _StaggeredUnlockRow(
                  gate: newUnlocks[i],
                  index: i,
                );
              }),
            ],

            const SizedBox(height: 26),
            ComicButton(
              label: 'CONTINUE',
              style: PBStyle.white,
              fontSize: 18,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 13),
              onTap: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}



class _StaggeredUnlockRow extends StatelessWidget {
  const _StaggeredUnlockRow({
    required this.gate,
    required this.index,
  });

  final UnlockGate gate;
  final int index;

  static const _gold = AppColors.ink;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _gold.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: _gold.withValues(alpha: 0.28), width: 1),
        ),
        child: Row(
          children: [
            Text(gate.emoji, style: const TextStyle(fontSize: 22, height: 1.0)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gate.label,
                    style: const TextStyle(
                      fontFamily: 'Bangers',
                      fontSize: 15,
                      color: _gold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    gate.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.40),
                      fontSize: 10,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.5),
                    width: 1),
              ),
              child:
                  const Icon(Icons.check, color: Color(0xFF4CAF50), size: 12),
            ),
          ],
        ),
      ),
    )
        .animate(delay: (200 + index * 100).ms)
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }
}



class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});

  final int level;

  static const _gold = AppColors.ink;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [

        const CustomPaint(
          size: Size(120, 120),
          painter: _RayPainter(progress: 1.0, color: _gold),
        )
            .animate(onPlay: (controller) => controller.repeat())
            .rotate(duration: 10.seconds),


        const CustomPaint(
          size: Size(94, 94),
          painter: _StarBurstPainter(color: _gold),
        ).animate().scale(
              begin: const Offset(0.5, 0.5),
              duration: 400.ms,
              curve: Curves.elasticOut,
            ),


        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1A0E00),
            border: Border.all(color: _gold, width: 2.0),
            boxShadow: [
              BoxShadow(
                color: _gold.withValues(alpha: 0.50),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$level',
              style: const TextStyle(
                fontFamily: 'Bangers',
                fontSize: 30,
                color: _gold,
                letterSpacing: 0,
                height: 1.0,
              ),
            ),
          ),
        )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(
              begin: const Offset(0.94, 0.94),
              end: const Offset(1.06, 1.06),
              duration: 1.seconds,
              curve: Curves.easeInOut,
            )
            .shimmer(
              delay: 2.seconds,
              duration: 1.5.seconds,
              color: Colors.white24,
            ),
      ],
    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack);
  }
}




class _StarBurstPainter extends CustomPainter {
  const _StarBurstPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    const spikes = 16;
    const innerR = 0.86;
    final path = Path();
    for (int i = 0; i < spikes * 2; i++) {
      final angle = (math.pi * 2 * i) / (spikes * 2) - math.pi / 2;
      final r = (i.isEven) ? 1.0 : innerR;
      final x = cx + (size.width / 2) * r * math.cos(angle);
      final y = cy + (size.height / 2) * r * math.sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.16));
  }

  @override
  bool shouldRepaint(_StarBurstPainter old) => old.color != color;
}

class _RayPainter extends CustomPainter {
  const _RayPainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final cx = size.width / 2, cy = size.height / 2;
    const rayCount = 12;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.10 * progress)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < rayCount; i++) {
      final angle = (math.pi * 2 * i) / rayCount;
      final innerR = size.width * 0.36;
      final outerR = size.width * 0.52 * progress;
      canvas.drawLine(
        Offset(cx + innerR * math.cos(angle), cy + innerR * math.sin(angle)),
        Offset(cx + outerR * math.cos(angle), cy + outerR * math.sin(angle)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RayPainter old) =>
      old.progress != progress || old.color != color;
}







class NextUnlockBanner extends StatelessWidget {
  const NextUnlockBanner({
    super.key,
    required this.playerLevel,
    required this.currentXp,
  });

  final int playerLevel;
  final int currentXp;

  static const _gold = AppColors.ink;
  static const _goldDim = AppColors.sketchGray;

  @override
  Widget build(BuildContext context) {
    final next = ProgressionService.instance.nextUnlock(playerLevel);
    if (next == null) return const SizedBox.shrink();

    final xpNeeded = ProgressionService.xpForLevel(next.requiredLevel);
    final xpNow = currentXp;
    final xpThisLevel = ProgressionService.xpForLevel(playerLevel);
    final progress =
        ((xpNow - xpThisLevel) / (xpNeeded - xpThisLevel)).clamp(0.0, 1.0);
    final battles = ProgressionService.approxBattlesTo(
      playerLevel,
      next.requiredLevel,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${next.emoji}  ${next.label}',
                style: const TextStyle(
                  color: _gold,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.5,
                ),
              ),
              const Spacer(),
              Text(
                'Lv ${next.requiredLevel}  ·  ~$battles wins',
                style: TextStyle(
                  color: _gold.withValues(alpha: 0.45),
                  fontSize: 9,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              backgroundColor: _goldDim.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(_gold),
            ),
          ),
        ],
      ),
    );
  }
}
