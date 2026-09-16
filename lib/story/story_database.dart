import 'package:colosynth/story/models/story_node.dart';
import 'package:colosynth/story/models/story_sequence.dart';

/// Database registry containing all narrative story sequences (battle intros, outros, cutscenes).
abstract final class StoryDatabase {
  /// Maps a Level Slot ID (e.g. `t1_a_0`) to before-battle intro story sequence ID.
  static const Map<String, String> levelIntros = {
    't1_a_0': 't1_a_0_intro',
  };

  /// Maps a Level Slot ID (e.g. `t1_a_0`) to after-battle outro story sequence ID.
  static const Map<String, String> levelOutros = {
    't1_a_0': 't1_a_0_outro',
  };

  /// In-memory lookup of all narrative story sequences.
  static final Map<String, StorySequence> _stories = {
    't1_a_0_intro': const StorySequence(
      id: 't1_a_0_intro',
      isSkippable: true,
      nodes: [
        StoryNode(
          id: 'l1_intro_1',
          speakerName: 'Arthur',
          speakerCharacterId: 'arthur',
          dialogueText: 'Wait up! Before we enter the arena, see who stands there. It\'s CHALK, the training dummy.',
          speakerPosition: StorySpeakerPosition.left,
        ),
        StoryNode(
          id: 'l1_intro_2',
          speakerName: 'Chalk',
          dialogueText: 'Ssscratch... ssscratch... I will test your brush stroke. Show me no mercy, challenger!',
          speakerPosition: StorySpeakerPosition.right,
          customPortraitAsset: 'assets/images/battle_ready.png',
        ),
        StoryNode(
          id: 'l1_intro_3',
          speakerName: 'Arthur',
          speakerCharacterId: 'arthur',
          dialogueText: 'Chalk is fragile but fast. Focus on timing your parry correctly. Let\'s fight!',
          speakerPosition: StorySpeakerPosition.left,
        ),
      ],
    ),

    't1_a_0_outro': const StorySequence(
      id: 't1_a_0_outro',
      isSkippable: true,
      nodes: [
        StoryNode(
          id: 'l1_outro_1',
          speakerName: 'Arthur',
          speakerCharacterId: 'arthur',
          dialogueText: 'Stellar work! You shattered that dummy into chalk dust.',
          speakerPosition: StorySpeakerPosition.left,
        ),
        StoryNode(
          id: 'l1_outro_2',
          speakerName: 'Arthur',
          speakerCharacterId: 'arthur',
          dialogueText: 'That was just a warm-up. More formidable adversaries await in the tournament. Keep training!',
          speakerPosition: StorySpeakerPosition.left,
        ),
      ],
    ),
  };

  /// Retrieves a story sequence by its ID.
  static StorySequence? getStoryById(String id) => _stories[id];

  /// Resolves the pre-battle intro story sequence for a level.
  static StorySequence? getIntroForLevel(String levelId) {
    final storyId = levelIntros[levelId];
    if (storyId == null) return null;
    return getStoryById(storyId);
  }

  /// Resolves the post-battle outro story sequence for a level.
  static StorySequence? getOutroForLevel(String levelId) {
    final storyId = levelOutros[levelId];
    if (storyId == null) return null;
    return getStoryById(storyId);
  }
}
