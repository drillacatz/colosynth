import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colosynth/game_settings.dart';
import 'package:colosynth/services/audio_service.dart';

import 'package:colosynth/game_data/level_data.dart';
import 'package:colosynth/game/app_shell/battle_models.dart';
import 'package:colosynth/providers/save_provider.dart';
import 'package:colosynth/providers/tournament_provider.dart';
import 'package:colosynth/services/achievement_service.dart';
import 'package:colosynth/services/battle_ads_service.dart';
import 'package:colosynth/services/battle_stats_service.dart';
import 'package:colosynth/game/app_shell/battle_result.dart';
import 'package:colosynth/services/save_manager.dart';
import 'package:colosynth/services/synth/synth_crate_service.dart';
import 'package:colosynth/services/account_sync_service.dart';
import 'package:colosynth/game/event_bus/game_event_bus.dart';
import 'package:colosynth/game/event_bus/game_events.dart';
import 'package:colosynth/services/level_progress_service.dart';
import 'package:colosynth/screens/overlays/top_overlay.dart';
import 'package:colosynth/screens/overlays/synth_crate_opening_overlay.dart';
import 'package:colosynth/screens/theme/background.dart';
import 'package:colosynth/screens/theme/tokens.dart';

class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({
    super.key,
    required this.result,
    required this.slot,
  });

  final BattleResult result;
  final TSlot slot;

  static Future<void> push(
    BuildContext context, {
    required BattleResult result,
    required TSlot slot,
  }) {
    return Navigator.of(context, rootNavigator: true).push<void>(
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => ResultScreen(result: result, slot: slot),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _countController;
  late final Animation<double> _counterAnimation;

  bool _isFirstClear = false;
  bool _isTierComplete = false;
  int _grantedInk = 0;
  int _grantedPaint = 0;
  int _grantedXp = 0;

  bool _rewardsProcessed = false;

  bool _doubleRewardClaimed = false;
  bool _doubleRewardBusy = false;
  bool _canDoubleReward = false;
  int _remainingDoubleRewards = 0;

  @override
  void initState() {
    super.initState();
    _countController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _counterAnimation = CurvedAnimation(
      parent: _countController,
      curve: Curves.easeOutCubic,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateAndApplyRewards();
    });
  }

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  Future<void> _calculateAndApplyRewards() async {
    if (_rewardsProcessed) return;
    _rewardsProcessed = true;

    final isVictory = widget.result.outcome == BattleOutcome.victory;
    if (!isVictory) {
      AudioService.instance.playSfx(SfxEvent.defeat);
      setState(() {});
      return;
    }

    AudioService.instance.playSfx(SfxEvent.victory);

    final progress = ref.read(tournamentProgressProvider);
    final isFirstClear = !progress.containsKey(widget.slot.id);
    final tier = widget.slot.tournamentTier;

    final istiercBoss = widget.slot.id == 't${tier}_c_boss';
    final isTierComplete =
        istiercBoss && !progress.containsKey('tier_${tier}_cleared');

    int totalInk = 0;
    int totalPaint = 0;
    int totalXp = 0;

    if (isFirstClear) {
      totalInk += 3000;
      totalPaint += 30;
      totalXp += ProgressionService.levelFirstClearXp(tier, widget.slot.id);
    } else {
      totalInk += 300;
      totalXp += (ProgressionService.levelFirstClearXp(tier, widget.slot.id) * 0.1).round();
    }

    if (isTierComplete) {
      totalInk += 12000;
      totalPaint += 200;
    }

    setState(() {
      _isFirstClear = isFirstClear;
      _isTierComplete = isTierComplete;
      _grantedInk = totalInk;
      _grantedPaint = totalPaint;
      _grantedXp = totalXp;
      _canDoubleReward = BattleAdsService.instance.canShowDoubleReward;
      _remainingDoubleRewards = BattleAdsService.instance.remainingDoubleRewards;
    });

    final notifier = ref.read(tournamentProgressProvider.notifier);
    notifier.markCompleted(widget.slot.id);
    GameEventBus.instance.emit(
      TournamentStageClearedEvent(widget.slot.id, tier, isFirstClear),
    );

    if (widget.slot.id == 'tutorial_2') {
      unawaited(ref.read(tutorialStateProvider.notifier).complete());
    }

    if (isTierComplete) {
      notifier.markCompleted('tier_${tier}_cleared');
      GameEventBus.instance.emit(
        TournamentTierClearedEvent(tier, true),
      );
    }

    final sm = ref.read(saveManagerProvider);
    await sm.saveTournamentProgress(
      Map.from(ref.read(tournamentProgressProvider)),
    );

    await ref.read(walletProvider.notifier).awardMultiple(
          ink: totalInk,
          paint: totalPaint,
          source: 'tournament_stage_reward',
        );

    if (totalXp > 0) {
      await ref.read(accountLevelProvider.notifier).addXp(totalXp);
    }

    if (isFirstClear) {
      await SynthCrateService.instance.onStageFirstClear();
    }

    final stats = BattleStatsService.instance;
    String tierName = 'easy';
    if (widget.slot.isExtreme) {
      tierName = 'extreme';
    } else if (tier >= 7) {
      tierName = 'hard';
    } else if (tier >= 4) {
      tierName = 'medium';
    }
    await stats.recordBattle(
      result: widget.result,
      tournamentTierName: tierName,
    );

    if (isFirstClear) {
      await ref
          .read(achievementServiceProvider)
          .unlock(AchievementIds.firstWin);
      await ref
          .read(achievementServiceProvider)
          .checkTournamentAchievements(tier);
    }


    unawaited(AccountSyncService.instance.flushMilestone());

    AudioService.instance.playSfx(SfxEvent.reward);
    unawaited(_countController.forward());
  }

  @override
  Widget build(BuildContext context) {
    final isVictory = widget.result.outcome == BattleOutcome.victory;
    final primaryColor =
        isVictory ? const Color(0xFFFFCC00) : const Color(0xFF1A1A1A);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(
            child: NotebookBackground(),
          ),
          if (isVictory)
            Positioned.fill(
              child: Opacity(
                opacity: 0.05,
                child: _HalftoneBurst(),
              ),
            ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: TopOverlay(
              visible: true,
              animateInk: isVictory && _grantedInk > 0,
              animatePaint: isVictory && _grantedPaint > 0,
              animateXp: isVictory && _grantedXp > 0,
            )
                .animate(delay: 300.ms)
                .slideY(begin: -0.5, end: 0, curve: Curves.easeOutCubic)
                .fadeIn(duration: 250.ms),
          ),

          SafeArea(
            child: Column(
              children: [
                const Spacer(),

                _ResultBanner(
                  isVictory: isVictory,
                  primaryColor: primaryColor,
                )
                    .animate()
                    .scale(
                        begin: const Offset(0.7, 0.7),
                        duration: 400.ms,
                        curve: Curves.elasticOut)
                    .fadeIn(duration: 250.ms),

                const SizedBox(height: 24),

                Text(
                  widget.slot.enemyName,
                  style: const TextStyle(
                    fontFamily: 'Bangers',
                    fontSize: 28,
                    letterSpacing: 2,
                    color: Color(0xFF1A1A1A),
                  ),
                ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1, end: 0),

                Text(
                  widget.slot.id.startsWith('tutorial_')
                      ? 'TUTORIAL - LESSON ${(int.tryParse(widget.slot.id.split('_').last) ?? 0) + 1}'
                      : 'TIER ${widget.slot.tournamentTier} - STAGE ${widget.slot.id.contains('_') ? widget.slot.id.split('_')[1].toUpperCase() : widget.slot.id.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 12,
                    letterSpacing: 3,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ).animate(delay: 260.ms).fadeIn(),

                const Spacer(),

                if (isVictory)
                  _RewardsCard(
                    ink: _grantedInk,
                    paint: _grantedPaint,
                    xp: _grantedXp,
                    isFirstClear: _isFirstClear,
                    isTierComplete: _isTierComplete,
                    counter: _counterAnimation,
                  )
                      .animate(delay: 450.ms)
                      .fadeIn(duration: 350.ms)
                      .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic)
                else
                  _DefeatStatsCard(result: widget.result)
                      .animate(delay: 350.ms)
                      .fadeIn(duration: 300.ms),

                const SizedBox(height: 16),

                if (isVictory)
                  _StatsRow(result: widget.result)
                      .animate(delay: 650.ms)
                      .fadeIn(duration: 300.ms),

                const Spacer(),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isVictory &&
                          _grantedInk > 0 &&
                          _canDoubleReward &&
                          !_doubleRewardClaimed) ...[
                        _DoubleRewardButton(
                          canShow: true,
                          claimed: _doubleRewardClaimed,
                          busy: _doubleRewardBusy,
                          remaining: _remainingDoubleRewards,
                          onTap: _handleDoubleRewardTap,
                        )
                            .animate(delay: 750.ms)
                            .fadeIn(duration: 300.ms)
                            .slideY(begin: 0.05, end: 0),
                        const SizedBox(height: 12),
                        _ContinueButton(
                          primaryColor: primaryColor,
                          label: 'CLAIM & CONTINUE',
                          isSecondary: true,
                          onTap: _handleContinueTap,
                        )
                            .animate(delay: 850.ms)
                            .fadeIn(duration: 250.ms)
                            .slideY(begin: 0.05, end: 0),
                      ] else ...[
                        if (_doubleRewardClaimed) ...[
                          const _DoubleRewardClaimedBadge()
                              .animate()
                              .fadeIn(duration: 300.ms),
                          const SizedBox(height: 12),
                        ],
                        _ContinueButton(
                          primaryColor: primaryColor,
                          label: 'CONTINUE',
                          isSecondary: false,
                          onTap: _handleContinueTap,
                        )
                            .animate(delay: 750.ms)
                            .fadeIn(duration: 250.ms)
                            .slideY(begin: 0.05, end: 0),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleContinueTap() {
    final isVictory = widget.result.outcome == BattleOutcome.victory;
    final isTutorial = widget.slot.id.startsWith('tutorial_');

    if (isVictory && (isTutorial || _isFirstClear)) {
      SynthCrateOpeningOverlay.show(
        context,
        onCompleted: () {
          if (mounted) Navigator.of(context).pop();
        },
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _handleDoubleRewardTap() {
    if (_doubleRewardClaimed || _doubleRewardBusy || !_canDoubleReward) return;
    setState(() => _doubleRewardBusy = true);

    BattleAdsService.instance.showDoubleRewardAd(
      onRewarded: () async {
        await ref.read(walletProvider.notifier).awardMultiple(
              ink: _grantedInk,
              paint: _grantedPaint,
              source: 'ad_double_ink',
            );
        if (_grantedXp > 0) {
          await ref.read(accountLevelProvider.notifier).addXp(_grantedXp);
        }
        if (mounted) {
          setState(() {
            _doubleRewardClaimed = true;
            _doubleRewardBusy = false;
            _remainingDoubleRewards = BattleAdsService.instance.remainingDoubleRewards;
          });
        }
      },
      onDismissed: () {
        if (mounted) {
          setState(() => _doubleRewardBusy = false);
        }
      },
    );
  }
}


class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.isVictory, required this.primaryColor});
  final bool isVictory;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
      decoration: BoxDecoration(
        color: isVictory ? const Color(0xFFFFCC00) : AppColors.paperWhite,
        border: Border.all(color: const Color(0xFF1A1A1A), width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF1A1A1A),
            offset: Offset(4, 5),
          ),
        ],
      ),
      transform: Matrix4.rotationZ(isVictory ? -0.04 : 0.03),
      child: Text(
        isVictory ? 'VICTORY!' : 'DEFEATED',
        style: const TextStyle(
          fontFamily: 'Bangers',
          fontSize: 38,
          letterSpacing: 6,
          color: Color(0xFF1A1A1A),
        ),
      ),
    );
  }
}


class _RewardsCard extends AnimatedWidget {
  const _RewardsCard({
    required this.ink,
    required this.paint,
    required this.xp,
    required this.isFirstClear,
    required this.isTierComplete,
    required Animation<double> counter,
  }) : super(listenable: counter);

  final int ink;
  final int paint;
  final int xp;
  final bool isFirstClear;
  final bool isTierComplete;

  Animation<double> get counter => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    final curInk = (ink * counter.value).round();
    final curPaint = (paint * counter.value).round();
    final curXp = (xp * counter.value).round();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.paperWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1A1A1A), width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF1A1A1A),
            offset: Offset(4, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Icon(Icons.water_drop,
                      color: Color(0xFF1A1A1A), size: 28),
                  const SizedBox(height: 6),
                  Text(
                    '+$curInk',
                    style: const TextStyle(
                      fontFamily: 'Bangers',
                      fontSize: 22,
                      letterSpacing: 1.5,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const Text(
                    'INK',
                    style: TextStyle(
                        fontSize: 10, color: Colors.black54, letterSpacing: 2, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              Column(
                children: [
                  const Icon(Icons.palette, color: Color(0xFFFF8F00), size: 28),
                  const SizedBox(height: 6),
                  Text(
                    '+$curPaint',
                    style: const TextStyle(
                      fontFamily: 'Bangers',
                      fontSize: 22,
                      letterSpacing: 1.5,
                      color: Color(0xFFFF8F00),
                    ),
                  ),
                  const Text(
                    'PAINT',
                    style: TextStyle(
                        fontSize: 10, color: Colors.black54, letterSpacing: 2, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              Column(
                children: [
                  const Icon(Icons.stars, color: Color(0xFF8E24AA), size: 28),
                  const SizedBox(height: 6),
                  Text(
                    '+$curXp',
                    style: const TextStyle(
                      fontFamily: 'Bangers',
                      fontSize: 22,
                      letterSpacing: 1.5,
                      color: Color(0xFF8E24AA),
                    ),
                  ),
                  const Text(
                    'XP',
                    style: TextStyle(
                        fontSize: 10, color: Colors.black54, letterSpacing: 2, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          if (isFirstClear || isTierComplete) ...[
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFE0E0E0), height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isFirstClear)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color:
                              const Color(0xFFFF9800), width: 1.5),
                    ),
                    child: const Text(
                      'FIRST CLEAR BONUS!',
                      style: TextStyle(
                        fontFamily: 'Bangers',
                        fontSize: 11,
                        letterSpacing: 1.5,
                        color: Color(0xFFE65100),
                      ),
                    ),
                  ),
                if (isTierComplete)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color:
                              const Color(0xFF4CAF50), width: 1.5),
                    ),
                    child: const Text(
                      'TIER COMPLETE BONUS!',
                      style: TextStyle(
                        fontFamily: 'Bangers',
                        fontSize: 11,
                        letterSpacing: 1.5,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}


class _DefeatStatsCard extends StatelessWidget {
  const _DefeatStatsCard({required this.result});
  final BattleResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.paperWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1A1A1A), width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF1A1A1A),
            offset: Offset(4, 4),
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(Icons.heart_broken_outlined, color: Color(0xFFE53935), size: 36),
          SizedBox(height: 12),
          Text(
            'DEFEAT IS NOT THE END',
            style: TextStyle(
              fontFamily: 'Bangers',
              fontSize: 20,
              letterSpacing: 2,
              color: Color(0xFF1A1A1A),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Improve stats, unlock new character skills, and try again!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}


class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.result});
  final BattleResult result;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _StatTile(label: 'PARRIES', value: '${result.parryCount}'),
        _StatTile(label: 'DODGES', value: '${result.dodgeCount}'),
        _StatTile(label: 'SHIELD BREAKS', value: '${result.brokenCount}'),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.paperWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1A1A1A), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF1A1A1A),
            offset: Offset(2, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Bangers',
              fontSize: 24,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}


class _HalftoneBurst extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BurstPainter(),
    );
  }
}

class _BurstPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = const Color(0xFF1A1A1A).withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;

    const rays = 18;
    final angleStep = (2 * 3.14159) / rays;

    final path = Path();
    for (int i = 0; i < rays; i++) {
      final startAngle = i * angleStep;
      final endAngle = startAngle + (angleStep * 0.5);

      path.moveTo(center.dx, center.dy);
      path.arcTo(
        Rect.fromCircle(center: center, radius: size.width * 1.5),
        startAngle,
        endAngle - startAngle,
        false,
      );
      path.close();
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) => false;
}


class _DoubleRewardButton extends StatelessWidget {
  const _DoubleRewardButton({
    required this.canShow,
    required this.claimed,
    required this.busy,
    required this.remaining,
    required this.onTap,
  });

  final bool canShow;
  final bool claimed;
  final bool busy;
  final int remaining;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (!canShow || claimed) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: busy ? null : () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0xFFFFCC00),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF1A1A1A), width: 2.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF1A1A1A),
              offset: Offset(3, 4),
            ),
          ],
        ),
        child: Center(
          child: busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF1A1A1A),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_circle_fill,
                        color: Color(0xFF1A1A1A), size: 22),
                    const SizedBox(width: 8),
                    const Text(
                      'WATCH AD FOR 2× REWARDS',
                      style: TextStyle(
                        fontFamily: 'Bangers',
                        fontSize: 17,
                        letterSpacing: 2,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$remaining left',
                        style: const TextStyle(
                          fontFamily: 'Bangers',
                          fontSize: 11,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: 1,
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


class _ContinueButton extends StatelessWidget {
  const _ContinueButton({
    required this.primaryColor,
    required this.label,
    this.isSecondary = false,
    this.onTap,
  });

  final Color primaryColor;
  final String label;
  final bool isSecondary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (onTap != null) {
          onTap!();
        } else {
          Navigator.of(context).pop();
        }
      },
      child: Container(
        height: isSecondary ? 46 : 54,
        decoration: BoxDecoration(
          color: isSecondary ? AppColors.paperWhite : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF1A1A1A),
            width: 2.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF1A1A1A),
              offset: Offset(3, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Bangers',
              fontSize: isSecondary ? 15 : 18,
              letterSpacing: isSecondary ? 2 : 3,
              color: isSecondary ? const Color(0xFF1A1A1A) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}


class _DoubleRewardClaimedBadge extends StatelessWidget {
  const _DoubleRewardClaimedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF4CAF50),
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF1A1A1A),
            offset: Offset(2, 3),
          ),
        ],
      ),
      child: const Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 18),
            SizedBox(width: 8),
            Text(
              '2× REWARDS CLAIMED!',
              style: TextStyle(
                fontFamily: 'Bangers',
                fontSize: 14,
                letterSpacing: 2,
                color: Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
