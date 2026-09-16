import 'package:colosynth/services/battle_stats_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flame/game.dart';

import 'package:colosynth/database/character/battle_stats.dart';
import 'package:colosynth/game_data/battle_anim.dart';
import 'package:colosynth/game/ai/ai_profiles.dart';
import 'package:colosynth/game/logic/battle_state_machine.dart';
import 'package:colosynth/game/logic/stamina_system.dart';
import 'package:colosynth/game/logic/skill_meter.dart';
import 'package:colosynth/game/logic/direction.dart';
import 'package:colosynth/game/skills/skill_effect.dart';
import 'package:colosynth/game/event_bus/game_events.dart';
import 'package:colosynth/game/app_shell/battle_result.dart';
export 'battle_result.dart';

abstract class BattleGameBase extends FlameGame {
  BattleStateMachine get fsm;
  AttackDirection get currentEnemyDirection;
  ValueNotifier<BattleResult?> get battleResultNotifier;
  ValueNotifier<double> get playerHpFraction;
  ValueNotifier<double> get enemyHpFraction;
  ValueNotifier<int> get damageEventNotifier;
  String get enemyDisplayName;
  Combatant get player;
  Combatant get enemy;
  StaminaSystem get stamina;
  ActiveSkillMeter get activeSkill;
  BattleStats get playerStats;
  BattleStatsTracker get stats;
  void applySkillEffect(SkillEffect effect);
  void quit();
  void onPlayerBlockStart();
  void onPlayerBlockEnd();
  void onPlayerActiveSkill();
  void onPlayerDodge({required bool isLeft});
  void onPlayerSwipe(AttackDirection direction);
  void shakeCamera(double amplitude);
  void onEnemyStaminaExhausted();
  BattleGameBase get game => this;
  void resetBattle();
}

typedef BattleWorld = BattleGameBase;

mixin BattleGameApi on FlameGame {
  ValueNotifier<BattleResult?> get battleResultNotifier;
  ValueNotifier<double> get playerHpFraction;
  ValueNotifier<double> get enemyHpFraction;
  ValueNotifier<int> get damageEventNotifier;
  String get enemyDisplayName;
  Combatant get player;
  Combatant get enemy;
  StaminaSystem get stamina;
  ActiveSkillMeter get activeSkill;
  BattleStateMachine get fsm;
  AttackDirection get currentEnemyDirection;
  BattleStats get playerStats;
  BattleStatsTracker get stats;
  void applySkillEffect(SkillEffect effect);
  void quit();
  void onPlayerBlockStart();
  void onPlayerBlockEnd();
  void onPlayerActiveSkill();
  void onPlayerDodge({required bool isLeft});
  void onEnemyStaminaExhausted();
  void resetBattle();
  void revive();
}

@immutable
class BattleGameParams {
  const BattleGameParams({
    required this.slotId,
    required this.aiProfile,
    required this.tier,
    this.mode = BattleMode.tournament,
  });

  final String slotId;
  final AiProfile aiProfile;
  final int tier;
  final BattleMode mode;

  @override
  bool operator ==(Object other) =>
      other is BattleGameParams && other.slotId == slotId && other.mode == mode;

  @override
  int get hashCode => Object.hash(slotId, mode);
}
