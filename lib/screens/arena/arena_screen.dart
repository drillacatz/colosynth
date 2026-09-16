import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colosynth/providers/save_provider.dart';
import 'package:colosynth/providers/daily_checkin_provider.dart';
import 'package:colosynth/services/level_progress_service.dart';
import 'package:colosynth/services/daily_task_service.dart';
import 'package:colosynth/guide/guide_anchor.dart';
import 'package:colosynth/screens/overlays/daily_task_overlay.dart';
import 'package:colosynth/screens/overlays/daily_checkin_dialog.dart';
import 'package:colosynth/screens/theme/tokens.dart';
import 'package:colosynth/providers/account_provider.dart';
import 'package:colosynth/character_viewer/character_model_viewer.dart';
import 'package:colosynth/screens/arena/arena_entry_panel.dart';

class ArenaScreen extends ConsumerWidget {
  const ArenaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerLevel = ref.watch(accountLevelProvider).accountLevel;
    final svc = ProgressionService.instance;
    final equippedCharId = ref.watch(equippedCharacterIdProvider);

    final dailyTasksUnlocked =
        svc.isUnlocked(UnlockableFeature.dailyTasksUnlocked, playerLevel);
    final endlessUnlocked =
        svc.isUnlocked(UnlockableFeature.endlessBattle, playerLevel);
    
    final showDailyTasksBadge = dailyTasksUnlocked &&
        ref.watch(dailyTaskNotifierProvider.select((s) => s.hasAnyClaimable));

    final checkInState = ref.watch(dailyCheckInProvider);
    final showDailyCheckInBadge =
        (!checkInState.isClaimedToday || checkInState.missedYesterday);

    return Stack(
      children: [
        Positioned(
          top: 100,
          left: 0,
          right: 0,
          height: 310,
          child: CharacterModelViewer(
            characterId: equippedCharId,
            height: 300,
            allowUserControl: true,
            autoRotate: true,
            showActionBar: false,
          ),
        ),
        Positioned(
          top: 120,
          right: 16,
          child: GuideAnchor(
            id: 'arena_daily_tasks',
            child: ComicSquareBtn(
              icon: Icons.assignment_outlined,
              onTap: dailyTasksUnlocked
                  ? () {
                      ComicButton.playButtonSfx();
                      DailyTaskOverlay.show(context);
                    }
                  : null,
              showBadge: showDailyTasksBadge,
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(
                begin: 0.2,
                end: 0,
                curve: Curves.easeOutCubic,
              ),
        ),
        Positioned(
          top: 184,
          right: 16,
          child: GuideAnchor(
            id: 'arena_daily_checkin',
            child: ComicSquareBtn(
              icon: Icons.calendar_month,
              onTap: () {
                ComicButton.playButtonSfx();
                DailyCheckInDialog.show(context);
              },
              showBadge: showDailyCheckInBadge,
            ),
          ).animate().fadeIn(delay: 150.ms, duration: 400.ms).slideY(
                begin: 0.2,
                end: 0,
                curve: Curves.easeOutCubic,
              ),
        ),

        Positioned(
          bottom: 124,
          left: 0,
          right: 0,
          child: ArenaEntryPanel(
            endlessUnlocked: endlessUnlocked,
          ),
        ),
      ],
    );
  }
}
