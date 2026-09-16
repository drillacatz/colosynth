import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colosynth/guide/models/guide_step.dart';
import 'package:colosynth/guide/models/guide_sequence.dart';
import 'package:colosynth/guide/guide_assets.dart';
import 'package:colosynth/guide/guide_persistence.dart';
import 'package:colosynth/services/audio_service.dart';


/// Immutable state snapshot of the guide system.
///
/// Read by [GuideOverlay] to decide what to render. The controller never
/// touches navigation or widget tree directly — it only mutates this state.
class GuideState {
  final GuideSequence? activeGuide;
  final int currentStepIndex;
  final bool isTypingCompleted;
  final bool isCompleted;

  const GuideState({
    this.activeGuide,
    this.currentStepIndex = 0,
    this.isTypingCompleted = false,
    this.isCompleted = false,
  });

  /// Whether a guide is currently active and not yet finished.
  bool get isActive => activeGuide != null && !isCompleted;

  /// The current step being displayed, or `null` if no guide is active.
  GuideStep? get currentStep {
    if (activeGuide == null ||
        currentStepIndex < 0 ||
        currentStepIndex >= activeGuide!.steps.length) {
      return null;
    }
    return activeGuide!.steps[currentStepIndex];
  }

  /// Progress fraction (0.0 – 1.0) for progress indicators.
  double get progress {
    if (activeGuide == null || activeGuide!.isEmpty) return 0;
    return (currentStepIndex + 1) / activeGuide!.length;
  }

  GuideState copyWith({
    GuideSequence? activeGuide,
    int? currentStepIndex,
    bool? isTypingCompleted,
    bool? isCompleted,
  }) {
    return GuideState(
      activeGuide: activeGuide ?? this.activeGuide,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      isTypingCompleted: isTypingCompleted ?? this.isTypingCompleted,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}


final guideControllerProvider =
    NotifierProvider<GuideController, GuideState>(GuideController.new);


/// Manages the lifecycle of guide/tutorial playback.
///
/// Key architectural improvements over the old [StoryNotifier]:
/// 1. **No Navigator.pop()** — state-only; the overlay reads state to show/hide.
/// 2. **Completion callback via Future** — callers `await startGuide()` and
///    decide what to do when it finishes (pop route, show next screen, etc.).
/// 3. **Delegates audio to [AudioService]** — no local AudioPlayer instance.
/// 4. **Action-based advancement** — screens call `notifyAction(id)` to
///    advance steps that require specific user interactions.
class GuideController extends Notifier<GuideState> {
  Completer<void>? _completionCompleter;
  Timer? _autoAdvanceTimer;

  @override
  GuideState build() {
    ref.onDispose(() {
      _autoAdvanceTimer?.cancel();
    });
    return const GuideState();
  }


  /// Starts playing a guide sequence.
  ///
  /// Returns a [Future] that completes when the guide finishes or is skipped.
  /// The caller decides what to do next (e.g., pop a route, show a reward).
  ///
  /// If [force] is `true`, the guide plays even if already completed.
  /// Otherwise, completed guides are silently skipped.
  Future<void> startGuide(GuideSequence guide, {bool force = false}) async {
    if (!force && GuidePersistence.isCompleted(guide.id)) {
      return;
    }

    if (state.isActive) {
      await finish(markCompleted: false);
    }

    _completionCompleter = Completer<void>();

    state = GuideState(
      activeGuide: guide,
      currentStepIndex: 0,
      isTypingCompleted: false,
      isCompleted: false,
    );

    if (guide.defaultBgm != null) {
      await AudioService.instance.pauseBgm();
    }

    _playCurrentStepAudio();
    _scheduleAutoAdvance();

    return _completionCompleter!.future;
  }

  /// Marks typewriter animation as completed for the current step.
  /// Called by [TypewriterText] when it finishes revealing all characters.
  void setTypingCompleted(bool completed) {
    state = state.copyWith(isTypingCompleted: completed);
  }

  /// Advances the guide to the next step.
  ///
  /// Behavior depends on current state:
  /// - If typewriter is still running → instantly completes typing.
  /// - If typing is done → moves to next step.
  /// - If on the last step → finishes the guide.
  Future<void> advance() async {
    final guide = state.activeGuide;
    if (guide == null || state.isCompleted) return;

    final step = state.currentStep;

    if (step?.requiredAction != null && !state.isTypingCompleted) {
      return;
    }

    if (!state.isTypingCompleted &&
        (step?.type == GuideStepType.dialogue ||
         step?.type == GuideStepType.coachMark)) {
      state = state.copyWith(isTypingCompleted: true);
      return;
    }

    final nextIndex = state.currentStepIndex + 1;
    if (nextIndex >= guide.steps.length) {
      await finish();
    } else {
      _autoAdvanceTimer?.cancel();
      state = state.copyWith(
        currentStepIndex: nextIndex,
        isTypingCompleted: false,
      );
      _playCurrentStepAudio();
      _scheduleAutoAdvance();
    }
  }

  /// Called by screens when the user performs a specific action.
  ///
  /// If the current step is waiting for [actionId], the guide advances.
  /// Returns `true` if the action matched and the guide advanced.
  bool notifyAction(String actionId) {
    final step = state.currentStep;
    if (step == null || !state.isActive) return false;
    if (step.requiredAction == actionId) {
      advance();
      return true;
    }
    return false;
  }

  /// Skips the entire guide sequence.
  Future<void> skip() async {
    if (!state.isActive) return;
    if (state.activeGuide?.isSkippable == false) return;
    await finish();
  }

  /// Concludes guide playback, persists completion, restores BGM,
  /// and resolves the completion future.
  Future<void> finish({bool markCompleted = true}) async {
    if (!state.isActive && _completionCompleter == null) return;

    _autoAdvanceTimer?.cancel();

    if (state.activeGuide?.defaultBgm != null) {
      await AudioService.instance.resumeBgm();
    }

    if (markCompleted && state.activeGuide != null) {
      await GuidePersistence.markCompleted(state.activeGuide!.id);
    }

    state = state.copyWith(isCompleted: true);

    if (_completionCompleter != null && !_completionCompleter!.isCompleted) {
      _completionCompleter!.complete();
    }
    _completionCompleter = null;
  }


  void _playCurrentStepAudio() {
    final step = state.currentStep;
    if (step == null || step.isSilent || step.voiceSfxPath == null) return;

    try {
      final path = GuideAssets.voicePath(step.voiceSfxPath!);
      debugPrint('Guide: would play voice line: $path');
    } catch (e) {
      debugPrint('Guide voice playback error: $e');
    }
  }

  void _scheduleAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    final step = state.currentStep;
    if (step?.autoAdvanceMs == null) return;

    _autoAdvanceTimer = Timer(
      Duration(milliseconds: step!.autoAdvanceMs!),
      () {
        if (state.isActive) {
          advance();
        }
      },
    );
  }
}
