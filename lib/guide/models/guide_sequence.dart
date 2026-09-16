import 'package:flutter/material.dart';

import 'package:colosynth/guide/models/guide_step.dart';


/// Identifies which screen or flow a [GuideSequence] belongs to.
///
/// The [GuideDatabase] indexes sequences by context so each screen can
/// efficiently query its own guides without scanning the full registry.
enum GuideContext {
  /// Home screen initial onboarding (tab walkthrough).
  home,

  /// Arena screen guide (tournament/roguelike modes, START button).
  arena,

  /// Character screen guide (wheel, stats, equipment, skills tabs).
  character,

  /// Store screen guide (ink/paint/synth sections, daily refresh).
  store,

  /// Upgrade screen guide (skill tree, inventory).
  upgrade,

  /// Pre-battle narrative dialogue.
  battleIntro,

  /// Post-battle narrative dialogue.
  battleOutro,

  /// In-battle tutorial steps (swipe, parry, dodge, etc.).
  battleTutorial,
}


/// An ordered sequence of [GuideStep]s representing a complete tutorial,
/// walkthrough, or narrative scene.
///
/// Analogous to a "chapter" or "cutscene script" in industry terminology.
/// Each sequence is self-contained and tied to a specific [GuideContext].
@immutable
class GuideSequence {
  /// Unique identifier used for persistence (tracking completion) and lookup.
  final String id;

  /// The screen/flow context this sequence belongs to.
  final GuideContext context;

  /// Ordered list of steps. The [GuideController] walks through these
  /// sequentially, advancing when the user meets each step's conditions.
  final List<GuideStep> steps;

  /// Whether the user can skip the entire sequence with a "SKIP" button.
  /// Set to `false` for mandatory first-time tutorials.
  final bool isSkippable;

  /// Optional BGM track to play during this sequence.
  /// The guide controller will pause the current BGM and restore it after.
  final String? defaultBgm;

  /// Optional full-screen background image for narrative scenes.
  final String? defaultBgImage;

  const GuideSequence({
    required this.id,
    required this.context,
    required this.steps,
    this.isSkippable = true,
    this.defaultBgm,
    this.defaultBgImage,
  });

  /// Total number of steps in this sequence.
  int get length => steps.length;

  /// Whether this sequence has any steps.
  bool get isEmpty => steps.isEmpty;
}
