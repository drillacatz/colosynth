import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colosynth/providers/battle_provider.dart';
import 'package:colosynth/providers/save_provider.dart';
import 'package:colosynth/screens/upgrade/upgrade_notifier.dart';
import 'package:colosynth/screens/upgrade/upgrade_screen_logic.dart';
import 'package:colosynth/screens/upgrade/upgrade_widgets.dart';

const _kNodePos = <String, (double col, int tier)>{

  'atk1': (1.0, 0),
  'hp1': (4.0, 0),
  'stam1': (7.0, 0),
  'active_skill1': (9.5, 0),


  'atk2': (1.0, 1),
  'atk3': (1.0, 2),
  'counter1': (2.5, 2),
  'combo1': (3.5, 1),
  'counter2': (2.5, 3),
  'finisher1': (1.0, 4),
  'finisher2': (1.0, 5),
  'blade_master': (1.5, 6),


  'hp2': (4.0, 1),
  'hp3': (4.0, 2),
  'def1': (3.0, 2),
  'shield1': (5.0, 2),
  'regen1': (4.0, 3),
  'def2': (3.0, 3),
  'shield2': (5.0, 3),
  'regen2': (4.0, 4),
  'iron_wall': (4.0, 5),
  'fortress': (4.0, 6),


  'stam2': (7.0, 1),
  'parry1': (6.0, 2),
  'dodge1': (8.0, 2),
  'parry2': (6.0, 3),
  'dodge2': (8.0, 3),
  'active_skill2': (9.5, 2),
  'lifesteal': (9.5, 3),
  'mastery': (7.5, 5),
};

const double _cellW = 68.0;
const double _cellH = 76.0;
const double _nodeR = 26.0;
const double _canvasMargin = 20.0;




const _kCatColor = {
  SkillCategory.offense: Color(0xFFFF3B30),
  SkillCategory.defense: Color(0xFF007AFF),
  SkillCategory.utility: Color(0xFF34C759),
};




class SkillTreeView extends ConsumerWidget {
  const SkillTreeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked = ref.watch(skillTreeProvider);
    final ink = ref.watch(inkProvider);


    final maxTier = _kNodePos.values.map((e) => e.$2).reduce(math.max);
    final maxCol = _kNodePos.values.map((e) => e.$1).reduce(math.max);

    final canvasW = (maxCol + 1) * _cellW + _canvasMargin * 2;
    final canvasH = (maxTier + 1) * _cellH + _canvasMargin * 2;

    Offset posOf(String id) {
      final (col, tier) = _kNodePos[id]!;
      final x = _canvasMargin + col * _cellW + _cellW / 2;

      final y = _canvasMargin + (maxTier - tier) * _cellH + _cellH / 2;
      return Offset(x, y);
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: SizedBox(
                width: canvasW,
                height: canvasH,
                child: Stack(
                  children: [

                    RepaintBoundary(
                      child: CustomPaint(
                        size: Size(canvasW, canvasH),
                        painter: _EdgePainter(
                          nodes: kAllSkillNodes,
                          posOf: posOf,
                          unlocked: unlocked,
                          catColor: _kCatColor,
                        ),
                      ),
                    ),


                    ...kAllSkillNodes.map((node) {
                      final pos = posOf(node.id);
                      final isUnlocked = unlocked.contains(node.id);
                      final prereqsMet =
                          node.prerequisites.every((p) => unlocked.contains(p));
                      final canUnlock =
                          !isUnlocked && prereqsMet && ink >= node.inkCost;
                      final isLocked = !isUnlocked && !prereqsMet;
                      final color = _kCatColor[node.category]!;

                      return Positioned(
                        left: pos.dx - _nodeR,
                        top: pos.dy - _nodeR,
                        child: _SkillCircle(
                          node: node,
                          isUnlocked: isUnlocked,
                          canUnlock: canUnlock,
                          isLocked: isLocked,
                          color: color,
                          radius: _nodeR,
                          onTap: canUnlock
                              ? () async {
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
                                }
                              : null,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
        SkillTreeFooter(unlockedCount: unlocked.length),
      ],
    );
  }
}




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
        final active =
            unlocked.contains(node.id) && unlocked.contains(prereqId);

        final color = active
            ? catColor[node.category]!.withValues(alpha: 0.70)
            : const Color(0xFFDDDDDD);

        final paint = Paint()
          ..color = color
          ..strokeWidth = active ? 2.5 : 1.8
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;


        final mid = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
        final path = Path()
          ..moveTo(from.dx, from.dy)
          ..quadraticBezierTo(mid.dx, mid.dy, to.dx, to.dy);
        canvas.drawPath(path, paint);


        _drawArrow(canvas, from, to, color, active ? 2.0 : 1.4);
      }
    }
  }

  void _drawArrow(
      Canvas canvas, Offset from, Offset to, Color color, double width) {
    final dir = (to - from);
    final len = dir.distance;
    if (len == 0) return;
    final unit = dir / len;

    final arrowTip = to - unit * _nodeR;
    final arrowBase = arrowTip - unit * 8;
    final perp = Offset(-unit.dy, unit.dx) * 4;

    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(arrowBase + perp, arrowTip, paint);
    canvas.drawLine(arrowBase - perp, arrowTip, paint);
  }

  @override
  bool shouldRepaint(_EdgePainter old) =>
      old.unlocked != unlocked || old.nodes != nodes;
}




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
  final VoidCallback? onTap;

  @override
  State<_SkillCircle> createState() => _SkillCircleState();
}

class _SkillCircleState extends State<_SkillCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _showTooltip = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _bgColor {
    if (widget.isUnlocked) return widget.color.withValues(alpha: 0.15);
    if (widget.canUnlock) return const Color(0xFFFDFDFB);
    return const Color(0xFFF0EDE8);
  }

  Color get _borderColor {
    if (widget.isUnlocked) return widget.color;
    if (widget.canUnlock) return const Color(0xFF1A1A1A);
    return const Color(0xFFCCCCCC);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.radius * 2;

    return GestureDetector(
      onTapDown: (_) {
        if (widget.onTap != null) _ctrl.animateTo(1.0);
        setState(() => _showTooltip = !_showTooltip);
      },
      onTapUp: (_) {
        _ctrl.animateBack(0.0);
        widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.animateBack(0.0),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform.scale(
          scale: 1.0 - _ctrl.value * 0.08,
          child: child,
        ),
        child: SizedBox(
          width: d,
          height: d,
          child: Stack(
            clipBehavior: Clip.none,
            children: [

              Positioned(
                left: 2,
                top: 3,
                child: Container(
                  width: d,
                  height: d,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isUnlocked
                        ? widget.color.withValues(alpha: 0.25)
                        : const Color(0xFFD0C8C0),
                  ),
                ),
              ),

              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: d,
                height: d,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _bgColor,
                  border: Border.all(
                    color: _borderColor,
                    width: widget.isUnlocked ? 2.5 : 1.8,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.isUnlocked
                          ? Icons.check_circle
                          : widget.isLocked
                              ? Icons.lock_outline
                              : Icons.radio_button_unchecked,
                      size: 12,
                      color: widget.isUnlocked
                          ? widget.color
                          : widget.isLocked
                              ? const Color(0xFFAAAAAA)
                              : const Color(0xFF555555),
                    ),
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text(
                        widget.node.label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 6.5,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Bangers',
                          letterSpacing: 0.3,
                          color: widget.isLocked
                              ? const Color(0xFFAAAAAA)
                              : const Color(0xFF1A1A1A),
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_showTooltip)
                Positioned(
                  bottom: d + 6,
                  left: -40,
                  child: _NodeTooltip(
                    node: widget.node,
                    color: widget.color,
                    isUnlocked: widget.isUnlocked,
                    canUnlock: widget.canUnlock,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}




class _NodeTooltip extends StatelessWidget {
  const _NodeTooltip({
    required this.node,
    required this.color,
    required this.isUnlocked,
    required this.canUnlock,
  });

  final SkillNode node;
  final Color color;
  final bool isUnlocked;
  final bool canUnlock;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 108,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFDFDFB),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isUnlocked ? color : const Color(0xFF1A1A1A),
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 6,
              offset: Offset(2, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              node.label,
              style: TextStyle(
                color: isUnlocked ? color : const Color(0xFF1A1A1A),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                fontFamily: 'Bangers',
                letterSpacing: 1,
              ),
            ),
            Consumer(
              builder: (context, ref, _) {
                final statsAsync = ref.watch(battleStatsProvider);
                final stats = statsAsync.value;
                String displayBonus = node.bonus;

                if (stats != null && (node.statType == 'atk' || node.statType == 'hp')) {
                  final statLabel = node.statType.toUpperCase();
                  final currentTotal = (node.statType == 'atk')
                      ? stats.atk
                      : stats.hp;
                  final bonusValue = node.value.toInt();

                  if (isUnlocked) {
                    displayBonus =
                        '$statLabel $currentTotal (INCL. +$bonusValue)';
                  } else {
                    displayBonus =
                        '$statLabel $currentTotal ➔ ${currentTotal + bonusValue}';
                  }
                }

                return Text(
                  displayBonus,
                  style: TextStyle(
                    color: isUnlocked ? color : const Color(0xFF555555),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.water_drop, size: 9, color: Color(0xFF007AFF)),
                const SizedBox(width: 3),
                Text(
                  '${formatResourceCost(node.inkCost)} INK',
                  style: const TextStyle(
                    color: Color(0xFF007AFF),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Bangers',
                  ),
                ),
                const Spacer(),
                if (isUnlocked)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: color,
                        fontSize: 7,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Bangers',
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
