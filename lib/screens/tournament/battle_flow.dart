import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colosynth/game_settings.dart';
import 'package:colosynth/services/audio_service.dart';

import 'package:colosynth/providers/account_provider.dart';
import 'package:colosynth/game_data/level_data.dart';
import 'package:colosynth/services/interstitial_ad_service.dart';
import 'package:colosynth/game/app_shell/battle_screen.dart';
import 'package:colosynth/game/event_bus/game_events.dart';
import 'package:colosynth/screens/ready/ready_screen.dart';
import 'package:colosynth/screens/result/result_screen.dart';

import 'package:colosynth/story/story_database.dart';
import 'package:colosynth/story/story_controller.dart';
import 'package:colosynth/story/ui/story_overlay.dart';


void playSfx() {
  AudioService.instance.playSfx(SfxEvent.button);
}

class TournamentBattleFlow {
  const TournamentBattleFlow();

  static bool _isFighting = false;

  Future<void> fight({
    required BuildContext context,
    required WidgetRef ref,
    required TSlot slot,
  }) async {
    if (_isFighting) return;
    _isFighting = true;

    try {
      final rootNav = Navigator.of(context, rootNavigator: true);

      final readyResult = await rootNav.push<ReadyResult>(
        PageRouteBuilder(
          opaque: false,
          pageBuilder: (context, animation, secondaryAnimation) => ReadyScreen(
            enemyId: slot.id,
            enemyName: slot.enemyName,
            aiProfile: slot.profile,
            tournamentTier: slot.tournamentTier,
            isBoss: slot.isBoss,
            isExtreme: slot.isExtreme,
            skipLightningEntrance: false,
          ),
          transitionDuration: const Duration(milliseconds: 200),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );

      if (readyResult == null || !readyResult.confirmed) return;

      await ref
          .read(equippedCharacterIdProvider.notifier)
          .setEquippedCharacter(readyResult.characterId);
      unawaited(AudioService.instance.playBgm(BgmTrack.battle));

      final params = BattleGameParams(
        slotId: slot.id,
        aiProfile: slot.profile,
        tier: slot.tournamentTier,
        mode: slot.id.startsWith('tutorial_')
            ? BattleMode.tutorial
            : BattleMode.tournament,
      );

      final introStory = StoryDatabase.getIntroForLevel(slot.id);
      if (introStory != null && rootNav.overlay != null) {
        final storyOverlayEntry = OverlayEntry(
          builder: (_) => const StoryOverlay(),
        );
        rootNav.overlay!.insert(storyOverlayEntry);
        try {
          await ref.read(storyStateProvider.notifier).startStory(introStory);
        } finally {
          storyOverlayEntry.remove();
        }
      }

      final result = await rootNav.push<BattleResult?>(
        PageRouteBuilder<BattleResult?>(
          pageBuilder: (context, animation, secondaryAnimation) => BattleScreen(
            params: params,
            tournamentStage: slot.id,
            tournamentTier: slot.tournamentTier,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 200),
        ),
      );

      if (result == null || result.outcome == BattleOutcome.quit) {
        return;
      }

      final outroStory = StoryDatabase.getOutroForLevel(slot.id);
      if (outroStory != null && rootNav.overlay != null) {
        final storyOverlayEntry = OverlayEntry(
          builder: (_) => const StoryOverlay(),
        );
        rootNav.overlay!.insert(storyOverlayEntry);
        try {
          await ref.read(storyStateProvider.notifier).startStory(outroStory);
        } finally {
          storyOverlayEntry.remove();
        }
      }

      if (rootNav.mounted) {
        await ResultScreen.push(rootNav.context, result: result, slot: slot);
      }

      if (result.outcome == BattleOutcome.victory && slot.isBoss) {
        unawaited(InterstitialAdService.instance.show());
      } else if (result.outcome != BattleOutcome.quit) {
        unawaited(InterstitialAdService.instance.recordBattleAndMaybeShow());
      }
    } finally {
      _isFighting = false;
      unawaited(AudioService.instance.playBgm(BgmTrack.home));
    }
  }

  static ArenaData arenaForTier(int tier) {
    return kArenas.firstWhere(
      (a) => a.tournaments.any((t) => t.tier == tier),
      orElse: () => kArenas.first,
    );
  }
}

