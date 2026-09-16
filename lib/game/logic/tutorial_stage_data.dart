
/// A single tutorial instruction step shown during tutorial battle.
class TutorialStep {
  const TutorialStep({
    required this.id,
    required this.headline,
    required this.body,
    this.highlightZone,
    this.requiredAction,
    this.autoAdvanceAfterMs,
  });

  /// Unique id for completion tracking.
  final String id;
  final String headline;
  final String body;

  /// Optional UI zone to highlight (e.g., 'stamina_bar', 'skill_meter').
  final String? highlightZone;

  /// If set, the step waits for this action before advancing.
  final TutorialRequiredAction? requiredAction;

  /// If set, auto-advance after this many milliseconds.
  final int? autoAdvanceAfterMs;
}

enum TutorialRequiredAction {
  swipe,
  parry,
  dodge,
  block,
  useActiveSkill,
  counterSlash,
}

/// Ordered list of tutorial steps shown during the intro battle.
const List<TutorialStep> kTutorialSteps = [
  TutorialStep(
    id: 'intro',
    headline: 'WELCOME TO COLOSYNTH',
    body: 'A battle is a clash of ink and will. Swipe to attack!',
    autoAdvanceAfterMs: 3000,
  ),
  TutorialStep(
    id: 'swipe_to_attack',
    headline: 'SWIPE TO ATTACK',
    body: 'Drag your finger in any direction to slash the enemy.',
    requiredAction: TutorialRequiredAction.swipe,
  ),
  TutorialStep(
    id: 'parry',
    headline: 'PARRY',
    body: 'When the enemy telegraphs an attack, swipe the OPPOSITE direction to parry!',
    highlightZone: 'enemy_direction_arrow',
    requiredAction: TutorialRequiredAction.parry,
  ),
  TutorialStep(
    id: 'dodge',
    headline: 'DODGE',
    body: 'Tap the left or right dodge button to roll away from diagonal strikes.',
    highlightZone: 'dodge_buttons',
    requiredAction: TutorialRequiredAction.dodge,
  ),
  TutorialStep(
    id: 'stamina',
    headline: 'ENEMY STAMINA',
    body: 'Every parry and dodge drains the enemy\'s stamina bar. Drain it fully to STAGGER the enemy!',
    highlightZone: 'stamina_bar',
    autoAdvanceAfterMs: 4000,
  ),
  TutorialStep(
    id: 'stagger',
    headline: 'STAGGER WINDOW',
    body: 'When staggered, a COUNTER WINDOW opens. Swipe to deal massive bonus damage!',
    highlightZone: 'counter_window',
    requiredAction: TutorialRequiredAction.counterSlash,
  ),
  TutorialStep(
    id: 'active_skill',
    headline: 'ACTIVE SKILL',
    body: 'Fill the skill meter by landing hits. When full, tap the skill button to unleash it!',
    highlightZone: 'skill_meter',
    requiredAction: TutorialRequiredAction.useActiveSkill,
  ),
  TutorialStep(
    id: 'synths',
    headline: 'SYNTHS',
    body: 'Equip Synths with unique combo sequences. During the counter window, input the sequence for a bonus multiplier!',
    autoAdvanceAfterMs: 5000,
  ),
  TutorialStep(
    id: 'finish',
    headline: 'YOU\'RE READY!',
    body: 'Defeat the enemy to complete your tutorial and begin your tournament journey.',
    autoAdvanceAfterMs: 3000,
  ),
];

/// Returns the index of the step matching [stepId], or -1 if not found.
int tutorialStepIndexOf(String stepId) {
  for (int i = 0; i < kTutorialSteps.length; i++) {
    if (kTutorialSteps[i].id == stepId) return i;
  }
  return -1;
}
