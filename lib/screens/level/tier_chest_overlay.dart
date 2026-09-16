import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colosynth/providers/tournament_provider.dart';
import 'package:colosynth/providers/tier_chest_provider.dart';
import 'package:colosynth/screens/theme/tokens.dart';
import 'package:colosynth/screens/theme/background.dart';
import 'package:colosynth/screens/overlays/claim_reward_overlay.dart';

class TierChestOverlay extends ConsumerWidget {
  const TierChestOverlay({
    super.key,
    required this.tier,
    required this.tournamentName,
  });

  final int tier;
  final String tournamentName;

  static Future<void> show(
    BuildContext context, {
    required int tier,
    required String tournamentName,
  }) {
    HapticFeedback.lightImpact();
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => TierChestOverlay(
        tier: tier,
        tournamentName: tournamentName,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          child: Stack(
            children: [
              const Positioned.fill(child: NotebookBackground()),
              _TierChestContent(
                tier: tier,
                tournamentName: tournamentName,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TierChestContent extends ConsumerWidget {
  const _TierChestContent({
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

    int claimableCount = 0;
    for (int r = 0; r < 6; r++) {
      if (!chestState.claimed[r] && isMilestoneCleared(tier, r, progress)) {
        claimableCount++;
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 16, 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.comicYellow,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.ink, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ink.withValues(alpha: 0.25),
                      offset: const Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.ink,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TIER $tier REWARDS',
                      style: const TextStyle(
                        fontFamily: 'Bangers',
                        fontSize: 22,
                        letterSpacing: 2.5,
                        color: AppColors.ink,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tournamentName.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Bangers',
                        fontSize: 11,
                        letterSpacing: 1.5,
                        color: AppColors.sketchGray,
                      ),
                    ),
                  ],
                ),
              ),
              if (claimableCount > 1) ...[
                GestureDetector(
                  onTap: () async {
                    ComicButton.playButtonSfx();
                    unawaited(HapticFeedback.mediumImpact());
                    int totalInk = 0;
                    int totalPaint = 0;
                    int totalXp = 0;
                    for (int r = 0; r < 6; r++) {
                      if (!chestState.claimed[r] &&
                          isMilestoneCleared(tier, r, progress)) {
                        final rew = rewards[r];
                        totalInk += rew.ink;
                        totalPaint += rew.paint;
                        totalXp += rew.accountXp;
                        await ref
                            .read(tierChestProvider(tier).notifier)
                            .claim(r);
                      }
                    }
                    if (context.mounted && (totalInk > 0 || totalPaint > 0)) {
                      await ClaimRewardOverlay.show(
                        context,
                        inkReward: totalInk,
                        paintReward: totalPaint,
                        xpReward: totalXp,
                      );
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.comicYellow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.ink, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.ink.withValues(alpha: 0.3),
                          offset: const Offset(1.5, 1.5),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Text(
                      'CLAIM ALL ($claimableCount)',
                      style: const TextStyle(
                        fontFamily: 'Bangers',
                        fontSize: 11,
                        letterSpacing: 1.0,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
              ],
              GestureDetector(
                onTap: () {
                  ComicButton.playButtonSfx();
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.comicRed,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.ink, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.ink.withValues(alpha: 0.3),
                        offset: const Offset(1.5, 1.5),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
        Divider(
          color: AppColors.ink.withValues(alpha: 0.12),
          height: 1,
          thickness: 1.5,
        ),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            itemCount: 6,
            itemBuilder: (context, row) {
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
                  ComicButton.playButtonSfx();
                  unawaited(HapticFeedback.mediumImpact());
                  await ref.read(tierChestProvider(tier).notifier).claim(row);
                  if (context.mounted &&
                      (reward.ink > 0 || reward.paint > 0)) {
                    await ClaimRewardOverlay.show(
                      context,
                      inkReward: reward.ink,
                      paintReward: reward.paint,
                      xpReward: reward.accountXp,
                    );
                  }
                },
              )
                  .animate(delay: Duration(milliseconds: 30 + row * 40))
                  .fadeIn(duration: 200.ms)
                  .slideY(begin: 0.05, end: 0);
            },
          ),
        ),
      ],
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
      rowBg = const Color(0xFFF3F3F3);
      leftBorder = const Color(0xFF4CAF50);
    } else if (cleared) {
      rowBg = AppColors.paperWhite;
      leftBorder = AppColors.comicYellow;
    } else {
      rowBg = AppColors.paperWhite;
      leftBorder = AppColors.sketchGray.withValues(alpha: 0.5);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: rowBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: claimed
              ? AppColors.ink.withValues(alpha: 0.25)
              : AppColors.ink,
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: claimed ? 0.15 : 0.4),
            offset: const Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: leftBorder,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(6),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isBossRow)
                          const Padding(
                            padding: EdgeInsets.only(right: 5),
                            child: Icon(
                              Icons.whatshot,
                              size: 13,
                              color: AppColors.comicRed,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            milestoneLabel(row),
                            style: TextStyle(
                              fontFamily: 'Bangers',
                              fontSize: 12.5,
                              letterSpacing: 1.2,
                              color: claimed
                                  ? AppColors.sketchGray
                                  : AppColors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    if (claimed)
                      const Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 13,
                            color: Color(0xFF4CAF50),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'CLAIMED',
                            style: TextStyle(
                              fontFamily: 'Bangers',
                              fontSize: 10.5,
                              letterSpacing: 1.5,
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (reward.ink > 0)
                    _RewardChip(
                      icon: Icons.water_drop_outlined,
                      color: const Color(0xFF1976D2),
                      label: _fmt(reward.ink),
                    ),
                  if (reward.paint > 0)
                    _RewardChip(
                      icon: Icons.palette_outlined,
                      color: const Color(0xFF0097A7),
                      label: '+${reward.paint}P',
                    ),
                  if (reward.accountXp > 0)
                    _RewardChip(
                      icon: Icons.stars_outlined,
                      color: const Color(0xFF8E24AA),
                      label: '+${reward.accountXp}XP',
                    ),
                  if (reward.expItemKey != null && reward.expItemCount > 0)
                    _RewardChip(
                      icon: Icons.science_outlined,
                      color: const Color(0xFFD84315),
                      label: '×${reward.expItemCount}',
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10, left: 2),
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
            padding: const EdgeInsets.only(right: 4),
            child: Container(
              width: done ? 16 : 12,
              height: 6,
              decoration: BoxDecoration(
                color: done ? AppColors.ink : const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: done
                      ? AppColors.ink
                      : AppColors.ink.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
            ),
          );
        }),
        const SizedBox(width: 4),
        Text(
          '$met/$total',
          style: const TextStyle(
            fontFamily: 'Bangers',
            fontSize: 10,
            letterSpacing: 0.8,
            color: AppColors.sketchGray,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10.5, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Bangers',
              fontSize: 10,
              letterSpacing: 0.8,
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

    if (!widget.cleared) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: AppColors.ink.withValues(alpha: 0.25),
            width: 1.2,
          ),
        ),
        child: const Text(
          'LOCKED',
          style: TextStyle(
            fontFamily: 'Bangers',
            fontSize: 10,
            letterSpacing: 1,
            color: AppColors.sketchGray,
          ),
        ),
      );
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 70),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.comicYellow,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: AppColors.ink, width: 1.8),
            boxShadow: const [
              BoxShadow(
                color: AppColors.ink,
                offset: Offset(1.5, 1.5),
              ),
            ],
          ),
          child: const Text(
            'CLAIM',
            style: TextStyle(
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
