import 'package:shared_preferences/shared_preferences.dart';
import 'package:colosynth/game/event_bus/game_event_bus.dart';
import 'package:colosynth/game/event_bus/game_events.dart';
import 'package:colosynth/game/logic/tutorial_stage_data.dart';

class TutorialService {
  TutorialService._();
  static final TutorialService instance = TutorialService._();

  static const _kTutorialCompletedKey = 'colosynth_tutorial_completed';
  static const _kTutorialSkippedKey = 'colosynth_tutorial_skipped';
  static const _kCurrentStepKey = 'colosynth_tutorial_current_step';

  SharedPreferences? _prefs;

  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
  }

  bool get isTutorialComplete {
    return _prefs?.getBool(_kTutorialCompletedKey) ?? false;
  }

  bool get isTutorialSkipped {
    return _prefs?.getBool(_kTutorialSkippedKey) ?? false;
  }

  bool get shouldShowTutorial => !isTutorialComplete && !isTutorialSkipped;

  int get currentStepIndex {
    return _prefs?.getInt(_kCurrentStepKey) ?? 0;
  }

  TutorialStep get currentStep {
    final idx = currentStepIndex.clamp(0, kTutorialSteps.length - 1);
    return kTutorialSteps[idx];
  }

  bool get isLastStep => currentStepIndex >= kTutorialSteps.length - 1;

  Future<void> advanceStep() async {
    final next = currentStepIndex + 1;
    if (next >= kTutorialSteps.length) {
      await completeTutorial();
    } else {
      await _prefs?.setInt(_kCurrentStepKey, next);
    }
  }

  Future<void> completeTutorial() async {
    await Future.wait([
      _prefs?.setBool(_kTutorialCompletedKey, true) ?? Future.value(),
      _prefs?.remove(_kCurrentStepKey) ?? Future.value(),
    ]);
    GameEventBus.instance.emit(const TutorialCompletedEvent());
  }

  Future<void> skipTutorial() async {
    await Future.wait([
      _prefs?.setBool(_kTutorialSkippedKey, true) ?? Future.value(),
      _prefs?.remove(_kCurrentStepKey) ?? Future.value(),
    ]);
    GameEventBus.instance.emit(const TutorialSkippedEvent());
  }

  Future<void> resetTutorial() async {
    await Future.wait([
      _prefs?.remove(_kTutorialCompletedKey) ?? Future.value(),
      _prefs?.remove(_kTutorialSkippedKey) ?? Future.value(),
      _prefs?.remove(_kCurrentStepKey) ?? Future.value(),
    ]);
  }

  /// Call this when a required action is detected during tutorial battle.
  /// Returns true if the action matched the current step's requirement.
  bool notifyAction(TutorialRequiredAction action) {
    final step = currentStep;
    if (step.requiredAction == action) {
      return true;
    }
    return false;
  }
}
