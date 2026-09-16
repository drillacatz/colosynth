enum BattleMode { tournament, extreme, tutorial }

abstract class GameEvent {
  const GameEvent();
}

class VictoryEvent extends GameEvent {
  final BattleMode mode;
  final int? tier;
  final String? slotId;

  const VictoryEvent(this.mode, {this.tier, this.slotId});
}

class DefeatEvent extends GameEvent {
  final BattleMode mode;

  const DefeatEvent(this.mode);
}

class CounterStartEvent extends GameEvent {
  const CounterStartEvent();
}
typedef StaggerStartEvent = CounterStartEvent;

class CounterSlashEvent extends GameEvent {
  final double damage;

  const CounterSlashEvent(this.damage);
}

class TournamentStageClearedEvent extends GameEvent {
  final String slotId;
  final int tier;
  final bool firstClear;

  const TournamentStageClearedEvent(this.slotId, this.tier, this.firstClear);
}

class TournamentTierClearedEvent extends GameEvent {
  final int tier;
  final bool firstClear;

  const TournamentTierClearedEvent(this.tier, this.firstClear);
}

class TutorialCompletedEvent extends GameEvent {
  const TutorialCompletedEvent();
}

class TutorialSkippedEvent extends GameEvent {
  const TutorialSkippedEvent();
}

class SynthKeyGrantedEvent extends GameEvent {
  final int qty;

  const SynthKeyGrantedEvent(this.qty);
}

class SynthCrateOpenedEvent extends GameEvent {
  final String synthId;
  final bool wasDuplicate;

  const SynthCrateOpenedEvent(this.synthId, this.wasDuplicate);
}

class SynthSlotUnlockedEvent extends GameEvent {
  final int slotIndex;

  const SynthSlotUnlockedEvent(this.slotIndex);
}

class ActiveSkillReleasedEvent extends GameEvent {
  final String charId;
  final double damage;
  final bool fromStoredCharge;

  const ActiveSkillReleasedEvent(this.charId, this.damage, this.fromStoredCharge);
}

class ExtremeRotationClearedEvent extends GameEvent {
  final int rotationSlot;
  final bool isFirstOfDay;
  final bool isFirstEverForThisSlot;

  const ExtremeRotationClearedEvent(
    this.rotationSlot,
    this.isFirstOfDay,
    this.isFirstEverForThisSlot,
  );
}

class RewardGrantedEvent extends GameEvent {
  final String source;
  final int inkDelta;
  final int paintDelta;
  final int accountXpDelta;
  final Map<String, int> itemDeltas;

  const RewardGrantedEvent({
    required this.source,
    required this.inkDelta,
    required this.paintDelta,
    required this.accountXpDelta,
    required this.itemDeltas,
  });
}

class ParrySuccessEvent extends GameEvent {
  const ParrySuccessEvent();
}

class DodgeSuccessEvent extends GameEvent {
  const DodgeSuccessEvent();
}

class BlockSuccessEvent extends GameEvent {
  const BlockSuccessEvent();
}

class BrokenEvent extends GameEvent {
  const BrokenEvent();
}

class SynthAbilityTriggeredEvent extends GameEvent {
  final String synthId;

  const SynthAbilityTriggeredEvent(this.synthId);
}

class CharacterLeveledUpEvent extends GameEvent {
  final String charId;
  final int newLevel;

  const CharacterLeveledUpEvent(this.charId, this.newLevel);
}

class EquipmentUpgradedEvent extends GameEvent {
  final String charId;
  final String slot;
  final int newLevel;

  const EquipmentUpgradedEvent(this.charId, this.slot, this.newLevel);
}

class CharacterRecruitedEvent extends GameEvent {
  final String charId;

  const CharacterRecruitedEvent(this.charId);
}

class BattleQuitEvent extends GameEvent {
  const BattleQuitEvent();
}

class ExpItemConsumedEvent extends GameEvent {
  final String itemId;
  final int count;

  const ExpItemConsumedEvent(this.itemId, this.count);
}

class DailyGiftClaimedEvent extends GameEvent {
  const DailyGiftClaimedEvent();
}
