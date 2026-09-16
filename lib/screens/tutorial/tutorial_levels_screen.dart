import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colosynth/game/ai/ai_profiles.dart';
import 'package:colosynth/game_data/level_data.dart';
import 'package:colosynth/providers/tournament_provider.dart';
import 'package:colosynth/providers/tutorial_provider.dart';
import 'package:colosynth/services/audio_service.dart';
import 'package:colosynth/game_settings.dart';
import 'package:colosynth/screens/theme/tokens.dart';
import 'package:colosynth/screens/theme/background.dart';
import 'package:colosynth/screens/tournament/battle_flow.dart';
import 'package:colosynth/services/review_service.dart';

final kTutorialSlots = [
  const TSlot(
    id: 'tutorial_0',
    enemyName: 'CHALK DUMMY',
    profile: AiProfile(
      id: 'easy',
      telegraphDuration: 1.2,
      attackInterval: 2.0,
      blockProbability: 0.20,
      dodgeProbability: 0.0,
      comboProbability: 0.0,
      activeSkillEnabled: false,
      bpm: 120,
      staminaMax: 80,
    ),
    tournamentTier: 1,
    accentColor: AppColors.comicYellow,
  ),
  const TSlot(
    id: 'tutorial_1',
    enemyName: 'SCRAWL',
    profile: AiProfile(
      id: 'easy',
      telegraphDuration: 1.2,
      attackInterval: 2.0,
      blockProbability: 0.20,
      dodgeProbability: 0.0,
      comboProbability: 0.0,
      activeSkillEnabled: false,
      bpm: 120,
      staminaMax: 100,
    ),
    tournamentTier: 1,
    accentColor: AppColors.comicBlue,
  ),
  const TSlot(
    id: 'tutorial_2',
    enemyName: 'CREASE',
    profile: AiProfile(
      id: 'easy',
      telegraphDuration: 1.2,
      attackInterval: 2.0,
      blockProbability: 0.20,
      dodgeProbability: 0.0,
      comboProbability: 0.0,
      activeSkillEnabled: false,
      bpm: 120,
      staminaMax: 120,
    ),
    tournamentTier: 1,
    accentColor: AppColors.comicRed,
  ),
];

class TutorialLevelsScreen extends ConsumerStatefulWidget {
  const TutorialLevelsScreen({super.key});

  @override
  ConsumerState<TutorialLevelsScreen> createState() =>
      _TutorialLevelsScreenState();
}

class _TutorialLevelsScreenState extends ConsumerState<TutorialLevelsScreen> {
  static const _flow = TournamentBattleFlow();
  bool _completionScheduled = false;

  @override
  void initState() {
    super.initState();
    AudioService.instance.playBgm(BgmTrack.home);
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(tournamentProgressProvider);
    final tutorialDone = ref.watch(tutorialCompletedProvider);

    if (progress.containsKey('tutorial_2') &&
        !tutorialDone &&
        !_completionScheduled) {
      _completionScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(tutorialStateProvider.notifier).complete();
          unawaited(ReviewService.instance.requestTutorialCompletionReview());
        }
      });
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            const Positioned.fill(child: NotebookBackground()),
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 52),
                  _buildHeader(context),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      itemCount: kTutorialSlots.length,
                      itemBuilder: (ctx, index) {
                        final slot = kTutorialSlots[index];
                        final isCompleted = progress.containsKey(slot.id);
                        final isUnlocked = index == 0 ||
                            progress.containsKey(kTutorialSlots[index - 1].id);

                        return _buildLevelCard(
                          context: context,
                          index: index,
                          slot: slot,
                          isUnlocked: isUnlocked,
                          isCompleted: isCompleted,
                          delayMs: index * 100,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              AudioService.instance.playSfx(SfxEvent.button);
              Navigator.of(context).pop();
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.ink.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: AppColors.ink, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TRAINING GROUNDS',
                  style: TextStyle(
                    fontFamily: 'Bangers',
                    fontSize: 28,
                    color: AppColors.ink,
                    letterSpacing: 5,
                  ),
                ),
                Text(
                  'Master the brush strokes to enter the tournaments',
                  style: TextStyle(
                    color: AppColors.ink.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard({
    required BuildContext context,
    required int index,
    required TSlot slot,
    required bool isUnlocked,
    required bool isCompleted,
    required int delayMs,
  }) {
    final title = 'TUTORIAL LEVEL ${index + 1}';
    final String objective;
    final String enemyEmoji;
    switch (index) {
      case 0:
        objective = 'Tap and slash the dummy. Master basic combat tempo.';
        enemyEmoji = '🤖';
        break;
      case 1:
        objective = 'Reposition using dodge and parry chalk strokes.';
        enemyEmoji = '⚔️';
        break;
      case 2:
      default:
        objective = 'Charge active skills to deliver final blows.';
        enemyEmoji = '🔥';
        break;
    }

    final cardColor = isCompleted
        ? const Color(0xFFF1F8E9)
        : (!isUnlocked ? const Color(0xFFF5F5F5) : Colors.white);

    final borderColor = !isUnlocked
        ? Colors.grey.shade300
        : (isCompleted ? const Color(0xFF81C784) : AppColors.ink);

    return GestureDetector(
      onTap: isUnlocked
          ? () {
              AudioService.instance.playSfx(SfxEvent.button);
              _flow.fight(
                context: context,
                ref: ref,
                slot: slot,
              );
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2.5),
          boxShadow: !isUnlocked || isCompleted
              ? null
              : const [
                  BoxShadow(
                    color: AppColors.ink,
                    offset: Offset(4, 4),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? slot.accentColor.withValues(alpha: 0.15)
                      : Colors.grey.shade200,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isUnlocked ? slot.accentColor : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    isUnlocked ? enemyEmoji : '🔒',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Bangers',
                        fontSize: 20,
                        letterSpacing: 1.5,
                        color:
                            isUnlocked ? AppColors.ink : Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      slot.enemyName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 1,
                        color: isUnlocked ? slot.accentColor : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      objective,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.3,
                        color: isUnlocked
                            ? AppColors.ink.withValues(alpha: 0.6)
                            : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _buildStatusWidget(context, isUnlocked, isCompleted, slot),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delayMs), duration: 250.ms)
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildStatusWidget(
    BuildContext context,
    bool isUnlocked,
    bool isCompleted,
    TSlot slot,
  ) {
    if (!isUnlocked) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock, color: Colors.grey, size: 20),
          SizedBox(height: 4),
          Text(
            'LOCKED',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ],
      );
    }

    if (isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.ink, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: AppColors.ink,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: const Text(
          'REPLAY',
          style: TextStyle(
            fontFamily: 'Bangers',
            fontSize: 12,
            letterSpacing: 1,
            color: Colors.white,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.comicYellow,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.ink, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.ink,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: const Text(
        'FIGHT',
        style: TextStyle(
          fontFamily: 'Bangers',
          fontSize: 14,
          letterSpacing: 1.5,
          color: Colors.black,
        ),
      ),
    );
  }
}
