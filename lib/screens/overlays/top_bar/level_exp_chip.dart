import 'package:flutter/material.dart';
import 'package:colosynth/services/level_progress_service.dart';
import 'package:colosynth/screens/theme/shared_painters.dart';
import 'package:colosynth/screens/theme/tokens.dart';

class LevelExpChip extends StatefulWidget {
  const LevelExpChip({
    super.key,
    required this.level,
    required this.xp,
    this.onTap,
    this.animateGain = false,
  });

  final int level;
  final int xp;
  final VoidCallback? onTap;
  final bool animateGain;

  @override
  State<LevelExpChip> createState() => _LevelExpChipState();
}

class _LevelExpChipState extends State<LevelExpChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    if (widget.animateGain) {
      _animController.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(covariant LevelExpChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animateGain &&
        (!oldWidget.animateGain ||
            widget.xp != oldWidget.xp ||
            widget.level != oldWidget.level)) {
      _animController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  static const _ink = Color(0xFF1A1A1A);

  int get _xpInLevel {
    final cur = widget.xp - ProgressionService.xpForLevel(widget.level);
    return cur > 0 ? cur : 0;
  }

  int get _xpForNext {
    final gap = ProgressionService.xpForLevel(widget.level + 1) -
        ProgressionService.xpForLevel(widget.level);
    return gap > 0 ? gap : 1;
  }

  double get _progress {
    if (widget.level >= ProgressionService.maxLevel) return 1.0;
    return (_xpInLevel / _xpForNext).clamp(0.0, 1.0);
  }

  String get _xpText {
    if (widget.level >= ProgressionService.maxLevel) return 'MAX';
    return '$_xpInLevel/$_xpForNext';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;

    Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          painter: NotebookCardPainter(
            seed: 42,
            faceColor: _ink,
            shadowColor: const Color(0xFFD0C8C0),
            borderColor: _ink,
            borderWidth: 1.0,
            cornerRadius: 8,
            jitter: 0.8,
            segments: 3,
            showShadow: true,
            shadowOffset: const Offset(1, 1),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            child: Text(
              '${widget.level}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontFamily: 'Bangers',
                letterSpacing: 1,
                height: 1.0,
              ),
            ),
          ),
        ),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _xpText,
              style: TextStyle(
                color: _ink.withValues(alpha: 0.40),
                fontSize: 9,
                fontFamily: 'Bangers',
                letterSpacing: 0.5,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 3),
            SizedBox(
              width: 38,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 3,
                  backgroundColor: const Color(0xFFE0E0E0),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF1A1A1A)),
                ),
              ),
            ),
          ],
        ),
      ],
    );

    if (widget.onTap != null) {
      child = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          ComicButton.playButtonSfx();
          widget.onTap!();
        },
        child: child,
      );
    }

    if (widget.animateGain) {
      return ScaleTransition(
        scale: TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween(begin: 1.0, end: 1.18)
                .chain(CurveTween(curve: Curves.easeOut)),
            weight: 40,
          ),
          TweenSequenceItem(
            tween: Tween(begin: 1.18, end: 1.0)
                .chain(CurveTween(curve: Curves.elasticOut)),
            weight: 60,
          ),
        ]).animate(_animController),
        child: child,
      );
    }

    return child;
  }
}
