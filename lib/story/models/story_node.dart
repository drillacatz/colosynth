import 'package:flutter/material.dart';

/// Speaker's position on screen during a dialogue step.
enum StorySpeakerPosition { left, center, right }

/// A single frame of dialogue in a narrative story cutscene.
@immutable
class StoryNode {
  /// Unique node identifier.
  final String id;

  /// Display name of the speaking character.
  final String speakerName;

  /// Optional ID referencing characters in CharacterDatabase.
  final String? speakerCharacterId;

  /// Optional direct asset path for custom characters/NPCs.
  final String? customPortraitAsset;

  /// The text content of the dialogue.
  final String dialogueText;

  /// Optional voice line audio file path relative to FlameAudio's asset folder.
  final String? voiceSfxPath;

  /// Position of the speaking character on screen.
  final StorySpeakerPosition speakerPosition;

  /// Whether this dialogue should skip playing any voice line.
  final bool isSilent;

  const StoryNode({
    required this.id,
    required this.speakerName,
    this.speakerCharacterId,
    this.customPortraitAsset,
    required this.dialogueText,
    this.voiceSfxPath,
    this.speakerPosition = StorySpeakerPosition.center,
    this.isSilent = false,
  });
}
