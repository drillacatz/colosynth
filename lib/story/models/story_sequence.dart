import 'package:flutter/material.dart';
import 'package:colosynth/story/models/story_node.dart';

/// A structured sequence of dialogue nodes representing a full narrative scene or cutscene.
@immutable
class StorySequence {
  /// Unique sequence identifier.
  final String id;

  /// Ordered list of dialog steps.
  final List<StoryNode> nodes;

  /// Default background music track to play during this cutscene.
  final String? defaultBgm;

  /// Default full-screen background graphic.
  final String? defaultBgImage;

  /// Whether the user can tap a "SKIP" button to bypass this cutscene.
  final bool isSkippable;

  const StorySequence({
    required this.id,
    required this.nodes,
    this.defaultBgm,
    this.defaultBgImage,
    this.isSkippable = true,
  });
}
