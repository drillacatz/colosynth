import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colosynth/providers/tournament_provider.dart';
import 'package:colosynth/providers/tier_chest_provider.dart';


class TierChestOverlay extends ConsumerWidget {
  const TierChestOverlay({
    super.key,
    required this.tier,
    required this.tournamentName,
  });

  final int tier;
  final String tournamentName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(tournamentProgressProvider);
    final chestState = ref.watch(tierChestProvider(tier));
    final rewards = milestoneRewardsForTier(tier);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF100700),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: Color(0xFF3D2200), width: 1.5),
          left: BorderSide(color: Color(0xFF3D2200), width: 1),
          right: BorderSide(color: Color(0xFF3D2200), width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF5A3000).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Icon(Icons.inventory_2_outlined,
                    color: Color(0xFF00E5FF), size: 26),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TIER $tier REWARDS',
                      style: const TextStyle(
                        fontFamily: 'Bangers',
                        fontSize: 20,
                        letterSpacing: 4,
                        color: Color(0xFF00E5FF),
                      ),
                    ),
                    Text(
                      tournamentName,
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.5,
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (chestState.allClaimed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
                          width: 1),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 12, color: Color(0xFF4CAF50)),
                        SizedBox(width: 4),
                        Text(
                          'ALL CLAIMED',
                          style: TextStyle(
                            fontFamily: 'Bangers',
                            fontSize: 10,
                            letterSpacing: 2,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const Divider(color: Color(0xFF3D2200), height: 1),
          const SizedBox(height: 4),

          ...List.generate(6, (row) {
            final cleared = isMilestoneCleared(tier, row, progress);
            final claimed = chestState.claimed[row];
            final reward = rewards[row];
            return _MilestoneRow(
              row: row,
              tier: tier,
              progress: progress,
              cleared: cleared,
              claimed: claimed,
              reward: reward,
              onClaim: () async {
                unawaited(HapticFeedback.mediumImpact());
                await ref.read(tierChestProvider(tier).notifier).claim(row);
              },
            )
                .animate(delay: Duration(milliseconds: 60 + row * 50))
                .fadeIn(duration: 220.ms)
                .slideX(begin: 0.03, end: 0);
          }),

          SizedBox(height: MediaQuery.paddingOf(context).bottom + 20),
        ],
      ),
    );
  }
}


class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({
    required this.row,
    required this.tier,
    required this.progress,
    required this.cleared,
    required this.claimed,
    required this.reward,
    required this.onClaim,
  });

  final int row;
  final int tier;
  final Map<String, String> progress;
  final bool cleared;
  final bool claimed;
  final MilestoneReward reward;
  final VoidCallback onClaim;

  int _metConditions() {
    final t = tier;
    switch (row) {
      case 0:
        return [
          progress.containsKey('t${t}_a_0'),
          progress.containsKey('t${t}_a_1'),
          progress.containsKey('t${t}_a_2'),
        ].where((b) => b).length;
      case 1:
        return progress.containsKey('t${t}_a_boss') ? 1 : 0;
      case 2:
        return [
          progress.containsKey('t${t}_b_0'),
          progress.containsKey('t${t}_b_1'),
          progress.containsKey('t${t}_b_2'),
        ].where((b) => b).length;
      case 3:
        return progress.containsKey('t${t}_b_boss') ? 1 : 0;
      case 4:
        return [
          progress.containsKey('t${t}_c_0'),
          progress.containsKey('t${t}_c_1'),
          progress.containsKey('t${t}_c_2'),
        ].where((b) => b).length;
      case 5:
        return progress.containsKey('t${t}_c_boss') ? 1 : 0;
      default:
        return 0;
    }
  }

  int _totalConditions() => (row == 1 || row == 3 || row == 5) ? 1 : 3;

  @override
  Widget build(BuildContext context) {
    final met = _metConditions();
    final total = _totalConditions();
    final isBossRow = (row == 1 || row == 3 || row == 5);

    final Color rowBg;
    final Color leftBorder;
    if (claimed) {
      rowBg = const Color(0xFF0F1A06);
      leftBorder = const Color(0xFF4CAF50);
    } else if (cleared) {
      rowBg = const Color(0xFF1A0D00);
      leftBorder = const Color(0xFF00E5FF);
    } else {
      rowBg = Colors.transparent;
      leftBorder = const Color(0xFF3D2200);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: rowBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: leftBorder.withValues(alpha: 0.35), width: 1),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: leftBorder,
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(8)),
              ),
            ),

            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isBossRow)
                          const Padding(
                            padding: EdgeInsets.only(right: 5),
                            child: Icon(Icons.whatshot,
                                size: 11, color: Color(0xFFFF6B35)),
                          ),
                        Expanded(
                          child: Text(
                            milestoneLabel(row),
                            style: TextStyle(
                              fontFamily: 'Bangers',
                              fontSize: 12,
                              letterSpacing: 1.5,
                              color: claimed
                                  ? const Color(0xFF4CAF50)
                                  : cleared
                                      ? const Color(0xFF00E5FF)
                                      : Colors.white.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (claimed)
                      const Row(
                        children: [
                          Icon(Icons.check_circle,
                              size: 12, color: Color(0xFF4CAF50)),
                          SizedBox(width: 4),
                          Text(
                            'CLAIMED',
                            style: TextStyle(
                              fontFamily: 'Bangers',
                              fontSize: 10,
                              letterSpacing: 2,
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                        ],
                      )
                    else
                      _ProgressDots(met: met, total: total),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (reward.ink > 0)
                    _RewardChip(
                      icon: Icons.water_drop_outlined,
                      color: const Color(0xFF90CAF9),
                      label: _fmt(reward.ink),
                    ),
                  if (reward.paint > 0)
                    _RewardChip(
                      icon: Icons.palette_outlined,
                      color: const Color(0xFF00E5FF),
                      label: '+${reward.paint}P',
                    ),
                  if (reward.accountXp > 0)
                    _RewardChip(
                      icon: Icons.stars_outlined,
                      color: const Color(0xFFCE93D8),
                      label: '+${reward.accountXp}XP',
                    ),
                  if (reward.expItemKey != null && reward.expItemCount > 0)
                    _RewardChip(
                      icon: Icons.science_outlined,
                      color: const Color(0xFF80CBC4),
                      label: '×${reward.expItemCount}',
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(right: 12, left: 4),
              child: _ClaimButton(
                cleared: cleared,
                claimed: claimed,
                onTap: onClaim,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(int ink) {
    if (ink >= 1000) return '+${(ink / 1000).toStringAsFixed(1)}k';
    return '+$ink';
  }
}


class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.met, required this.total});
  final int met;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ...List.generate(total, (i) {
          final done = i < met;
          return Padding(
            padding: const EdgeInsets.only(right: 5),
            child: Container(
              width: done ? 18 : 14,
              height: 5,
              decoration: BoxDecoration(
                color: done
                    ? const Color(0xFF00E5FF)
                    : Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          );
        }),
        const SizedBox(width: 4),
        Text(
          '$met/$total',
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
}


class _RewardChip extends StatelessWidget {
  const _RewardChip({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Bangers',
              fontSize: 11,
              letterSpacing: 1,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}


class _ClaimButton extends StatefulWidget {
  const _ClaimButton({
    required this.cleared,
    required this.claimed,
    required this.onTap,
  });

  final bool cleared;
  final bool claimed;
  final VoidCallback onTap;

  @override
  State<_ClaimButton> createState() => _ClaimButtonState();
}

class _ClaimButtonState extends State<_ClaimButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    if (widget.claimed) {
      return const Icon(Icons.check_circle,
          size: 22, color: Color(0xFF4CAF50));
    }

    final active = widget.cleared;
    final bg = active ? const Color(0xFF00E5FF) : Colors.white.withValues(alpha: 0.06);
    final textCol = active ? const Color(0xFF1A1A1A) : Colors.white.withValues(alpha: 0.25);
    final borderCol = active ? const Color(0xFF1A1A1A).withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.08);

    return GestureDetector(
      onTapDown: active ? (_) => setState(() => _pressed = true) : null,
      onTapUp: active ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: active ? () => setState(() => _pressed = false) : null,
      onTap: active ? widget.onTap : null,
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: borderCol, width: 1.2),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            'CLAIM',
            style: TextStyle(
              fontFamily: 'Bangers',
              fontSize: 12,
              letterSpacing: 2.5,
              color: textCol,
            ),
          ),
        ),
      ),
    );
  }
}
