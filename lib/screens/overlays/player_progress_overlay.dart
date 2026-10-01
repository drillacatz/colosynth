import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:colosynth/services/level_progress_service.dart';
import 'package:colosynth/screens/theme/tokens.dart';
import 'package:colosynth/widgets/comic/comic_word_badge.dart';
import 'package:colosynth/widgets/comic/zzz_extruded_banner.dart';

class MilestoneInfo {
  final int level;
  final String emoji;
  final String label;
  final String description;
  final int ink;
  final int paint;
  final int hammer;
  final int note;
  final int book;

  const MilestoneInfo({
    required this.level,
    required this.emoji,
    required this.label,
    required this.description,
    this.ink = 0,
    this.paint = 0,
    this.hammer = 0,
    this.note = 0,
    this.book = 0,
  });

  bool get hasRewards =>
      ink > 0 || paint > 0 || hammer > 0 || note > 0 || book > 0;
}

class PlayerProgressOverlay extends StatefulWidget {
  const PlayerProgressOverlay({
    super.key,
    required this.level,
    required this.xp,
    required this.onDismiss,
  });

  final int level;
  final int xp;
  final VoidCallback onDismiss;

  static Future<void> show(
    BuildContext context, {
    required int level,
    required int xp,
  }) {
    HapticFeedback.lightImpact();
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: const Color(0xD0000000),
      builder: (ctx) => PlayerProgressOverlay(
        level: level,
        xp: xp,
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  State<PlayerProgressOverlay> createState() => _PlayerProgressOverlayState();
}

class _PlayerProgressOverlayState extends State<PlayerProgressOverlay> {
  late final List<MilestoneInfo> _milestones;
  late int _selectedLevel;
  late final ScrollController _scrollController;
  bool _hasEntered = false;

  static List<MilestoneInfo> getMilestones() {
    final Map<int, List<Object>> groups = {};
    for (final g in ProgressionService.gates) {
      groups.putIfAbsent(g.requiredLevel, () => []).add(g);
    }
    for (final m in ProgressionService.milestones) {
      groups.putIfAbsent(m.level, () => []).add(m);
    }

    final sortedLevels = groups.keys.toList()..sort();
    return sortedLevels.map((lv) {
      final items = groups[lv]!;
      String label = '';
      String description = '';
      String emoji = '';
      int ink = 0;
      int paint = 0;
      int hammer = 0;
      int note = 0;
      int book = 0;

      final gates = items.whereType<UnlockGate>().toList();
      final milestones = items.whereType<RewardMilestone>().toList();

      if (gates.isNotEmpty) {
        label = gates.map((g) => g.label).join(' & ');
        description = gates.map((g) => g.description).join('\n');
        emoji = gates.first.emoji;
      } else {
        label = 'LEVEL REWARD';
        description = 'Obtain milestone level rewards';
        if (milestones.isNotEmpty) {
          emoji = milestones.first.emoji;
        } else {
          emoji = '🎁';
        }
      }

      for (final g in gates) {
        ink += g.inkReward;
        paint += g.paintReward;
        hammer += g.hammerReward;
        note += g.noteReward;
        book += g.bookReward;
      }
      for (final m in milestones) {
        ink += m.inkReward;
        paint += m.paintReward;
        hammer += m.hammerReward;
        note += m.noteReward;
        book += m.bookReward;
      }

      return MilestoneInfo(
        level: lv,
        emoji: emoji,
        label: label,
        description: description,
        ink: ink,
        paint: paint,
        hammer: hammer,
        note: note,
        book: book,
      );
    }).toList();
  }

  int getInitialSelectedIndex(List<MilestoneInfo> milestones, int playerLevel) {
    for (int i = 0; i < milestones.length; i++) {
      if (milestones[i].level > playerLevel) {
        return i;
      }
    }
    return milestones.length - 1;
  }

  @override
  void initState() {
    super.initState();
    _milestones = getMilestones();
    final initialIdx = getInitialSelectedIndex(_milestones, widget.level);
    _selectedLevel = _milestones[initialIdx].level;
    _scrollController = ScrollController()..addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final targetOffset = _getOffsetForIndex(initialIdx);
        _scrollController.animateTo(
          targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
      }
    });

    Future.delayed(const Duration(milliseconds: 480), () {
      if (mounted) {
        setState(() => _hasEntered = true);
      }
    });
  }

  void _onScroll() {
    if (!mounted) return;
    final offset = _scrollController.offset;
    const double itemWidth = 100.0;

    int index = (offset / itemWidth).round();
    index = index.clamp(0, _milestones.length - 1);

    final targetLevel = _milestones[index].level;
    if (_selectedLevel != targetLevel) {
      setState(() {
        _selectedLevel = targetLevel;
      });
      HapticFeedback.selectionClick();
    }
  }

  double _getOffsetForIndex(int index) {
    const double itemWidth = 100.0;
    return index * itemWidth;
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  int get _xpInLevel => widget.xp - ProgressionService.xpForLevel(widget.level);
  int get _xpForNext {
    final gap = ProgressionService.xpForLevel(widget.level + 1) -
        ProgressionService.xpForLevel(widget.level);
    return gap > 0 ? gap : 1;
  }

  double get _xpProgress {
    if (widget.level >= ProgressionService.maxLevel) return 1.0;
    return (_xpInLevel / _xpForNext).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;
    final selectedMilestone = _milestones.firstWhere(
      (m) => m.level == _selectedLevel,
      orElse: () => _milestones.first,
    );

    final splatterSize = isWide ? 190.0 : 150.0;
    final contentTop = (isWide ? 120.0 : 90.0) + 80.0;
    final baseWidth = isWide ? 380.0 : math.min(size.width * 0.88, 340.0);
    final baseHeight = isWide ? 310.0 : math.min(size.height * 0.42, 290.0);
    // 40% smaller footprint (~60% of original)
    final boxWidth = math.max(215.0, baseWidth * 0.60);
    final boxHeight = math.max(175.0, baseHeight * 0.60);

    return Material(
      color: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // 1. Full-screen dismiss on tapping empty space
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onDismiss,
              child: const SizedBox.expand(),
            ),
          ),

          // 2. ZZZ 3D Extruded Moving Text Banner (Angled at -30 deg across background)
          Positioned(
            left: -250,
            right: -250,
            top: size.height * 0.40,
            child: Transform.rotate(
              angle: -30 * math.pi / 180,
              alignment: Alignment.center,
              child: const IgnorePointer(
                child: _ZzzExtrudedTextBanner(),
              ),
            ),
          ),

          // 3. Deco Stroke 1 (Parallel to roadmap, -30 deg)
          Positioned(
            left: -20,
            top: -100,
            bottom: -100,
            width: isWide ? 320 : size.width * 0.52,
            child: Transform.rotate(
              angle: -30 * math.pi / 180,
              alignment: Alignment.center,
              child: const IgnorePointer(
                child: CustomPaint(
                  painter: _ParallelDecoStrokePainter(),
                ),
              )
                  .animate()
                  .fadeIn(duration: 200.ms)
                  .slide(
                    begin: const Offset(-1.2, -1.0),
                    end: Offset.zero,
                    duration: 420.ms,
                    curve: Curves.easeOutCubic,
                  ),
            ),
          ),

          // 4. Deco Stroke 2 (Perpendicular at 90 deg relative to roadmap, +60 deg)
          Positioned(
            left: -20,
            top: -100,
            bottom: -100,
            width: isWide ? 320 : size.width * 0.52,
            child: Transform.rotate(
              angle: 60 * math.pi / 180,
              alignment: Alignment.center,
              child: const IgnorePointer(
                child: CustomPaint(
                  painter: _PerpendicularDecoStrokePainter(),
                ),
              )
                  .animate()
                  .fadeIn(duration: 200.ms)
                  .slide(
                    begin: const Offset(1.2, -1.0),
                    end: Offset.zero,
                    duration: 420.ms,
                    curve: Curves.easeOutCubic,
                  ),
            ),
          ),

          // 5. Roadmap milestone track
          Positioned(
            left: -20,
            top: -100,
            bottom: -100,
            width: isWide ? 320 : size.width * 0.52,
            child: Transform.rotate(
              angle: -30 * math.pi / 180,
              alignment: Alignment.center,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final viewportHeight = constraints.maxHeight;
                  final sidePadding = viewportHeight / 2 - 50.0;
                  return ListView.builder(
                    scrollDirection: Axis.vertical,
                    reverse: true,
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    itemCount: _milestones.length,
                    itemExtent: 100.0,
                    padding: EdgeInsets.symmetric(vertical: sidePadding),
                    itemBuilder: (context, index) {
                      final milestone = _milestones[index];
                      final isUnlocked = milestone.level <= widget.level;
                      final isSelected = milestone.level == _selectedLevel;

                      final isAboveUnlocked = index < _milestones.length - 1 &&
                          _milestones[index + 1].level <= widget.level;

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          if (index < _milestones.length - 1)
                            Positioned(
                              top: 0,
                              bottom: 50,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  width: 3.5,
                                  color: isAboveUnlocked
                                      ? AppColors.comicYellow
                                      : AppColors.ink.withValues(alpha: 0.25),
                                ),
                              ),
                            ),

                          if (index > 0)
                            Positioned(
                              top: 50,
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  width: 3.5,
                                  color: isUnlocked
                                      ? AppColors.comicYellow
                                      : AppColors.ink.withValues(alpha: 0.25),
                                ),
                              ),
                            ),

                          Center(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                final targetOffset = _getOffsetForIndex(index);
                                _scrollController.animateTo(
                                  targetOffset.clamp(
                                      0.0, _scrollController.position.maxScrollExtent),
                                  duration: const Duration(milliseconds: 350),
                                  curve: Curves.easeOutCubic,
                                );
                              },
                              child: SizedBox(
                                width: 70,
                                height: 70,
                                child: Center(
                                  child: AnimatedDefaultTextStyle(
                                    duration: 200.ms,
                                    curve: Curves.easeOutCubic,
                                    style: TextStyle(
                                      fontFamily: 'Bangers',
                                      fontSize: isSelected ? 40 : (isUnlocked ? 30 : 26),
                                      letterSpacing: 1.0,
                                      color: isSelected
                                          ? AppColors.comicYellow
                                          : (isUnlocked
                                              ? Colors.white
                                              : Colors.white38),
                                      shadows: [
                                        Shadow(
                                          color: AppColors.ink.withValues(
                                              alpha: isSelected ? 0.9 : 0.6),
                                          offset: const Offset(2.0, 2.0),
                                          blurRadius: isSelected ? 4.0 : 2.0,
                                        ),
                                        if (isSelected)
                                          Shadow(
                                            color: AppColors.primaryAccent
                                                .withValues(alpha: 0.6),
                                            offset: const Offset(-1.0, -1.0),
                                            blurRadius: 3.0,
                                          ),
                                      ],
                                    ),
                                    child: Text('${milestone.level}'),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              )
                  .animate()
                  .fadeIn(duration: 200.ms)
                  .slide(
                    begin: const Offset(-0.8, 1.2),
                    end: Offset.zero,
                    duration: 420.ms,
                    curve: Curves.easeOutCubic,
                  ),
            ),
          ),

          // 6. Selected Milestone Card (Right-Angled Manga Trapezoid, 40% smaller)
          Positioned(
            left: 0,
            bottom: 0,
            width: boxWidth,
            height: boxHeight,
            child: _SelectedMilestoneChip(
              milestone: selectedMilestone,
              currentLevel: widget.level,
              width: boxWidth,
              height: boxHeight,
            )
                .animate(
                  key: ValueKey(_selectedLevel),
                  delay: _hasEntered ? Duration.zero : 380.ms,
                )
                .fadeIn(duration: 220.ms)
                .scale(
                  begin: const Offset(0.25, 0.25),
                  end: const Offset(1.0, 1.0),
                  duration: _hasEntered ? 250.ms : 420.ms,
                  curve: Curves.easeOutBack,
                ),
          ),

          // 7. Player Level & XP Splatter (Bouncy Pop-and-Snap)
          Positioned(
            right: isWide ? 60 : 16,
            top: contentTop,
            child: _LevelXPSplatter(
              level: widget.level,
              progress: _xpProgress,
              xpInLevel: _xpInLevel,
              xpForNext: _xpForNext,
              size: splatterSize,
            )
                .animate(delay: 380.ms)
                .fadeIn(duration: 220.ms)
                .scale(
                  begin: const Offset(0.2, 0.2),
                  end: const Offset(1.0, 1.0),
                  duration: 420.ms,
                  curve: Curves.easeOutBack,
                ),
          ),
        ],
      ),
    );
  }
}

class _LevelXPSplatter extends StatelessWidget {
  const _LevelXPSplatter({
    required this.level,
    required this.progress,
    required this.xpInLevel,
    required this.xpForNext,
    required this.size,
  });

  final int level;
  final double progress;
  final int xpInLevel;
  final int xpForNext;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ComicWordBadge(
          text: 'LV.$level',
          fontSize: size * 0.39,
          style: ComicBadgeStyle.flameOrange,
          backdropType: ComicBackdropType.cloud,
          isAnimated: true,
          showTrailingBubbles: false,
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: size * 0.85,
          child: Column(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.ink, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.ink,
                      offset: Offset(1.5, 1.5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress.clamp(0.0, 1.0),
                        child: Container(
                          color: AppColors.comicYellow,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                level >= ProgressionService.maxLevel
                    ? 'MAX XP'
                    : '$xpInLevel / $xpForNext XP',
                style: const TextStyle(
                  fontFamily: 'Bangers',
                  fontSize: 11,
                  letterSpacing: 1.0,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MangaTrapezoidClipper extends CustomClipper<Path> {
  const _MangaTrapezoidClipper();

  @override
  Path getClip(Size size) {
    final topCutX = size.width * 0.58;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(topCutX, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _MangaTrapezoidPainter extends CustomPainter {
  const _MangaTrapezoidPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final topCutX = size.width * 0.58;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(topCutX, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final shadowPaint = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(path.shift(const Offset(3.0, 3.0)), shadowPaint);

    final fillPaint = Paint()
      ..color = AppColors.paperWhite
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    final strokePaint = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawLine(Offset.zero, Offset(topCutX, 0), strokePaint);
    canvas.drawLine(Offset(topCutX, 0), Offset(size.width, size.height), strokePaint);
    canvas.drawLine(Offset(size.width, size.height), Offset(0, size.height), strokePaint);
    canvas.drawLine(Offset(0, size.height), Offset.zero, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SelectedMilestoneChip extends StatelessWidget {
  const _SelectedMilestoneChip({
    required this.milestone,
    required this.currentLevel,
    required this.width,
    required this.height,
  });

  final MilestoneInfo milestone;
  final int currentLevel;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isUnlocked = milestone.level <= currentLevel;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return CustomPaint(
      painter: const _MangaTrapezoidPainter(),
      child: ClipPath(
        clipper: const _MangaTrapezoidClipper(),
        child: SizedBox(
          width: width,
          height: height,
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: EdgeInsets.only(
                left: 10,
                bottom: 8 + bottomPadding * 0.3,
                right: width * 0.22,
                top: 8,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.ink,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'LEVEL ${milestone.level}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Bangers',
                              fontSize: 10,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isUnlocked ? Icons.check_circle : Icons.lock,
                              size: 11,
                              color: isUnlocked
                                  ? AppColors.comicGreen
                                  : AppColors.comicRed,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              isUnlocked ? 'UNLOCKED' : 'LOCKED',
                              style: TextStyle(
                                fontFamily: 'Bangers',
                                fontSize: 9,
                                letterSpacing: 0.5,
                                color: isUnlocked
                                    ? AppColors.comicGreen
                                    : AppColors.comicRed,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (milestone.emoji.isNotEmpty) ...[
                          Text(
                            milestone.emoji,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            milestone.label.toUpperCase(),
                            style: const TextStyle(
                              fontFamily: 'Bangers',
                              fontSize: 11.5,
                              color: AppColors.ink,
                              letterSpacing: 0.4,
                              height: 1.05,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (milestone.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        milestone.description,
                        style: TextStyle(
                          color: AppColors.ink.withValues(alpha: 0.7),
                          fontSize: 8.5,
                          height: 1.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (milestone.hasRewards) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 3,
                        runSpacing: 2,
                        children: [
                          if (milestone.ink > 0)
                            _RewardPill(
                              icon: Icons.water_drop,
                              amount:
                                  '${ProgressionService.fmtInk(milestone.ink)} INK',
                              backgroundColor: const Color(0xFFE3F2FD),
                              iconColor: const Color(0xFF1565C0),
                            ),
                          if (milestone.paint > 0)
                            _RewardPill(
                              icon: Icons.brush,
                              amount: '${milestone.paint} PAINT',
                              backgroundColor: const Color(0xFFFCE4EC),
                              iconColor: const Color(0xFFE91E63),
                            ),
                          if (milestone.hammer > 0)
                            _RewardPill(
                              icon: Icons.construction,
                              amount: '${milestone.hammer} HAMMER',
                              backgroundColor: const Color(0xFFFFF8E1),
                              iconColor: const Color(0xFFFFB300),
                            ),
                          if (milestone.note > 0)
                            _RewardPill(
                              icon: Icons.music_note,
                              amount: '${milestone.note} NOTE',
                              backgroundColor: const Color(0xFFF3E5F5),
                              iconColor: const Color(0xFF8E24AA),
                            ),
                          if (milestone.book > 0)
                            _RewardPill(
                              icon: Icons.book,
                              amount: '${milestone.book} BOOK',
                              backgroundColor: const Color(0xFFEFEBE9),
                              iconColor: const Color(0xFF5D4037),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RewardPill extends StatelessWidget {
  const _RewardPill({
    required this.icon,
    required this.amount,
    required this.backgroundColor,
    required this.iconColor,
  });

  final IconData icon;
  final String amount;
  final Color backgroundColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.ink, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 8, color: iconColor),
          const SizedBox(width: 2.5),
          Text(
            amount,
            style: const TextStyle(
              color: AppColors.ink,
              fontFamily: 'Bangers',
              fontSize: 8,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParallelDecoStrokePainter extends CustomPainter {
  const _ParallelDecoStrokePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double roadmapCenterX = size.width / 2;
    final double strokeX = roadmapCenterX + 100.0;

    final paint = Paint()
      ..color = AppColors.comicYellow.withValues(alpha: 0.35)
      ..strokeWidth = 30.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(strokeX, -200),
      Offset(strokeX, size.height + 200),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PerpendicularDecoStrokePainter extends CustomPainter {
  const _PerpendicularDecoStrokePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double roadmapCenterX = size.width / 2;
    final double strokeX = roadmapCenterX + 60.0;

    final paint = Paint()
      ..color = AppColors.comicYellow.withValues(alpha: 0.35)
      ..strokeWidth = 30.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(strokeX, -300),
      Offset(strokeX, size.height + 300),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Zenless Zone Zero (ZZZ) Style 3D Extruded Flat Moving Text Banner.
///
/// Features:
/// - High-contrast Caution Yellow ribbon with black hazard border lines.
/// - 3D extruded flat typography using multi-layered solid isometric vector shadows.
/// - Two-phase motion: High-speed rush slide-in (0–400ms) decelerating smoothly
///   into an infinite, seamless slow-scrolling marquee ticker (~35dp/sec).
class _ZzzExtrudedTextBanner extends StatelessWidget {
  const _ZzzExtrudedTextBanner();

  static const String _tickerUnit =
      '/// PLAYER ROADMAP // LEVEL PROGRESSION // MILESTONE ARCHIVE ///   ';

  @override
  Widget build(BuildContext context) {
    return const ZzzTickerBanner(
      text: _tickerUnit,
      fontSize: 17.0,
      textColor: Colors.white,
      shadowColor: Color(0xFF1A1A1A),
      bannerColor: Color(0xFFFFD500),
      height: 38.0,
      reverse: false,
      crawlSpeed: 35.0,
      hasEntranceRush: true,
    );
  }
}

