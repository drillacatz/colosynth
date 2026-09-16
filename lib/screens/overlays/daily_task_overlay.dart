import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colosynth/services/daily_task_service.dart';
import 'package:colosynth/screens/theme/tokens.dart';
import 'package:colosynth/screens/theme/background.dart';
import 'package:colosynth/screens/overlays/claim_reward_overlay.dart';
import 'package:colosynth/screens/theme/shared_painters.dart';
import 'package:colosynth/providers/navigation_provider.dart';
import 'package:colosynth/game_data/store_data.dart';
import 'package:colosynth/providers/store_provider.dart';

class DailyTaskOverlay extends ConsumerStatefulWidget {
  const DailyTaskOverlay({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => const DailyTaskOverlay(),
    );
  }

  @override
  ConsumerState<DailyTaskOverlay> createState() => _DailyTaskOverlayState();
}

class _DailyTaskOverlayState extends ConsumerState<DailyTaskOverlay> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final maxHeight = size.height * 0.85;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: maxHeight,
        ),
        decoration: BoxDecoration(
          color: AppColors.paperWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.ink, width: 3.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.4),
              blurRadius: 0,
              offset: const Offset(6, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: const Stack(
            children: [
              Positioned.fill(child: NotebookBackground()),
              _DialogContent(),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogContent extends ConsumerStatefulWidget {
  const _DialogContent();

  @override
  ConsumerState<_DialogContent> createState() => _DialogContentState();
}

class _DialogContentState extends ConsumerState<_DialogContent> {
  @override
  void initState() {
    super.initState();
    if (!DailyTaskService.instance.initialized) {
      unawaited(DailyTaskService.instance.init());
    }
  }

  Future<void> _onClaimTask(DailyTask task, DailyTaskService service) async {
    if (!service.isCompleted(task.id) || service.isClaimed(task.id)) return;
    ComicButton.playButtonSfx();
    unawaited(HapticFeedback.mediumImpact());

    await service.claimTask(task.id);
    if (!mounted) return;

    if (task.inkReward > 0 || task.paintReward > 0) {
      await ClaimRewardOverlay.show(
        context,
        inkReward: task.inkReward,
        paintReward: task.paintReward,
      );
    }
  }

  Future<void> _onClaimMilestone(int threshold, DailyTaskService service) async {
    if (!service.isMilestoneReached(threshold) ||
        service.isMilestoneClaimed(threshold)) {
      return;
    }
    ComicButton.playButtonSfx();
    unawaited(HapticFeedback.lightImpact());

    final reward = DailyTaskService.milestones[threshold] ?? {};
    final inkAmt = (reward['ink'] as num?)?.toInt() ?? 0;
    final paintAmt = (reward['paint'] as num?)?.toInt() ?? 0;
    final item = reward['item'] as String?;
    final xpAmt = (reward['xp'] as num?)?.toInt() ?? 0;

    await service.claimMilestone(threshold);
    if (!mounted) return;

    await ClaimRewardOverlay.show(
      context,
      inkReward: inkAmt,
      paintReward: paintAmt,
      xpReward: xpAmt,
      expItems: item != null ? {item: 1} : const {},
    );
  }

  Future<void> _onClaimWeeklyMilestone(
      int threshold, DailyTaskService service) async {
    if (service.weeklyPoints < threshold) return;
    if (threshold == 400 && service.milestone400Claimed) return;
    if (threshold == 800 && service.milestone800Claimed) return;

    ComicButton.playButtonSfx();
    unawaited(HapticFeedback.mediumImpact());

    await service.claimWeeklyMilestone(threshold);
    if (!mounted) return;

    if (threshold == 400) {
      await ClaimRewardOverlay.show(
        context,
        inkReward: 0,
        paintReward: 10,
        expItems: const {'exp_hammer_common': 3},
      );
    } else if (threshold == 800) {
      await ClaimRewardOverlay.show(
        context,
        inkReward: 0,
        paintReward: 10,
        expItems: const {'exp_book_common': 2},
      );
    }
  }

  Future<void> _onClaimAll(DailyTaskService service) async {
    ComicButton.playButtonSfx();
    unawaited(HapticFeedback.heavyImpact());

    final summary = await service.claimAll();
    if (!mounted) return;

    if (summary.ink > 0 ||
        summary.paint > 0 ||
        summary.xp > 0 ||
        summary.items.isNotEmpty) {
      await ClaimRewardOverlay.show(
        context,
        inkReward: summary.ink,
        paintReward: summary.paint,
        xpReward: summary.xp,
        expItems: summary.items,
      );
    }
  }

  void _onNavigateTask(String taskId) {
    ComicButton.playButtonSfx();
    Navigator.of(context).pop();

    int targetTab = NavigationNotifier.arenaIndex;
    if (taskId == 'claim_daily_ink') {
      ref.read(storeSectionProvider.notifier).setSection(StoreSection.daily);
      targetTab = 0;
    } else if (taskId.contains('upgrade') ||
        taskId.contains('char') ||
        taskId.contains('equip') ||
        taskId.contains('scholar') ||
        taskId.contains('smith')) {
      targetTab = 1;
    } else {
      targetTab = 2;
    }

    ref.read(navigationProvider.notifier).selectTab(targetTab);
  }

  IconData _getTaskIcon(String taskId) {
    if (taskId == 'claim_daily_ink') return Icons.water_drop;
    if (taskId.contains('parry')) return Icons.shield_outlined;
    if (taskId.contains('skill')) return Icons.auto_awesome;
    if (taskId.contains('dodge')) return Icons.directions_run;
    if (taskId.contains('battle') || taskId.contains('win')) {
      return Icons.military_tech;
    }
    if (taskId.contains('upgrade_equip') || taskId.contains('equip')) {
      return Icons.handyman_outlined;
    }
    if (taskId.contains('upgrade_char') || taskId.contains('char')) {
      return Icons.menu_book_outlined;
    }
    if (taskId.contains('tournament')) return Icons.emoji_events;
    return Icons.task_alt;
  }

  Color _getTaskColor(String taskId) {
    if (taskId == 'claim_daily_ink') return const Color(0xFF2196F3);
    if (taskId.contains('parry')) return const Color(0xFF00E5FF);
    if (taskId.contains('skill')) return const Color(0xFFAB47BC);
    if (taskId.contains('dodge')) return const Color(0xFFFFB300);
    if (taskId.contains('battle') || taskId.contains('win')) {
      return const Color(0xFFFF5252);
    }
    if (taskId.contains('upgrade_equip') || taskId.contains('equip')) {
      return const Color(0xFF26A69A);
    }
    if (taskId.contains('upgrade_char') || taskId.contains('char')) {
      return const Color(0xFFFF7043);
    }
    return AppColors.ink;
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(dailyTaskNotifierProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Header(
          hasClaimable: service.hasAnyClaimable,
          onClaimAll: () => _onClaimAll(service),
          onClose: () {
            ComicButton.playButtonSfx();
            Navigator.of(context).pop();
          },
        ),
        if (service.initialized) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: _DailyActivityTracker(
              activity: service.activity,
              onClaimMilestone: (th) => _onClaimMilestone(th, service),
              isMilestoneReached: service.isMilestoneReached,
              isMilestoneClaimed: service.isMilestoneClaimed,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: _WeeklyActivityTracker(
              weeklyPoints: service.weeklyPoints,
              milestone400Claimed: service.milestone400Claimed,
              milestone800Claimed: service.milestone800Claimed,
              onClaimMilestone: (th) => _onClaimWeeklyMilestone(th, service),
            ),
          ),
          Expanded(
            child: _TaskList(
              service: service,
              getIcon: _getTaskIcon,
              getColor: _getTaskColor,
              onClaim: (task) => _onClaimTask(task, service),
              onNavigate: _onNavigateTask,
            ),
          ),
        ] else
          const SizedBox(
            height: 160,
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.ink,
                strokeWidth: 3,
              ),
            ),
          ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.hasClaimable,
    required this.onClaimAll,
    required this.onClose,
  });

  final bool hasClaimable;
  final VoidCallback onClaimAll;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr =
        '${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.ink, width: 2.2)),
      ),
      child: Row(
        children: [
          const Text(
            'DAILY TASKS',
            style: TextStyle(
              fontFamily: 'Bangers',
              fontSize: 24,
              letterSpacing: 2.5,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.paperWhite,
              border: Border.all(color: AppColors.ink, width: 1.5),
              borderRadius: BorderRadius.circular(4),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.ink,
                  offset: Offset(1.5, 1.5),
                ),
              ],
            ),
            child: Text(
              dateStr,
              style: const TextStyle(
                fontFamily: 'Bangers',
                color: AppColors.ink,
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
          ),
          const Spacer(),
          if (hasClaimable) ...[
            _ClaimAllButton(onTap: onClaimAll),
            const SizedBox(width: 10),
          ],
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.paperWhite,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.ink, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.ink,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.close, color: AppColors.ink, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClaimAllButton extends StatefulWidget {
  const _ClaimAllButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_ClaimAllButton> createState() => _ClaimAllButtonState();
}

class _ClaimAllButtonState extends State<_ClaimAllButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 60),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF00E676),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.ink, width: 2),
            boxShadow: const [
              BoxShadow(
                color: AppColors.ink,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt, color: AppColors.ink, size: 14),
              SizedBox(width: 3),
              Text(
                'CLAIM ALL',
                style: TextStyle(
                  fontFamily: 'Bangers',
                  fontSize: 12,
                  letterSpacing: 1.2,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.04, 1.04),
          duration: 900.ms,
          curve: Curves.easeInOut,
        );
  }
}

class _DailyActivityTracker extends StatelessWidget {
  const _DailyActivityTracker({
    required this.activity,
    required this.onClaimMilestone,
    required this.isMilestoneReached,
    required this.isMilestoneClaimed,
  });

  final int activity;
  final Future<void> Function(int) onClaimMilestone;
  final bool Function(int) isMilestoneReached;
  final bool Function(int) isMilestoneClaimed;

  @override
  Widget build(BuildContext context) {
    final clampedActivity = activity.clamp(0, 100);
    final fillRatio = clampedActivity / 100.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.paperWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.ink, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.ink,
            offset: Offset(2.5, 2.5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt, size: 16, color: Color(0xFFFFB300)),
              const SizedBox(width: 4),
              const Text(
                'DAILY ACTIVITY',
                style: TextStyle(
                  fontFamily: 'Bangers',
                  fontSize: 13,
                  letterSpacing: 1.5,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$activity',
                      style: const TextStyle(
                        fontFamily: 'Bangers',
                        fontSize: 16,
                        letterSpacing: 1,
                        color: Color(0xFF00B0FF),
                      ),
                    ),
                    const TextSpan(
                      text: ' / 100 AP',
                      style: TextStyle(
                        fontFamily: 'Bangers',
                        fontSize: 12,
                        letterSpacing: 0.8,
                        color: Color(0xFF777777),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final trackWidth = constraints.maxWidth;
              const barHeight = 10.0;

              return SizedBox(
                height: 52,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Background track
                    Positioned(
                      top: 20,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEEEEE),
                          borderRadius: BorderRadius.circular(barHeight / 2),
                          border: Border.all(color: AppColors.ink, width: 1.5),
                        ),
                      ),
                    ),
                    // Animated Fill
                    Positioned(
                      top: 20,
                      left: 0,
                      child: Container(
                        height: barHeight,
                        width: trackWidth * fillRatio,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF),
                          borderRadius: BorderRadius.circular(barHeight / 2),
                          border: Border.all(color: AppColors.ink, width: 1.5),
                        ),
                      )
                          .animate(target: fillRatio)
                          .custom(
                            duration: 500.ms,
                            curve: Curves.easeOutCubic,
                            builder: (_, val, child) => SizedBox(
                              height: barHeight,
                              width: trackWidth * val,
                              child: child,
                            ),
                          ),
                    ),
                    // Milestone Nodes (30, 60, 100)
                    for (final th in DailyTaskService.milestoneThresholds) ...[
                      _buildMilestoneNode(
                        threshold: th,
                        trackWidth: trackWidth,
                        reached: isMilestoneReached(th),
                        claimed: isMilestoneClaimed(th),
                        onClaim: () => onClaimMilestone(th),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneNode({
    required int threshold,
    required double trackWidth,
    required bool reached,
    required bool claimed,
    required VoidCallback onClaim,
  }) {
    const nodeWidth = 46.0;
    final ratio = threshold / 100.0;
    final leftPos = (trackWidth * ratio - (nodeWidth / 2)).clamp(
      0.0,
      trackWidth - nodeWidth,
    );

    String label = '';
    IconData icon = Icons.card_giftcard;
    if (threshold == 30) {
      label = 'HAMMER';
      icon = Icons.gavel;
    } else if (threshold == 60) {
      label = 'BOOK';
      icon = Icons.menu_book;
    } else {
      label = '5P+XP';
      icon = Icons.stars;
    }

    final Color bgColor = claimed
        ? const Color(0xFFC8E6C9)
        : reached
            ? const Color(0xFFFFD54F)
            : AppColors.paperWhite;

    final Color borderColor = claimed
        ? const Color(0xFF2E7D32)
        : reached
            ? AppColors.ink
            : const Color(0xFF888888);

    return Positioned(
      left: leftPos,
      top: 0,
      child: GestureDetector(
        onTap: (reached && !claimed) ? onClaim : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: nodeWidth,
              padding: const EdgeInsets.symmetric(vertical: 2.5),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: borderColor, width: 1.8),
                boxShadow: reached && !claimed
                    ? const [
                        BoxShadow(
                          color: AppColors.ink,
                          offset: Offset(1.5, 1.5),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    claimed ? Icons.check : icon,
                    size: 13,
                    color: claimed ? const Color(0xFF2E7D32) : AppColors.ink,
                  ),
                  Text(
                    claimed
                        ? 'DONE'
                        : reached
                            ? 'CLAIM'
                            : '$threshold AP',
                    style: TextStyle(
                      fontFamily: 'Bangers',
                      fontSize: 8.5,
                      letterSpacing: 0.5,
                      color: claimed ? const Color(0xFF2E7D32) : AppColors.ink,
                      fontWeight:
                          reached && !claimed ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: Color(0xFF555555),
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyActivityTracker extends StatelessWidget {
  const _WeeklyActivityTracker({
    required this.weeklyPoints,
    required this.milestone400Claimed,
    required this.milestone800Claimed,
    required this.onClaimMilestone,
  });

  final int weeklyPoints;
  final bool milestone400Claimed;
  final bool milestone800Claimed;
  final Future<void> Function(int) onClaimMilestone;

  @override
  Widget build(BuildContext context) {
    final fillRatio = (weeklyPoints / 800.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.ink, width: 1.6),
        boxShadow: const [
          BoxShadow(
            color: AppColors.ink,
            offset: Offset(1.5, 1.5),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.date_range, size: 14, color: AppColors.ink),
          const SizedBox(width: 5),
          Text(
            'WEEKLY: $weeklyPoints/800 AP',
            style: const TextStyle(
              fontFamily: 'Bangers',
              fontSize: 11,
              letterSpacing: 0.8,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: fillRatio,
                minHeight: 6,
                backgroundColor: const Color(0xFFDDDDDD),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFFFFB300)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildWeeklyNode(
            threshold: 400,
            reached: weeklyPoints >= 400,
            claimed: milestone400Claimed,
            rewardText: '10P+3🔨',
            onTap: () => onClaimMilestone(400),
          ),
          const SizedBox(width: 5),
          _buildWeeklyNode(
            threshold: 800,
            reached: weeklyPoints >= 800,
            claimed: milestone800Claimed,
            rewardText: '10P+2📖',
            onTap: () => onClaimMilestone(800),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyNode({
    required int threshold,
    required bool reached,
    required bool claimed,
    required String rewardText,
    required VoidCallback onTap,
  }) {
    final Color bgColor = claimed
        ? const Color(0xFFC8E6C9)
        : reached
            ? const Color(0xFFFFD54F)
            : AppColors.paperWhite;

    return GestureDetector(
      onTap: (reached && !claimed) ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.ink, width: 1.2),
          boxShadow: reached && !claimed
              ? const [
                  BoxShadow(
                    color: AppColors.ink,
                    offset: Offset(1, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (claimed)
              const Icon(Icons.check, size: 9, color: Color(0xFF2E7D32))
            else
              Text(
                rewardText,
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  const _TaskList({
    required this.service,
    required this.getIcon,
    required this.getColor,
    required this.onClaim,
    required this.onNavigate,
  });

  final DailyTaskService service;
  final IconData Function(String) getIcon;
  final Color Function(String) getColor;
  final Future<void> Function(DailyTask) onClaim;
  final void Function(String) onNavigate;

  @override
  Widget build(BuildContext context) {
    final tasks = DailyTaskService.tasks;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final task = tasks[i];
        final completed = service.isCompleted(task.id);
        final claimed = service.isClaimed(task.id);

        return _TaskCard(
          task: task,
          icon: getIcon(task.id),
          accentColor: getColor(task.id),
          progress: service.getProgress(task.id),
          completed: completed,
          claimed: claimed,
          onClaim: () => onClaim(task),
          onNavigate: () => onNavigate(task.id),
        ).animate(delay: (i * 35).ms).fadeIn(duration: 250.ms).slideY(
              begin: 0.05,
              end: 0,
              curve: Curves.easeOutCubic,
            );
      },
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.icon,
    required this.accentColor,
    required this.progress,
    required this.completed,
    required this.claimed,
    required this.onClaim,
    required this.onNavigate,
  });

  final DailyTask task;
  final IconData icon;
  final Color accentColor;
  final int progress;
  final bool completed;
  final bool claimed;
  final VoidCallback onClaim;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    final ratio = (progress / task.target).clamp(0.0, 1.0);
    final faceColor = claimed ? const Color(0xFFF3F3F3) : AppColors.paperWhite;

    return CustomPaint(
      painter: NotebookCardPainter(
        seed: task.id.hashCode,
        faceColor: faceColor,
        shadowOffset: const Offset(2, 2),
        jitter: 1.2,
        borderWidth: 1.8,
        cornerRadius: 6.0,
        showTexture: false,
        borderOpacity: claimed ? 0.35 : 0.95,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Task Icon Box
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: claimed
                    ? const Color(0xFFE0E0E0)
                    : accentColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: claimed ? const Color(0xFFBDBDBD) : AppColors.ink,
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon,
                size: 18,
                color: claimed ? const Color(0xFF888888) : accentColor,
              ),
            ),
            const SizedBox(width: 10),
            // Title & Progress Bar
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.description.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Bangers',
                            fontSize: 13,
                            letterSpacing: 1.2,
                            color: claimed
                                ? const Color(0xFF888888)
                                : AppColors.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: claimed
                              ? const Color(0xFFEAEAEA)
                              : const Color(0xFF00E5FF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: claimed
                                ? const Color(0xFFCCCCCC)
                                : const Color(0xFF00E5FF).withValues(alpha: 0.5),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          '+${task.activityPoints} AP',
                          style: TextStyle(
                            fontFamily: 'Bangers',
                            fontSize: 9.5,
                            letterSpacing: 0.5,
                            color: claimed
                                ? const Color(0xFF888888)
                                : const Color(0xFF0097A7),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: claimed ? 1.0 : ratio,
                            minHeight: 5,
                            backgroundColor: const Color(0xFFE0E0E0),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              claimed
                                  ? const Color(0xFF4CAF50)
                                  : accentColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$progress / ${task.target}',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: claimed
                              ? const Color(0xFFAAAAAA)
                              : const Color(0xFF666666),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  if (task.inkReward > 0 || task.paintReward > 0) ...[
                    const SizedBox(height: 4),
                    _RewardChips(
                      ink: task.inkReward,
                      paint: task.paintReward,
                      claimed: claimed,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Action Button
            _buildAction(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAction(BuildContext context) {
    if (claimed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: const Color(0xFF81C784), width: 1.2),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check, color: Color(0xFF388E3C), size: 12),
            SizedBox(width: 2),
            Text(
              'DONE',
              style: TextStyle(
                fontFamily: 'Bangers',
                fontSize: 10,
                letterSpacing: 1,
                color: Color(0xFF388E3C),
              ),
            ),
          ],
        ),
      );
    }

    if (completed) {
      return _ActionComicBtn(
        label: 'CLAIM',
        color: const Color(0xFF00E676),
        onTap: onClaim,
        highlighted: true,
      );
    }

    return _ActionComicBtn(
      label: 'GO ▸',
      color: AppColors.paperWhite,
      onTap: onNavigate,
      highlighted: false,
    );
  }
}

class _ActionComicBtn extends StatefulWidget {
  const _ActionComicBtn({
    required this.label,
    required this.color,
    required this.onTap,
    required this.highlighted,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  State<_ActionComicBtn> createState() => _ActionComicBtnState();
}

class _ActionComicBtnState extends State<_ActionComicBtn> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 70),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: AppColors.ink, width: 1.8),
            boxShadow: const [
              BoxShadow(
                color: AppColors.ink,
                offset: Offset(1.5, 1.5),
              ),
            ],
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontFamily: 'Bangers',
              fontSize: 11,
              letterSpacing: 1.2,
              color: AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _RewardChips extends StatelessWidget {
  const _RewardChips({
    required this.ink,
    required this.paint,
    required this.claimed,
  });

  final int ink;
  final int paint;
  final bool claimed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      children: [
        if (ink > 0)
          _Chip(
            icon: Icons.water_drop,
            label: '+$ink',
            color: const Color(0xFF2196F3),
            dimmed: claimed,
          ),
        if (paint > 0)
          _Chip(
            icon: Icons.brush,
            label: '+$paint',
            color: const Color(0xFFE91E63),
            dimmed: claimed,
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.color,
    required this.dimmed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = dimmed ? const Color(0xFF888888) : color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: dimmed ? 0.05 : 0.10),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: effectiveColor.withValues(alpha: dimmed ? 0.2 : 0.35),
          width: 0.7,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 8.5, color: effectiveColor),
          const SizedBox(width: 2.5),
          Text(
            label,
            style: TextStyle(
              fontSize: 8.5,
              color: effectiveColor,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
