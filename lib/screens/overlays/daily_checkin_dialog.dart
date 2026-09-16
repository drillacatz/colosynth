import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colosynth/providers/daily_checkin_provider.dart';
import 'package:colosynth/services/daily_checkin_service.dart';
import 'package:colosynth/services/audio_service.dart';
import 'package:colosynth/game_settings.dart';
import 'package:colosynth/screens/theme/tokens.dart';

class DailyCheckInDialog extends ConsumerWidget {
  const DailyCheckInDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => const DailyCheckInDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkInState = ref.watch(dailyCheckInProvider);
    final notifier = ref.read(dailyCheckInProvider.notifier);

    final nextDayIndex =
        checkInState.currentCycleDay < 7 ? checkInState.currentCycleDay + 1 : 7;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440, minHeight: 540),
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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/daily_login.png',
                    height: 135,
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, err, stack) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.calendar_month,
                            color: AppColors.comicRed, size: 28),
                        SizedBox(width: 8),
                        Text(
                          'DAILY CHECK-IN',
                          style: TextStyle(
                            fontFamily: 'Bangers',
                            color: AppColors.ink,
                            fontSize: 24,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        ComicButton.playButtonSfx();
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.ink, width: 2),
                        ),
                        child:
                            const Icon(Icons.close, color: AppColors.ink, size: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (checkInState.missedYesterday &&
                    checkInState.makeUpUsedInCycle == 0)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.comicRed.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.comicRed, width: 2),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: AppColors.comicRed, size: 22),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You missed yesterday! Use Make-Up ad to save your streak.',
                            style: TextStyle(
                              fontFamily: 'Bangers',
                              color: AppColors.comicRed,
                              fontSize: 12,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                Row(
                  children: [
                    for (int day = 1; day <= 4; day++) ...[
                      if (day > 1) const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: SizedBox(
                          height: 110,
                          child: _buildRewardCardForDay(
                            context: context,
                            day: day,
                            checkInState: checkInState,
                            nextDayIndex: nextDayIndex,
                            notifier: notifier,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 110,
                        child: _buildRewardCardForDay(
                          context: context,
                          day: 5,
                          checkInState: checkInState,
                          nextDayIndex: nextDayIndex,
                          notifier: notifier,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 110,
                        child: _buildRewardCardForDay(
                          context: context,
                          day: 6,
                          checkInState: checkInState,
                          nextDayIndex: nextDayIndex,
                          notifier: notifier,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 110,
                        child: _buildRewardCardForDay(
                          context: context,
                          day: 7,
                          checkInState: checkInState,
                          nextDayIndex: nextDayIndex,
                          notifier: notifier,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                _buildActionButtons(context, checkInState, notifier),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRewardCardForDay({
    required BuildContext context,
    required int day,
    required DailyCheckInState checkInState,
    required int nextDayIndex,
    required DailyCheckInNotifier notifier,
  }) {
    final reward = DailyCheckInService.instance.getRewardForDay(day);
    final isCurrentDay = checkInState.currentCycleDay == day;
    final isClaimed = day < checkInState.currentCycleDay ||
        (isCurrentDay && checkInState.isClaimedToday);

    final isNextDay = day == nextDayIndex;
    final canPreClaimNextDay = isNextDay &&
        !checkInState.isAdvanceClaimedTomorrow &&
        checkInState.advanceClaimUsedInCycle == 0 &&
        checkInState.isClaimedToday;

    return _buildRewardCard(
      context: context,
      day: day,
      reward: reward,
      isCurrentDay: isCurrentDay,
      isNextDayCanPreClaim: canPreClaimNextDay,
      isClaimed: isClaimed,
      notifier: notifier,
    );
  }

  Widget _buildRewardCard({
    required BuildContext context,
    required int day,
    required CheckInReward reward,
    required bool isCurrentDay,
    required bool isNextDayCanPreClaim,
    required bool isClaimed,
    required DailyCheckInNotifier notifier,
  }) {
    IconData iconData = Icons.water_drop;
    Color iconColor = AppColors.comicBlue;
    if (reward.paint > 0) {
      iconData = Icons.brush;
      iconColor = AppColors.comicRed;
    } else if (reward.itemKey != null) {
      iconData = Icons.auto_stories;
      iconColor = AppColors.comicYellow;
    }

    final isDay7 = day == 7;

    return Container(
      decoration: BoxDecoration(
        color: isCurrentDay
            ? AppColors.comicYellow
            : (isNextDayCanPreClaim
                ? const Color(0xFFE3F2FD)
                : (isClaimed
                    ? Colors.black.withValues(alpha: 0.05)
                    : Colors.white)),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrentDay
              ? AppColors.ink
              : (isNextDayCanPreClaim
                  ? AppColors.comicBlue
                  : (isDay7
                      ? AppColors.comicRed
                      : AppColors.ink.withValues(alpha: 0.7))),
          width: (isCurrentDay || isNextDayCanPreClaim) ? 2.5 : 1.5,
        ),
        boxShadow: isCurrentDay || isNextDayCanPreClaim
            ? [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.35),
                  blurRadius: 0,
                  offset: const Offset(3, 3),
                ),
              ]
            : [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.15),
                  blurRadius: 0,
                  offset: const Offset(2, 2),
                ),
              ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'DAY $day',
            style: TextStyle(
              fontFamily: 'Bangers',
              color: isCurrentDay
                  ? AppColors.ink
                  : (isNextDayCanPreClaim
                      ? AppColors.comicBlue
                      : AppColors.sketchGray),
              fontSize: 12,
              letterSpacing: 1.0,
            ),
          ),
          Icon(
            isClaimed ? Icons.check_circle : iconData,
            color: isClaimed ? AppColors.comicGreen : iconColor,
            size: 24,
          ),
          Text(
            reward.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Bangers',
              color: isClaimed ? AppColors.sketchGray : AppColors.ink,
              fontSize: 10,
              letterSpacing: 0.6,
            ),
          ),
          if (isNextDayCanPreClaim)
            GestureDetector(
              onTap: () async {
                ComicButton.playButtonSfx();
                final ok = await notifier.claimTomorrowWithAd();
                if (ok && context.mounted) {
                  AudioService.instance.playSfx(SfxEvent.reward);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Tomorrow\'s Reward Pre-Claimed!')),
                  );
                }
              },
              child: Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.comicBlue,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.ink, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.ondemand_video,
                  size: 13,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    DailyCheckInState state,
    DailyCheckInNotifier notifier,
  ) {
    if (state.missedYesterday && state.makeUpUsedInCycle == 0) {
      return Column(
        children: [
          ComicButton(
            label: 'MAKE-UP CHECK-IN (AD)',
            leading:
                const Icon(Icons.ondemand_video, size: 18, color: Colors.white),
            style: PBStyle.dark,
            fontSize: 13,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            onTap: () async {
              ComicButton.playButtonSfx();
              final ok = await notifier.makeUpWithAd();
              if (ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Streak Restored & Reward Claimed!')),
                );
              }
            },
          ),
          const SizedBox(height: 6),
          TextButton(
            style: TextButton.styleFrom(
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            ),
            onPressed: () async {
              ComicButton.playButtonSfx();
              await notifier.claimToday();
            },
            child: const Text(
              'Reset to Day 1 and Claim Normal',
              style: TextStyle(
                fontFamily: 'Bangers',
                color: AppColors.sketchGray,
                fontSize: 13,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      );
    }

    if (!state.isClaimedToday) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ComicButton(
            label: 'CLAIM 2X REWARD (AD)',
            leading: const Icon(Icons.ondemand_video,
                size: 18, color: AppColors.comicYellow),
            style: PBStyle.dark,
            fontSize: 14,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            onTap: () async {
              ComicButton.playButtonSfx();
              final ok = await notifier.claimTodayWithDoubleAd();
              if (ok && context.mounted) {
                AudioService.instance.playSfx(SfxEvent.reward);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('2X Reward Claimed Successfully!')),
                );
              }
            },
          ),
          const SizedBox(height: 6),
          TextButton(
            style: TextButton.styleFrom(
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            ),
            onPressed: () async {
              ComicButton.playButtonSfx();
              final ok = await notifier.claimToday();
              if (ok && context.mounted) {
                AudioService.instance.playSfx(SfxEvent.reward);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reward Claimed Successfully!')),
                );
              }
            },
            child: const Text(
              'Claim Normal Reward (1X)',
              style: TextStyle(
                fontFamily: 'Bangers',
                color: AppColors.sketchGray,
                fontSize: 13,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      );
    }

    if (!state.isDoubleClaimedToday) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.comicGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.comicGreen, width: 1.5),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle,
                    color: AppColors.comicGreen, size: 20),
                SizedBox(width: 6),
                Text(
                  '1X REWARD CLAIMED',
                  style: TextStyle(
                    fontFamily: 'Bangers',
                    color: AppColors.comicGreen,
                    fontSize: 14,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ComicButton(
            label: 'DOUBLE REWARD (AD)',
            leading: const Icon(Icons.ondemand_video,
                size: 16, color: AppColors.comicYellow),
            style: PBStyle.dark,
            fontSize: 13,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            onTap: () async {
              ComicButton.playButtonSfx();
              final ok = await notifier.claimDoubleWithAd();
              if (ok && context.mounted) {
                AudioService.instance.playSfx(SfxEvent.reward);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reward Doubled!')),
                );
              }
            },
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.comicGreen.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.comicGreen, width: 1.5),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: AppColors.comicGreen, size: 20),
          SizedBox(width: 6),
          Text(
            'TODAY\'S REWARD CLAIMED (2X)!',
            style: TextStyle(
              fontFamily: 'Bangers',
              color: AppColors.comicGreen,
              fontSize: 14,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
