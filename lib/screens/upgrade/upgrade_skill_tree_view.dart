import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colosynth/providers/save_provider.dart';
import 'package:colosynth/screens/upgrade/upgrade_notifier.dart';
import 'package:colosynth/screens/upgrade/upgrade_screen_logic.dart';
import 'package:colosynth/screens/upgrade/upgrade_widgets.dart';

/// Node placement configuration in the 3-column vertical tree:
/// - col: 0 (Offense), 1 (Defense), 2 (Utility)
/// - tier: 0 to 6 (progression down the vertical axis)
/// - subOffset: lateral offset within the column (normalized: -1.0 to 1.0)
class _TreeCoord {
  const _TreeCoord({
    required this.col,
    required this.tier,
    this.subOffset = 0.0,
  });

  final int col;
  final int tier;
  final double subOffset;
}

const _kNodeCoords = <String, _TreeCoord>{
  // Column 0: Offense
  'atk1': _TreeCoord(col: 0, tier: 0),
  'atk2': _TreeCoord(col: 0, tier: 1),
  'crit1': _TreeCoord(col: 0, tier: 2, subOffset: -0.55),
  'combo1': _TreeCoord(col: 0, tier: 2, subOffset: 0.55),
  'atk3': _TreeCoord(col: 0, tier: 3, subOffset: -0.55),
  'active1': _TreeCoord(col: 0, tier: 3, subOffset: 0.55),
  'crit2': _TreeCoord(col: 0, tier: 4, subOffset: -0.55),
  'active2': _TreeCoord(col: 0, tier: 4, subOffset: 0.55),
  'finisher1': _TreeCoord(col: 0, tier: 5),

  // Column 1: Defense
  'hp1': _TreeCoord(col: 1, tier: 0),
  'hp2': _TreeCoord(col: 1, tier: 1),
  'def1': _TreeCoord(col: 1, tier: 2, subOffset: -0.55),
  'shield1': _TreeCoord(col: 1, tier: 2, subOffset: 0.55),
  'hp3': _TreeCoord(col: 1, tier: 3, subOffset: -0.55),
  'parry_def': _TreeCoord(col: 1, tier: 3, subOffset: 0.55),
  'def2': _TreeCoord(col: 1, tier: 4, subOffset: -0.72),
  'shield2': _TreeCoord(col: 1, tier: 4, subOffset: 0.0),
  'block1': _TreeCoord(col: 1, tier: 4, subOffset: 0.72),
  'regen1': _TreeCoord(col: 1, tier: 5),

  // Column 2: Utility
  'stam1': _TreeCoord(col: 2, tier: 0),
  'stam2': _TreeCoord(col: 2, tier: 1),
  'parry1': _TreeCoord(col: 2, tier: 2, subOffset: -0.55),
  'dodge1': _TreeCoord(col: 2, tier: 2, subOffset: 0.55),
  'active_skill1': _TreeCoord(col: 2, tier: 3, subOffset: -0.55),
  'parry2': _TreeCoord(col: 2, tier: 3, subOffset: 0.55),
  'dodge2': _TreeCoord(col: 2, tier: 4, subOffset: -0.55),
  'active_skill2': _TreeCoord(col: 2, tier: 4, subOffset: 0.55),
  'lifesteal': _TreeCoord(col: 2, tier: 5),

  // Capstone: Spanning center
  'mastery': _TreeCoord(col: 1, tier: 6),
};

const _kCatColor = {
  SkillCategory.offense: Color(0xFFFF3B30),
  SkillCategory.defense: Color(0xFF007AFF),
  SkillCategory.utility: Color(0xFF34C759),
};

const double _nodeR = 21.0; // 42dp diameter node disc
const double _headerH = 38.0;
const double _tierSpacing = 92.0;

class SkillTreeView extends ConsumerWidget {
  const SkillTreeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked = ref.watch(skillTreeProvider);
    final ink = ref.watch(inkProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasW = constraints.maxWidth;
        final colW = canvasW / 3;
        final totalCanvasH = _headerH + (7 * _tierSpacing) + 30.0;

        Offset posOf(String id) {
          final coord = _kNodeCoords[id] ?? const _TreeCoord(col: 0, tier: 0);
          final baseColX = (coord.col + 0.5) * colW;
          // Sub-offset shifts node slightly inside the column width
          final maxSubSpread = (colW * 0.38);
          final x = baseColX + coord.subOffset * maxSubSpread;
          final y = _headerH + 20.0 + coord.tier * _tierSpacing;
          return Offset(x, y);
        }

        return Column(
          children: [
            // Sticky 3-Column Header
            _StickyThreeColumnHeaders(colWidth: colW),

            // Vertical-Only Scrollable Tree
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  width: canvasW,
                  height: totalCanvasH,
                  child: Stack(
                    children: [
                      // Freeform Bezier Network
                      RepaintBoundary(
                        child: CustomPaint(
                          size: Size(canvasW, totalCanvasH),
                          painter: _EdgePainter(
                            nodes: kAllSkillNodes,
                            posOf: posOf,
                            unlocked: unlocked,
                            catColor: _kCatColor,
                          ),
                        ),
                      ),

                      // Skill Nodes
                      ...kAllSkillNodes.map((node) {
                        final pos = posOf(node.id);
                        final isUnlocked = unlocked.contains(node.id);
                        final prereqsMet = node.prerequisites
                            .every((p) => unlocked.contains(p));
                        final canUnlock =
                            !isUnlocked && prereqsMet && ink >= node.inkCost;
                        final isLocked = !isUnlocked && !prereqsMet;
                        final color = (node.id == 'mastery')
                            ? const Color(0xFFFFD700) // Golden Capstone
                            : _kCatColor[node.category]!;

                        return Positioned(
                          left: pos.dx - 36,
                          top: pos.dy - _nodeR,
                          width: 72,
                          child: _SkillCircle(
                            node: node,
                            isUnlocked: isUnlocked,
                            canUnlock: canUnlock,
                            isLocked: isLocked,
                            color: color,
                            radius: _nodeR,
                            onTap: () {
                              _showNodeDetailsDialog(
                                context: context,
                                ref: ref,
                                node: node,
                                isUnlocked: isUnlocked,
                                canUnlock: canUnlock,
                                isLocked: isLocked,
                                currentInk: ink,
                                color: color,
                              );
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),

            SkillTreeFooter(unlockedCount: unlocked.length),
          ],
        );
      },
    );
  }

  void _showNodeDetailsDialog({
    required BuildContext context,
    required WidgetRef ref,
    required SkillNode node,
    required bool isUnlocked,
    required bool canUnlock,
    required bool isLocked,
    required int currentInk,
    required Color color,
  }) {
    HapticFeedback.lightImpact();
    showDialog<void>(
      context: context,
      builder: (ctx) => _SkillNodeModalDialog(
        node: node,
        isUnlocked: isUnlocked,
        canUnlock: canUnlock,
        isLocked: isLocked,
        currentInk: currentInk,
        color: color,
        onUnlock: () async {
          Navigator.of(ctx).pop();
          unawaited(HapticFeedback.mediumImpact());
          try {
            await ref
                .read(upgradeNotifierProvider.notifier)
                .unlockSkillNode(
                  node.id,
                  node.inkCost,
                  node.prerequisites,
                );
          } catch (_) {}
        },
      ),
    );
  }
}

/// Sticky 3-Column Header dividing Offense, Defense, and Utility.
class _StickyThreeColumnHeaders extends StatelessWidget {
  const _StickyThreeColumnHeaders({required this.colWidth});

  final double colWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _headerH,
      decoration: const BoxDecoration(
        color: Color(0xFFF8F6F0),
        border: Border(
          bottom: BorderSide(color: Color(0xFF1A1A1A), width: 2),
        ),
      ),
      child: Row(
        children: [
          _HeaderCell(
            label: 'OFFENSE',
            icon: Icons.colorize,
            color: _kCatColor[SkillCategory.offense]!,
            width: colWidth,
          ),
          _HeaderCell(
            label: 'DEFENSE',
            icon: Icons.shield,
            color: _kCatColor[SkillCategory.defense]!,
            width: colWidth,
          ),
          _HeaderCell(
            label: 'UTILITY',
            icon: Icons.bolt,
            color: _kCatColor[SkillCategory.utility]!,
            width: colWidth,
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.label,
    required this.icon,
    required this.color,
    required this.width,
  });

  final String label;
  final IconData icon;
  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Bangers',
                  fontSize: 12,
                  letterSpacing: 1.2,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Freeform Bezier Network connecting prerequisite nodes.
class _EdgePainter extends CustomPainter {
  const _EdgePainter({
    required this.nodes,
    required this.posOf,
    required this.unlocked,
    required this.catColor,
  });

  final List<SkillNode> nodes;
  final Offset Function(String) posOf;
  final Set<String> unlocked;
  final Map<SkillCategory, Color> catColor;

  @override
  void paint(Canvas canvas, Size size) {
    for (final node in nodes) {
      final to = posOf(node.id);
      for (final prereqId in node.prerequisites) {
        final from = posOf(prereqId);
        final isUnlockedPath =
            unlocked.contains(node.id) && unlocked.contains(prereqId);
        final canUnlockTarget =
            !unlocked.contains(node.id) && unlocked.contains(prereqId);

        final strokeColor = isUnlockedPath
            ? catColor[node.category]!.withValues(alpha: 0.85)
            : canUnlockTarget
                ? const Color(0xFF1A1A1A).withValues(alpha: 0.65)
                : const Color(0xFFD5D2CC);

        final strokeWidth = isUnlockedPath
            ? 2.6
            : canUnlockTarget
                ? 2.0
                : 1.3;

        final paint = Paint()
          ..color = strokeColor
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

        // Smooth cubic/quadratic bezier curve
        final path = Path()..moveTo(from.dx, from.dy);
        final midY = (from.dy + to.dy) / 2;

        if ((from.dx - to.dx).abs() < 5) {
          // Direct vertical downward connection
          path.lineTo(to.dx, to.dy);
        } else {
          // Curved freeform bezier routing
          path.cubicTo(
            from.dx,
            midY,
            to.dx,
            midY,
            to.dx,
            to.dy,
          );
        }
        canvas.drawPath(path, paint);

        // Arrow tip at destination node
        _drawArrowTip(canvas, from, to, strokeColor, strokeWidth);
      }
    }
  }

  void _drawArrowTip(
    Canvas canvas,
    Offset from,
    Offset to,
    Color color,
    double width,
  ) {
    final dir = to - from;
    final len = dir.distance;
    if (len == 0) return;
    final unit = dir / len;

    final tip = to - unit * (_nodeR + 1.0);
    final base = tip - unit * 6.0;
    final perp = Offset(-unit.dy, unit.dx) * 3.5;

    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(base + perp, tip, paint);
    canvas.drawLine(base - perp, tip, paint);
  }

  @override
  bool shouldRepaint(_EdgePainter old) =>
      old.unlocked != unlocked || old.nodes != nodes;
}

/// Modernized Comic Skill Node Disc.
class _SkillCircle extends StatefulWidget {
  const _SkillCircle({
    required this.node,
    required this.isUnlocked,
    required this.canUnlock,
    required this.isLocked,
    required this.color,
    required this.radius,
    required this.onTap,
  });

  final SkillNode node;
  final bool isUnlocked;
  final bool canUnlock;
  final bool isLocked;
  final Color color;
  final double radius;
  final VoidCallback onTap;

  @override
  State<_SkillCircle> createState() => _SkillCircleState();
}

class _SkillCircleState extends State<_SkillCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.canUnlock) {
      _pulseCtrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_SkillCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.canUnlock && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!widget.canUnlock && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.radius * 2;
    final isCapstone = widget.node.id == 'mastery';

    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (context, child) {
              final scale = widget.canUnlock
                  ? 1.0 + _pulseCtrl.value * 0.08
                  : 1.0;
              return Transform.scale(
                scale: scale,
                child: child,
              );
            },
            child: SizedBox(
              width: d,
              height: d,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Hard Comic Drop Shadow
                  Positioned(
                    left: 2,
                    top: 2,
                    child: Container(
                      width: d,
                      height: d,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),

                  // Node Body
                  Container(
                    width: d,
                    height: d,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isUnlocked
                          ? widget.color
                          : widget.canUnlock
                              ? const Color(0xFFFDFDFB)
                              : const Color(0xFFE8E5DF),
                      border: Border.all(
                        color: const Color(0xFF1A1A1A),
                        width: isCapstone ? 3.0 : 2.0,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        widget.isUnlocked
                            ? Icons.check
                            : widget.isLocked
                                ? Icons.lock
                                : _iconForNode(widget.node),
                        size: 16,
                        color: widget.isUnlocked
                            ? Colors.white
                            : widget.isLocked
                                ? const Color(0xFFAAAAAA)
                                : widget.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 2),
          // Node Label
          SizedBox(
            width: 72,
            child: Text(
              widget.node.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Bangers',
                fontSize: 8,
                letterSpacing: 0.3,
                color: widget.isUnlocked
                    ? widget.color
                    : const Color(0xFF1A1A1A),
              ),
            ),
          ),
          const SizedBox(height: 1),
          // Compact Label / Ink Cost Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: widget.isUnlocked
                  ? widget.color.withValues(alpha: 0.15)
                  : widget.canUnlock
                      ? const Color(0xFF1A1A1A)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              widget.isUnlocked
                  ? 'ACTIVE'
                  : formatResourceCost(widget.node.inkCost),
              style: TextStyle(
                fontFamily: 'Bangers',
                fontSize: 8,
                letterSpacing: 0.5,
                color: widget.isUnlocked
                    ? widget.color
                    : widget.canUnlock
                        ? Colors.white
                        : const Color(0xFF888888),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForNode(SkillNode node) {
    if (node.id == 'mastery') return Icons.military_tech;
    switch (node.category) {
      case SkillCategory.offense:
        return Icons.colorize;
      case SkillCategory.defense:
        return Icons.shield;
      case SkillCategory.utility:
        return Icons.bolt;
    }
  }
}

/// Intuitive modal dialog displayed when tapping any skill node.
class _SkillNodeModalDialog extends StatelessWidget {
  const _SkillNodeModalDialog({
    required this.node,
    required this.isUnlocked,
    required this.canUnlock,
    required this.isLocked,
    required this.currentInk,
    required this.color,
    required this.onUnlock,
  });

  final SkillNode node;
  final bool isUnlocked;
  final bool canUnlock;
  final bool isLocked;
  final int currentInk;
  final Color color;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 290,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFFDFDFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF1A1A1A), width: 2.5),
            boxShadow: const [
              BoxShadow(color: Color(0xFF1A1A1A), offset: Offset(4, 4)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? color
                          : color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF1A1A1A), width: 1.8),
                    ),
                    child: Icon(
                      isUnlocked ? Icons.check : Icons.account_tree,
                      color: isUnlocked ? Colors.white : color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          node.label,
                          style: TextStyle(
                            fontFamily: 'Bangers',
                            fontSize: 18,
                            letterSpacing: 1.2,
                            color: color,
                          ),
                        ),
                        Text(
                          node.bonus,
                          style: const TextStyle(
                            fontFamily: 'Bangers',
                            fontSize: 13,
                            color: Color(0xFF1A1A1A),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(color: Color(0xFF1A1A1A), thickness: 1.5, height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'INK COST:',
                    style: TextStyle(
                      fontFamily: 'Bangers',
                      fontSize: 12,
                      letterSpacing: 1,
                      color: Color(0xFF888888),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.water_drop, size: 14, color: Color(0xFF007AFF)),
                      const SizedBox(width: 4),
                      Text(
                        '${node.inkCost} INK',
                        style: const TextStyle(
                          fontFamily: 'Bangers',
                          fontSize: 14,
                          letterSpacing: 1,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'STATUS:',
                    style: TextStyle(
                      fontFamily: 'Bangers',
                      fontSize: 12,
                      letterSpacing: 1,
                      color: Color(0xFF888888),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      isUnlocked
                          ? 'UNLOCKED & ACTIVE'
                          : isLocked
                              ? 'PREREQUISITES REQUIRED'
                              : 'READY TO UNLOCK',
                      style: TextStyle(
                        fontFamily: 'Bangers',
                        fontSize: 12,
                        letterSpacing: 1,
                        color: isUnlocked
                            ? const Color(0xFF4CAF50)
                            : isLocked
                                ? const Color(0xFFFF3B30)
                                : const Color(0xFF007AFF),
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (isUnlocked)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF4CAF50), width: 1.5),
                  ),
                  child: const Center(
                    child: Text(
                      'NODE ALREADY UNLOCKED',
                      style: TextStyle(
                        fontFamily: 'Bangers',
                        fontSize: 12,
                        letterSpacing: 1,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ),
                )
              else
                GestureDetector(
                  onTap: canUnlock ? onUnlock : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: canUnlock
                          ? const Color(0xFF1A1A1A)
                          : const Color(0xFFE0DDD8),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: canUnlock
                          ? const [
                              BoxShadow(
                                color: Color(0xFF1A1A1A),
                                offset: Offset(2, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        canUnlock
                            ? 'UNLOCK NODE'
                            : isLocked
                                ? 'LOCKED (UNLOCK PREREQUISITES)'
                                : 'NOT ENOUGH INK ($currentInk / ${node.inkCost})',
                        style: TextStyle(
                          fontFamily: 'Bangers',
                          fontSize: 12,
                          letterSpacing: 1,
                          color: canUnlock ? Colors.white : const Color(0xFFAAAAAA),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
