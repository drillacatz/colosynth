import 'package:flutter/material.dart';
import 'package:colosynth/screens/theme/tokens.dart';
import 'package:colosynth/screens/theme/shared_painters.dart';
import 'package:colosynth/services/daily_task_service.dart';

class DailyTaskCard extends StatelessWidget {
  const DailyTaskCard({
    super.key,
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
                    TaskRewardChips(
                      ink: task.inkReward,
                      paint: task.paintReward,
                      claimed: claimed,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
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
      return TaskActionComicBtn(
        label: 'CLAIM',
        color: const Color(0xFF00E676),
        onTap: onClaim,
        highlighted: true,
      );
    }

    return TaskActionComicBtn(
      label: 'GO ▸',
      color: AppColors.paperWhite,
      onTap: onNavigate,
      highlighted: false,
    );
  }
}

class TaskActionComicBtn extends StatefulWidget {
  const TaskActionComicBtn({
    super.key,
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
  State<TaskActionComicBtn> createState() => _TaskActionComicBtnState();
}

class _TaskActionComicBtnState extends State<TaskActionComicBtn> {
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

class TaskRewardChips extends StatelessWidget {
  const TaskRewardChips({
    super.key,
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
          TaskChip(
            icon: Icons.water_drop,
            label: '+$ink',
            color: const Color(0xFF2196F3),
            dimmed: claimed,
          ),
        if (paint > 0)
          TaskChip(
            icon: Icons.brush,
            label: '+$paint',
            color: const Color(0xFFE91E63),
            dimmed: claimed,
          ),
      ],
    );
  }
}

class TaskChip extends StatelessWidget {
  const TaskChip({
    super.key,
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
