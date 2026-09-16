import 'package:colosynth/providers/save_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:colosynth/services/tutorial/tutorial_service.dart';
import 'package:colosynth/providers/auth_provider.dart';


class TutorialState {
  final bool isComplete;
  final bool isSkipped;
  final int currentStepIndex;

  const TutorialState({
    required this.isComplete,
    required this.isSkipped,
    required this.currentStepIndex,
  });

  bool get shouldShow => !isComplete && !isSkipped;

  TutorialState copyWith({
    bool? isComplete,
    bool? isSkipped,
    int? currentStepIndex,
  }) {
    return TutorialState(
      isComplete: isComplete ?? this.isComplete,
      isSkipped: isSkipped ?? this.isSkipped,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TutorialState &&
          other.isComplete == isComplete &&
          other.isSkipped == isSkipped &&
          other.currentStepIndex == currentStepIndex;

  @override
  int get hashCode => Object.hash(isComplete, isSkipped, currentStepIndex);
}


final tutorialStateProvider =
    NotifierProvider<TutorialStateNotifier, TutorialState>(
  TutorialStateNotifier.new,
);

class TutorialStateNotifier extends Notifier<TutorialState> {
  @override
  TutorialState build() {
    ref.watch(authStateProvider);
    ref.watch(saveSyncReadyProvider);
    final svc = TutorialService.instance;
    return TutorialState(
      isComplete: svc.isTutorialComplete,
      isSkipped: svc.isTutorialSkipped,
      currentStepIndex: svc.currentStepIndex,
    );
  }

  Future<void> advanceStep() async {
    final svc = TutorialService.instance;
    await svc.advanceStep();
    state = state.copyWith(
      isComplete: svc.isTutorialComplete,
      currentStepIndex: svc.currentStepIndex,
    );
  }

  Future<void> complete() async {
    await TutorialService.instance.completeTutorial();
    state = state.copyWith(isComplete: true);
  }

  Future<void> skip() async {
    await TutorialService.instance.skipTutorial();
    state = state.copyWith(isSkipped: true);
  }

  Future<void> reset() async {
    await TutorialService.instance.resetTutorial();
    state = const TutorialState(
      isComplete: false,
      isSkipped: false,
      currentStepIndex: 0,
    );
  }
}


final tutorialCompletedProvider = Provider<bool>((ref) {
  return ref.watch(tutorialStateProvider.select((s) => s.isComplete));
});

final tutorialShouldShowProvider = Provider<bool>((ref) {
  return ref.watch(tutorialStateProvider.select((s) => s.shouldShow));
});
