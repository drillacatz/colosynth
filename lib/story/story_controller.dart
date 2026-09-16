import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:colosynth/story/models/story_node.dart';
import 'package:colosynth/story/models/story_sequence.dart';
import 'package:colosynth/services/audio_service.dart';

/// Immutable state containing progress of narrative story playback.
class StoryState {
  final StorySequence? activeStory;
  final int currentNodeIndex;
  final bool isTypingCompleted;
  final bool isCompleted;

  const StoryState({
    this.activeStory,
    this.currentNodeIndex = 0,
    this.isTypingCompleted = false,
    this.isCompleted = false,
  });

  bool get isActive => activeStory != null && !isCompleted;

  StoryNode? get currentNode {
    if (activeStory == null ||
        currentNodeIndex < 0 ||
        currentNodeIndex >= activeStory!.nodes.length) {
      return null;
    }
    return activeStory!.nodes[currentNodeIndex];
  }

  StoryState copyWith({
    StorySequence? activeStory,
    int? currentNodeIndex,
    bool? isTypingCompleted,
    bool? isCompleted,
  }) {
    return StoryState(
      activeStory: activeStory ?? this.activeStory,
      currentNodeIndex: currentNodeIndex ?? this.currentNodeIndex,
      isTypingCompleted: isTypingCompleted ?? this.isTypingCompleted,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// Provider for narrative story state.
final storyStateProvider =
    NotifierProvider<StoryNotifier, StoryState>(StoryNotifier.new);

/// Notifier managing active story playback and progression.
class StoryNotifier extends Notifier<StoryState> {
  Completer<void>? _completionCompleter;

  @override
  StoryState build() {
    return const StoryState();
  }

  /// Starts playing a narrative story sequence. Returns a Future that completes when finished or skipped.
  Future<void> startStory(StorySequence story) async {
    _completionCompleter = Completer<void>();
    state = StoryState(
      activeStory: story,
      currentNodeIndex: 0,
      isTypingCompleted: false,
      isCompleted: false,
    );

    if (story.defaultBgm != null) {
      await AudioService.instance.pauseBgm();
    }

    return _completionCompleter!.future;
  }

  void setTypingCompleted(bool completed) {
    state = state.copyWith(isTypingCompleted: completed);
  }

  Future<void> advance() async {
    final active = state.activeStory;
    if (active == null || state.isCompleted) return;

    if (!state.isTypingCompleted) {
      state = state.copyWith(isTypingCompleted: true);
      return;
    }

    final nextIndex = state.currentNodeIndex + 1;
    if (nextIndex >= active.nodes.length) {
      await finish();
    } else {
      state = state.copyWith(
        currentNodeIndex: nextIndex,
        isTypingCompleted: false,
      );
    }
  }

  Future<void> skip() async {
    if (!state.isActive) return;
    if (state.activeStory?.isSkippable == false) return;
    await finish();
  }

  Future<void> finish() async {
    if (!state.isActive) return;

    if (state.activeStory?.defaultBgm != null) {
      await AudioService.instance.resumeBgm();
    }

    state = state.copyWith(isCompleted: true);

    if (_completionCompleter != null && !_completionCompleter!.isCompleted) {
      _completionCompleter!.complete();
    }
  }
}
