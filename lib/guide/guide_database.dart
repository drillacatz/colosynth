import 'package:colosynth/guide/models/guide_step.dart';
import 'package:colosynth/guide/models/guide_sequence.dart';

/// Central registry of all guide sequences in the game.
///
/// Organized by [GuideContext] so each screen can efficiently query its
/// own guides. Also provides level-specific battle intro/outro lookups
/// migrated from the old [StoryDatabase].
abstract final class GuideDatabase {

  /// Retrieves a guide sequence by its unique [id].
  static GuideSequence? getById(String id) => _all[id];

  /// Retrieves all guide sequences for a given [context].
  static List<GuideSequence> getByContext(GuideContext context) {
    return _all.values.where((g) => g.context == context).toList();
  }

  /// Retrieves the first (primary) guide for a screen context.
  /// Returns `null` if no guides are defined for that context.
  static GuideSequence? getPrimaryForContext(GuideContext context) {
    final guides = getByContext(context);
    return guides.isEmpty ? null : guides.first;
  }


  /// Maps a level slot ID to its before-battle intro guide ID.
  static const Map<String, String> _levelIntros = {
    't1_a_0': 't1_a_0_intro',
  };

  /// Maps a level slot ID to its after-battle outro guide ID.
  static const Map<String, String> _levelOutros = {
    't1_a_0': 't1_a_0_outro',
  };

  /// Returns the pre-battle intro guide for a level, if one exists.
  static GuideSequence? getBattleIntro(String levelId) {
    final id = _levelIntros[levelId];
    return id != null ? _all[id] : null;
  }

  /// Returns the post-battle outro guide for a level, if one exists.
  static GuideSequence? getBattleOutro(String levelId) {
    final id = _levelOutros[levelId];
    return id != null ? _all[id] : null;
  }


  static final Map<String, GuideSequence> _all = {

    'arena_guide': const GuideSequence(
      id: 'arena_guide',
      context: GuideContext.arena,
      isSkippable: true,
      steps: [
        GuideStep(
          id: 'arena_welcome',
          type: GuideStepType.dialogue,
          speakerName: 'Arthur',
          speakerCharacterId: 'arthur',
          text: 'This is the Arena — the heart of all combat in Colosynth. '
              'Let me walk you through the layout.',
          speakerPosition: GuideSpeakerPosition.left,
        ),
        GuideStep(
          id: 'arena_start_btn',
          type: GuideStepType.coachMark,
          text: 'Tap START to enter the Tournament bracket and choose your '
              'next battle. Each tier has 12 increasingly challenging fights.',
          anchorId: 'arena_start_button',
          position: GuidePosition.top,
        ),
        GuideStep(
          id: 'arena_mode_toggle',
          type: GuideStepType.coachMark,
          text: 'Switch between TOURNAMENT mode (story progression) and '
              'ROGUELIKE mode (endless challenge) using this toggle.',
          anchorId: 'arena_mode_toggle',
          position: GuidePosition.top,
        ),
        GuideStep(
          id: 'arena_daily_tasks',
          type: GuideStepType.coachMark,
          text: 'Check your daily tasks here! Complete them for bonus Ink '
              'and Paint rewards.',
          anchorId: 'arena_daily_tasks',
          position: GuidePosition.left,
        ),
        GuideStep(
          id: 'arena_finish',
          type: GuideStepType.dialogue,
          speakerName: 'Arthur',
          speakerCharacterId: 'arthur',
          text: 'You\'re all set! Tap START when you\'re ready to fight.',
          speakerPosition: GuideSpeakerPosition.left,
        ),
      ],
    ),

    'character_guide': const GuideSequence(
      id: 'character_guide',
      context: GuideContext.character,
      isSkippable: true,
      steps: [
        GuideStep(
          id: 'char_welcome',
          type: GuideStepType.dialogue,
          speakerName: 'Arthur',
          speakerCharacterId: 'arthur',
          text: 'Welcome to the Character screen! Here you can manage your '
              'synths, upgrade their stats, and equip gear.',
          speakerPosition: GuideSpeakerPosition.left,
        ),
        GuideStep(
          id: 'char_wheel',
          type: GuideStepType.coachMark,
          text: 'Swipe left or right to browse your roster of characters. '
              'Tap one to select them as your active fighter.',
          anchorId: 'character_wheel',
          position: GuidePosition.bottom,
        ),
        GuideStep(
          id: 'char_stats_tab',
          type: GuideStepType.coachMark,
          text: 'The STATS tab shows your character\'s base attributes and '
              'combat power breakdown.',
          anchorId: 'char_tab_stats',
          position: GuidePosition.right,
        ),
        GuideStep(
          id: 'char_equip_tab',
          type: GuideStepType.coachMark,
          text: 'The EQUIPMENT tab lets you view and breakthrough your '
              'character\'s four gear slots for permanent stat boosts.',
          anchorId: 'char_tab_equipment',
          position: GuidePosition.right,
        ),
        GuideStep(
          id: 'char_skills_tab',
          type: GuideStepType.coachMark,
          text: 'The SKILLS tab shows your character\'s Active Skill — '
              'charge it in battle by landing hits!',
          anchorId: 'char_tab_skills',
          position: GuidePosition.right,
        ),
        GuideStep(
          id: 'char_finish',
          type: GuideStepType.dialogue,
          speakerName: 'Arthur',
          speakerCharacterId: 'arthur',
          text: 'Remember: a well-equipped synth is a victorious one. '
              'Invest in your characters wisely!',
          speakerPosition: GuideSpeakerPosition.left,
        ),
      ],
    ),

    'store_guide': const GuideSequence(
      id: 'store_guide',
      context: GuideContext.store,
      isSkippable: true,
      steps: [
        GuideStep(
          id: 'store_welcome',
          type: GuideStepType.dialogue,
          speakerName: 'Arthur',
          speakerCharacterId: 'arthur',
          text: 'This is the Store! Here you\'ll find everything you need '
              'to strengthen your synths.',
          speakerPosition: GuideSpeakerPosition.left,
        ),
        GuideStep(
          id: 'store_ink_section',
          type: GuideStepType.coachMark,
          text: 'The INK section offers daily free ink and purchasable ink '
              'bundles. Ink is the primary currency for character leveling.',
          anchorId: 'store_section_ink',
          position: GuidePosition.bottom,
        ),
        GuideStep(
          id: 'store_synth_section',
          type: GuideStepType.coachMark,
          text: 'Use Synth Keys (earned from tournament victories) to open '
              'crates and unlock powerful Synth abilities here.',
          anchorId: 'store_section_synth',
          position: GuidePosition.bottom,
        ),
        GuideStep(
          id: 'store_recruit_section',
          type: GuideStepType.coachMark,
          text: 'Recruit new characters using Paint currency. Each '
              'synth has unique stats and an Active Skill.',
          anchorId: 'store_section_recruit',
          position: GuidePosition.bottom,
        ),
        GuideStep(
          id: 'store_finish',
          type: GuideStepType.dialogue,
          speakerName: 'Arthur',
          speakerCharacterId: 'arthur',
          text: 'Check back daily for free Ink refills! Smart resource '
              'management is key to climbing the tournament ranks.',
          speakerPosition: GuideSpeakerPosition.left,
        ),
      ],
    ),

    'upgrade_guide': const GuideSequence(
      id: 'upgrade_guide',
      context: GuideContext.upgrade,
      isSkippable: true,
      steps: [
        GuideStep(
          id: 'upgrade_welcome',
          type: GuideStepType.dialogue,
          speakerName: 'Arthur',
          speakerCharacterId: 'arthur',
          text: 'Welcome to the Upgrade lab! This is where you unlock '
              'powerful permanent bonuses via the Skill Tree.',
          speakerPosition: GuideSpeakerPosition.left,
        ),
        GuideStep(
          id: 'upgrade_skill_tree',
          type: GuideStepType.coachMark,
          text: 'The Skill Tree provides account-wide bonuses shared by '
              'ALL your characters. Unlock nodes using Ink currency.',
          anchorId: 'upgrade_skill_tree',
          position: GuidePosition.bottom,
        ),
        GuideStep(
          id: 'upgrade_inventory',
          type: GuideStepType.coachMark,
          text: 'Your EXP items inventory. Use Books, Hammers, and Notes '
              'to boost character levels instantly.',
          anchorId: 'upgrade_inventory',
          position: GuidePosition.top,
        ),
        GuideStep(
          id: 'upgrade_finish',
          type: GuideStepType.dialogue,
          speakerName: 'Arthur',
          speakerCharacterId: 'arthur',
          text: 'Invest in the Skill Tree early — those permanent bonuses '
              'make every battle easier!',
          speakerPosition: GuideSpeakerPosition.left,
        ),
      ],
    ),

    't1_a_0_intro': const GuideSequence(
      id: 't1_a_0_intro',
      context: GuideContext.battleIntro,
      isSkippable: true,
      steps: [
        GuideStep(
          id: 'l1_intro_1',
          type: GuideStepType.dialogue,
          speakerName: 'Arthur',
          speakerCharacterId: 'arthur',
          text: 'Wait up! Before we enter the arena, see who stands '
              'there. It\'s CHALK, the training dummy.',
          speakerPosition: GuideSpeakerPosition.left,
        ),
        GuideStep(
          id: 'l1_intro_2',
          type: GuideStepType.dialogue,
          speakerName: 'Chalk',
          customPortraitAsset: 'assets/images/battle_ready.png',
          text: 'Ssscratch... ssscratch... I will test your brush stroke. '
              'Show me no mercy, challenger!',
          speakerPosition: GuideSpeakerPosition.right,
        ),
        GuideStep(
          id: 'l1_intro_3',
          type: GuideStepType.dialogue,
          speakerName: 'Arthur',
          speakerCharacterId: 'arthur',
          text: 'Chalk is fragile but fast. Focus on timing your parry '
              'correctly. Let\'s fight!',
          speakerPosition: GuideSpeakerPosition.left,
        ),
      ],
    ),

    't1_a_0_outro': const GuideSequence(
      id: 't1_a_0_outro',
      context: GuideContext.battleOutro,
      isSkippable: true,
      steps: [
        GuideStep(
          id: 'l1_outro_1',
          type: GuideStepType.dialogue,
          speakerName: 'Arthur',
          speakerCharacterId: 'arthur',
          text: 'Stellar work! You shattered that dummy into chalk dust.',
          speakerPosition: GuideSpeakerPosition.left,
        ),
        GuideStep(
          id: 'l1_outro_2',
          type: GuideStepType.dialogue,
          speakerName: 'Arthur',
          speakerCharacterId: 'arthur',
          text: 'That was just a warm-up. More formidable adversaries await '
              'in the tournament. Keep training!',
          speakerPosition: GuideSpeakerPosition.left,
        ),
      ],
    ),
  };
}
