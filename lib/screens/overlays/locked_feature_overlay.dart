import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:colosynth/services/level_progress_service.dart';
import 'package:colosynth/screens/theme/animation_tokens.dart';
import 'package:colosynth/screens/theme/tokens.dart';
import 'package:colosynth/screens/theme/background.dart';
import 'package:colosynth/widgets/common/common_widgets.dart';

class LockedFeatureOverlay extends StatefulWidget {
  const LockedFeatureOverlay({
    super.key,
    this.feature,
    this.requiredLevel,
    this.currentLevel,
    this.customTitle,
    this.customDescription,
    this.customConditionText,
    this.customEmoji,
    required this.onDismiss,
  });

  final UnlockableFeature? feature;
  final int? requiredLevel;
  final int? currentLevel;
  final String? customTitle;
  final String? customDescription;
  final String? customConditionText;
  final String? customEmoji;
  final VoidCallback onDismiss;

  static Future<void> show(
    BuildContext context, {
    UnlockableFeature? feature,
    int? requiredLevel,
    int? currentLevel,
    String? customTitle,
    String? customDescription,
    String? customConditionText,
    String? customEmoji,
  }) {
    HapticFeedback.lightImpact();
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (ctx) => LockedFeatureOverlay(
        feature: feature,
        requiredLevel: requiredLevel,
        currentLevel: currentLevel,
        customTitle: customTitle,
        customDescription: customDescription,
        customConditionText: customConditionText,
        customEmoji: customEmoji,
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  State<LockedFeatureOverlay> createState() => _LockedFeatureOverlayState();
}

class _LockedFeatureOverlayState extends State<LockedFeatureOverlay> {
  @override
  Widget build(BuildContext context) {
    final gate = widget.feature != null
        ? ProgressionService.instance.gateFor(widget.feature!)
        : null;
    final isCharScreen = widget.feature == UnlockableFeature.characterScreen;

    final emoji =
        widget.customEmoji ?? gate?.emoji ?? (isCharScreen ? '🛡️' : '🔒');
    final title = widget.customTitle ??
        gate?.label ??
        (isCharScreen ? 'CHARACTER' : 'LOCKED');
    final description = widget.customDescription ??
        gate?.description ??
        (isCharScreen
            ? 'View and equip your roster'
            : 'This feature is currently locked.');

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            color: AppColors.paperWhite,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.ink, width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: AppColors.ink,
                offset: Offset(4, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                const Positioned.fill(child: NotebookBackground()),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 26),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _LockedBadge(),
                      const SizedBox(height: 14),
                      const Text(
                        '✦  FEATURE LOCKED  ✦',
                        style: TextStyle(
                          color: AppColors.sketchGray,
                          fontSize: 9,
                          letterSpacing: 4,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (emoji.isNotEmpty) ...[
                        Text(
                          emoji,
                          style: const TextStyle(fontSize: 28, height: 1.0),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        title.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Bangers',
                          fontSize: 24,
                          color: AppColors.ink,
                          letterSpacing: 3.5,
                          height: 1.0,
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.ink.withValues(alpha: 0.6),
                            fontSize: 11,
                            letterSpacing: 0.3,
                            height: 1.5,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      const Divider(color: Color(0xFFD0D0D0), thickness: 1),
                      const SizedBox(height: 14),
                      _UnlockConditionPill(
                        isCharScreen: isCharScreen,
                        requiredLevel: widget.requiredLevel,
                        currentLevel: widget.currentLevel,
                        customConditionText: widget.customConditionText,
                      ),
                      const SizedBox(height: 24),
                      AppComicButton(
                        label: 'GOT IT',
                        style: AppButtonStyle.dark,
                        fontSize: 16,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 48, vertical: 11),
                        onTap: widget.onDismiss,
                      ).animateButton(delay: 250.ms),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animateOverlay();
  }
}

class _LockedBadge extends StatelessWidget {
  const _LockedBadge();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        const CustomPaint(
          size: Size(110, 110),
          painter:
              _RayPainter(progress: 1.0, color: AppColors.comicYellow),
        ).animate(onPlay: (c) => c.repeat()).rotate(duration: 12.seconds),
        const CustomPaint(
          size: Size(86, 86),
          painter: _StarBurstPainter(color: AppColors.comicYellow),
        ).animate().scale(
              begin: const Offset(0.5, 0.5),
              duration: 380.ms,
              curve: Curves.elasticOut,
            ),
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.paperWhite,
            border: Border.all(color: AppColors.ink, width: 2.0),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.15),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Icon(Icons.lock_rounded, color: AppColors.ink, size: 26),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              begin: const Offset(0.94, 0.94),
              end: const Offset(1.06, 1.06),
              duration: 1200.ms,
              curve: Curves.easeInOut,
            )
            .shimmer(
              delay: 1800.ms,
              duration: 1.5.seconds,
              color: Colors.white24,
            ),
      ],
    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack);
  }
}

class _UnlockConditionPill extends StatelessWidget {
  const _UnlockConditionPill({
    required this.isCharScreen,
    this.requiredLevel,
    this.currentLevel,
    this.customConditionText,
  });

  final bool isCharScreen;
  final int? requiredLevel;
  final int? currentLevel;
  final String? customConditionText;

  @override
  Widget build(BuildContext context) {
    final String label;
    if (customConditionText != null) {
      label = customConditionText!;
    } else if (isCharScreen) {
      label = 'Play 2 games to unlock';
    } else if (requiredLevel != null) {
      label = 'Unlocks at Level $requiredLevel';
    } else {
      label = 'Locked';
    }

    final double? progress;
    if (customConditionText != null) {
      progress = null;
    } else if (isCharScreen) {
      progress = null;
    } else if (currentLevel != null &&
        requiredLevel != null &&
        requiredLevel! > 0) {
      progress = (currentLevel! / requiredLevel!).clamp(0.0, 1.0);
    } else {
      progress = null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
            color: AppColors.ink.withValues(alpha: 0.15), width: 1.2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isCharScreen ? Icons.sports_esports : Icons.lock_outline,
                color: AppColors.ink,
                size: 14,
              ),
              const SizedBox(width: 8),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Bangers',
                  fontSize: 16,
                  color: AppColors.ink,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: AppColors.ink.withValues(alpha: 0.10),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.ink),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Lv $currentLevel / $requiredLevel',
              style: TextStyle(
                color: AppColors.ink.withValues(alpha: 0.5),
                fontSize: 9,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
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
      final r = i.isEven ? 1.0 : innerR;
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
      final innerR = size.width * 0.34;
      final outerR = size.width * 0.50 * progress;
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
