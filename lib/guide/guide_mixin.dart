import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colosynth/guide/guide_controller.dart';
import 'package:colosynth/guide/guide_database.dart';
import 'package:colosynth/guide/guide_persistence.dart';

/// Mixin for [ConsumerStatefulWidget] screens that adds guide/tutorial
/// integration with minimal boilerplate.
///
/// Usage:
/// ```dart
/// class _ArenaScreenState extends ConsumerState<ArenaScreen>
///     with GuideAwareScreen {
///
///   @override
///   String? get guideSequenceId => 'arena_guide';
///
///   @override
///   void initState() {
///     super.initState();
///     maybeShowGuide();
///   }
/// }
/// ```
mixin GuideAwareScreen<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  /// Override to specify which guide sequence this screen should auto-show
  /// the first time the user visits it.
  ///
  /// Return `null` to disable auto-triggering.
  String? get guideSequenceId => null;

  /// Whether to delay the guide trigger to allow screen animations to settle.
  Duration get guideDelay => const Duration(milliseconds: 600);

  /// Call in [initState] to check if this screen's guide should auto-trigger.
  ///
  /// The guide only shows if:
  /// 1. [guideSequenceId] is non-null
  /// 2. The sequence exists in [GuideDatabase]
  /// 3. The sequence hasn't been completed yet (per [GuidePersistence])
  /// 4. No other guide is currently active
  void maybeShowGuide() {
    final id = guideSequenceId;
    if (id == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (GuidePersistence.isCompleted(id)) return;

      final currentState = ref.read(guideControllerProvider);
      if (currentState.isActive) return;

      final sequence = GuideDatabase.getById(id);
      if (sequence == null) return;

      Future.delayed(guideDelay, () {
        if (!mounted) return;
        ref.read(guideControllerProvider.notifier).startGuide(sequence);
      });
    });
  }

  /// Manually trigger the guide (e.g., from a "?" help button).
  /// Always shows the guide regardless of completion status.
  void showGuide() {
    final id = guideSequenceId;
    if (id == null) return;

    final sequence = GuideDatabase.getById(id);
    if (sequence == null) return;

    ref.read(guideControllerProvider.notifier).startGuide(
          sequence,
          force: true,
        );
  }
}
