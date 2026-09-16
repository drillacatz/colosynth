import 'package:flutter/material.dart';


/// Determines how a guide step is rendered and what interaction it expects.
enum GuideStepType {
  /// Full narrative dialogue: portrait + typewriter text in DoodleDialogBox.
  /// User taps anywhere to advance (or waits for typewriter to finish).
  dialogue,

  /// Compact tooltip bubble anchored to a specific UI element.
  /// Great for contextual hints ("This is the Store tab").
  coachMark,

  /// Dims the entire screen and highlights a specific widget with a cutout.
  /// User MUST tap the highlighted widget to advance (forced interaction).
  spotlight,

  /// Shows instruction text and waits for a specific user action
  /// (e.g., "Swipe to attack", "Navigate to the Store tab").
  action,
}

/// Where a coach mark or dialogue is positioned relative to its anchor widget.
enum GuidePosition {
  top,
  bottom,
  left,
  right,
  center,
}

/// Placement position of the dialogue box during interactive guide steps.
enum GuideDialogPosition {
  /// Automatically calculates target position on screen: if target anchor is in
  /// lower half of screen (e.g. bottom bar), position dialogue box at top; if top half, at bottom.
  auto,

  /// Explicitly forces the dialogue box to top of screen.
  top,

  /// Explicitly forces the dialogue box to bottom of screen.
  bottom,
}

/// Speaker's visual position on screen during dialogue steps.
enum GuideSpeakerPosition { left, center, right }


/// A single instruction frame within a [GuideSequence].
///
/// Each step describes *what* to show, *where* to anchor it, and *how*
/// the user advances past it. The [GuideOverlay] reads these fields to
/// auto-select its rendering mode (dialogue box, coach bubble, spotlight, etc.).
@immutable
class GuideStep {
  /// Unique step identifier (used for logging / analytics / debugging).
  final String id;

  /// Determines the visual presentation and interaction model.
  final GuideStepType type;


  /// Display name of the speaking character (dialogue / coachMark).
  final String? speakerName;

  /// Character ID from [CharacterDatabase] to auto-resolve portraits/colors.
  final String? speakerCharacterId;

  /// Direct asset path for custom characters not in [CharacterDatabase].
  final String? customPortraitAsset;

  /// The instruction / dialogue text to display.
  final String text;

  /// Speaker's visual position on screen (dialogue steps only).
  final GuideSpeakerPosition speakerPosition;


  /// The ID of the [GuideAnchor] widget to spotlight or point at.
  /// When non-null, the overlay will locate this widget on screen and
  /// draw a spotlight cutout or position a tooltip relative to it.
  final String? anchorId;

  /// Where to show the tooltip / bubble relative to the [anchorId] widget.
  final GuidePosition position;

  /// Placement position of the dialogue box (auto, top, or bottom).
  /// Defaults to `GuideDialogPosition.auto` which places the box at the top
  /// when the target anchor is in the bottom half of the screen (e.g. bottom bar).
  final GuideDialogPosition dialogPosition;


  /// For [GuideStepType.action] steps: the action ID the user must perform
  /// before the guide auto-advances. The screen reports actions via
  /// `GuideController.notifyAction(actionId)`.
  ///
  /// Examples: `'navigate_to_store'`, `'tap_start_button'`, `'swipe_attack'`.
  final String? requiredAction;

  /// If set, the step auto-advances after this many milliseconds
  /// (even if the user hasn't interacted). Useful for timed info popups.
  final int? autoAdvanceMs;

  /// Whether to dim and block background taps while this step is active.
  /// Defaults to `true` for spotlight and action steps.
  final bool blockBackground;

  /// Whether the user can tap anywhere (outside the anchor) to skip
  /// past this step. Defaults to `true` for dialogue and coachMark.
  final bool canTapToAdvance;


  /// Optional voice line audio file path (relative to assets/audio/).
  final String? voiceSfxPath;

  /// Whether to suppress all audio for this step.
  final bool isSilent;

  const GuideStep({
    required this.id,
    required this.type,
    this.speakerName,
    this.speakerCharacterId,
    this.customPortraitAsset,
    required this.text,
    this.speakerPosition = GuideSpeakerPosition.center,
    this.anchorId,
    this.position = GuidePosition.bottom,
    this.dialogPosition = GuideDialogPosition.auto,
    this.requiredAction,
    this.autoAdvanceMs,
    this.blockBackground = true,
    this.canTapToAdvance = true,
    this.voiceSfxPath,
    this.isSilent = false,
  });
}
