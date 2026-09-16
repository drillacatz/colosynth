import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:colosynth/services/level_progress_service.dart';
import 'package:colosynth/screens/theme/tokens.dart';

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
      barrierColor: Colors.black87,
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

    final circleSize = (isWide ? 260.0 : 200.0) * 0.85;
    final circleTop = isWide ? 150.0 : 130.0;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onDismiss,
              child: const SizedBox.expand(),
            ),
          ),

          Positioned(
            right: isWide ? 60 : 16,
            top: circleTop,
            child: _LevelXPCircle(
              level: widget.level,
              progress: _xpProgress,
              xpInLevel: _xpInLevel,
              xpForNext: _xpForNext,
              size: circleSize,
            )
                .animate(delay: 300.ms)
                .fadeIn(duration: 300.ms)
                .scale(begin: const Offset(0.8, 0.8)),
          ),

          Positioned(
            right: isWide ? 50 : 12,
            top: circleTop + circleSize + 14,
            width: isWide ? 270 : math.min(size.width * 0.46, 210),
            child: _SelectedMilestoneChip(
              milestone: selectedMilestone,
              currentLevel: widget.level,
            )
                .animate(key: ValueKey(_selectedLevel), delay: 150.ms)
                .fadeIn(duration: 200.ms)
                .slideY(begin: 0.08, end: 0),
          ),

          Positioned(
            left: 0,
            top: 50,
            bottom: 30,
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
                              child: AnimatedContainer(
                                duration: 200.ms,
                                width: isSelected ? 68 : 58,
                                height: isSelected ? 68 : 58,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    if (isSelected)
                                      Container(
                                        width: 68,
                                        height: 68,
                                        decoration: BoxDecoration(
                                          color: AppColors.comicYellow,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.ink,
                                            width: 3.0,
                                          ),
                                        ),
                                      )
                                    else
                                      Container(
                                        width: 58,
                                        height: 58,
                                        decoration: BoxDecoration(
                                          color: isUnlocked
                                              ? AppColors.paperWhite
                                              : Colors.grey.shade800,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isUnlocked
                                                ? AppColors.ink
                                                : AppColors.ink.withValues(alpha: 0.4),
                                            width: 2.0,
                                          ),
                                        ),
                                      ),
                                    Text(
                                      '${milestone.level}',
                                      style: TextStyle(
                                        fontFamily: 'Bangers',
                                        fontSize: isSelected ? 23 : 19,
                                        color: isSelected
                                            ? AppColors.ink
                                            : (isUnlocked
                                                ? AppColors.ink
                                                : Colors.white60),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          )
              .animate(delay: 300.ms)
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.1, end: 0),
        ],
      ),
    );
  }
}

class _LevelXPCircle extends StatelessWidget {
  const _LevelXPCircle({
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
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size - 10,
            height: size - 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.comicYellow.withValues(alpha: 0.15),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          Container(
            width: size - 15,
            height: size - 15,
            decoration: BoxDecoration(
              color: AppColors.paperWhite,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.ink,
                width: 2.0,
              ),
            ),
          ),
          SizedBox(
            width: size - 25,
            height: size - 25,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 13.5,
              backgroundColor: AppColors.ink.withValues(alpha: 0.05),
              valueColor: const AlwaysStoppedAnimation(AppColors.comicYellow),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'LEVEL',
                style: TextStyle(
                  fontFamily: 'Bangers',
                  fontSize: size * 0.08,
                  color: AppColors.ink.withValues(alpha: 0.4),
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                '$level',
                style: TextStyle(
                  fontFamily: 'Bangers',
                  fontSize: size * 0.32,
                  color: AppColors.ink,
                  height: 0.9,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  level >= ProgressionService.maxLevel
                      ? 'MAX XP'
                      : '$xpInLevel / $xpForNext',
                  style: TextStyle(
                    fontFamily: 'Bangers',
                    fontSize: size * 0.07,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectedMilestoneChip extends StatelessWidget {
  const _SelectedMilestoneChip({
    required this.milestone,
    required this.currentLevel,
  });

  final MilestoneInfo milestone;
  final int currentLevel;

  @override
  Widget build(BuildContext context) {
    final isUnlocked = milestone.level <= currentLevel;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.paperWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.ink,
          width: 2.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.ink,
            offset: Offset(2, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'LEVEL ${milestone.level}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Bangers',
                    fontSize: 11,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isUnlocked ? Icons.check_circle : Icons.lock,
                    size: 13,
                    color: isUnlocked
                        ? AppColors.comicGreen
                        : AppColors.comicRed,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isUnlocked ? 'UNLOCKED' : 'LOCKED',
                    style: TextStyle(
                      fontFamily: 'Bangers',
                      fontSize: 10,
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
          const SizedBox(height: 8),
          Row(
            children: [
              if (milestone.emoji.isNotEmpty) ...[
                Text(
                  milestone.emoji,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  milestone.label.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Bangers',
                    fontSize: 13,
                    color: AppColors.ink,
                    letterSpacing: 0.5,
                    height: 1.1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (milestone.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              milestone.description,
              style: TextStyle(
                color: AppColors.ink.withValues(alpha: 0.65),
                fontSize: 10,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (milestone.hasRewards) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 5,
              runSpacing: 4,
              children: [
                if (milestone.ink > 0)
                  _RewardPill(
                    icon: Icons.water_drop,
                    amount: '${ProgressionService.fmtInk(milestone.ink)} INK',
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.ink, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: iconColor),
          const SizedBox(width: 3),
          Text(
            amount,
            style: const TextStyle(
              color: AppColors.ink,
              fontFamily: 'Bangers',
              fontSize: 9,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

