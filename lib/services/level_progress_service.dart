import 'package:colosynth/services/battle_stats_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:colosynth/services/sp_manager.dart';

enum UnlockableFeature {
  store,
  upgradeTab,
  characterSlot2,
  skillTree,
  characterScreen,
  characterSlot3,
  tournamentMedium,
  endlessBattle,
  dailyTasksUnlocked
}
@immutable
class UnlockGate {
  final UnlockableFeature feature;
  final int requiredLevel;
  final String label;
  final String description;
  final String emoji;
  final int inkReward;
  final int paintReward;
  final int hammerReward;
  final int noteReward;
  final int bookReward;

  const UnlockGate({
    required this.feature,
    required this.requiredLevel,
    required this.label,
    required this.description,
    required this.emoji,
    this.inkReward = 0,
    this.paintReward = 0,
    this.hammerReward = 0,
    this.noteReward = 0,
    this.bookReward = 0,
  });

}

@immutable
class RewardMilestone {
  final int level;
  final String emoji;
  final int inkReward;
  final int paintReward;
  final int hammerReward;
  final int noteReward;
  final int bookReward;

  const RewardMilestone({
    required this.level,
    required this.emoji,
    this.inkReward = 0,
    this.paintReward = 0,
    this.hammerReward = 0,
    this.noteReward = 0,
    this.bookReward = 0,
  });
}

class ProgressionService {
  ProgressionService._();
  static final ProgressionService instance = ProgressionService._();
  
  final Set<UnlockableFeature> _permanentUnlocks = {};
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final list = _prefs?.getStringList(SPKeys.permanentUnlocks) ?? [];
    for (final name in list) {
      try {
        _permanentUnlocks.add(UnlockableFeature.values.byName(name));
      } catch (_) {}
    }
  }

  static const int maxLevel = 99;

  static const List<UnlockGate> gates = [
    UnlockGate(
      feature: UnlockableFeature.store,
      requiredLevel: 1,
      label: 'STORE',
      description: 'Claim daily free Ink every day',
      emoji: '🛒',
    ),
    UnlockGate(
      feature: UnlockableFeature.characterScreen,
      requiredLevel: 1,
      label: 'CHARACTER',
      description: 'Unlock your synth roster',
      emoji: '⚔️',
      inkReward: 2000,
    ),
    UnlockGate(
      feature: UnlockableFeature.upgradeTab,
      requiredLevel: 2,
      label: 'UPGRADE',
      description: 'Strengthen your equipment and skills',
      emoji: '⬆️',
    ),
    UnlockGate(
      feature: UnlockableFeature.characterSlot2,
      requiredLevel: 5,
      label: 'CHARACTER SLOT 2',
      description: 'Unlock your second character slot',
      emoji: '👤',
      inkReward: 5000,
    ),
    UnlockGate(
      feature: UnlockableFeature.dailyTasksUnlocked,
      requiredLevel: 4,
      label: 'DAILY TASKS',
      description: 'Complete daily objectives for big rewards',
      emoji: '📅',
      paintReward: 10,
    ),
    UnlockGate(
      feature: UnlockableFeature.skillTree,
      requiredLevel: 7,
      label: 'SKILL TREE',
      description: 'Unlock passive combat skills',
      emoji: '🌿',
    ),
    UnlockGate(
      feature: UnlockableFeature.characterSlot3,
      requiredLevel: 10,
      label: 'CHARACTER SLOT 3',
      description: 'Unlock your third character slot',
      emoji: '👥',
      inkReward: 15000,
    ),
    UnlockGate(
      feature: UnlockableFeature.tournamentMedium,
      requiredLevel: 15,
      label: 'TOURNAMENT T4–T6',
      description: 'Face tougher opponents',
      emoji: '🥈',
      paintReward: 20,
    ),
    UnlockGate(
      feature: UnlockableFeature.endlessBattle,
      requiredLevel: 20,
      label: 'ENDLESS BATTLE',
      description: 'How long can you survive?',
      emoji: '♾️',
      paintReward: 50,
    ),
  ];

  static const List<RewardMilestone> milestones = [
    RewardMilestone(level: 5, emoji: '🎁', inkReward: 3000),
    RewardMilestone(level: 8, emoji: '🎁', inkReward: 5000, paintReward: 5),
    RewardMilestone(level: 12, emoji: '🎁', inkReward: 8000, paintReward: 10),
    RewardMilestone(level: 18, emoji: '🎁', inkReward: 12000, paintReward: 15),
    RewardMilestone(level: 25, emoji: '💎', inkReward: 20000, paintReward: 30),
    RewardMilestone(level: 30, emoji: '💎', inkReward: 30000, paintReward: 50),
    RewardMilestone(level: 40, emoji: '💎', inkReward: 50000, paintReward: 100),
    RewardMilestone(level: 50, emoji: '🏆', inkReward: 75000, paintReward: 150),
    RewardMilestone(level: 60, emoji: '🏆', inkReward: 100000, paintReward: 200),
    RewardMilestone(level: 70, emoji: '🏆', inkReward: 150000, paintReward: 300),
    RewardMilestone(level: 80, emoji: '🔥', inkReward: 200000, paintReward: 500),
    RewardMilestone(level: 90, emoji: '🔥', inkReward: 300000, paintReward: 800),
    RewardMilestone(level: 99, emoji: '👑', inkReward: 500000, paintReward: 1500),
  ];

  static final Map<UnlockableFeature, UnlockGate> _gateMap = {
    for (final g in gates) g.feature: g,
  };

  bool isUnlocked(UnlockableFeature feature, int playerLevel) {
    if (_permanentUnlocks.contains(feature)) return true;

    bool unlocked;
    if (feature == UnlockableFeature.characterScreen) {

      unlocked = BattleStatsService.instance.isCharacterScreenUnlocked || 
                 playerLevel >= requiredLevel(feature);
    } else {
      unlocked = playerLevel >= requiredLevel(feature);
    }

    return unlocked;
  }

  void checkAndMarkUnlocks(int playerLevel) {
    for (final feature in UnlockableFeature.values) {
      if (!_permanentUnlocks.contains(feature)) {
        if (isUnlocked(feature, playerLevel) && _isPermanentFeature(feature)) {
          markPermanentUnlock(feature);
        }
      }
    }
  }

  bool _isPermanentFeature(UnlockableFeature f) {
    return f == UnlockableFeature.characterScreen || 
           f == UnlockableFeature.upgradeTab ||
           f == UnlockableFeature.skillTree ||
           f == UnlockableFeature.dailyTasksUnlocked;
  }

  Future<void> markPermanentUnlock(UnlockableFeature feature) async {
    if (_permanentUnlocks.contains(feature)) return;
    _permanentUnlocks.add(feature);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setStringList(
      SPKeys.permanentUnlocks,
      _permanentUnlocks.map((e) => e.name).toList(),
    );
  }

  int requiredLevel(UnlockableFeature feature) =>
      _gateMap[feature]?.requiredLevel ?? 1;

  UnlockGate? gateFor(UnlockableFeature feature) => _gateMap[feature];

  List<UnlockGate> newlyUnlocked(int oldLevel, int newLevel) => gates
      .where(
        (g) => g.requiredLevel > oldLevel && g.requiredLevel <= newLevel,
      )
      .toList();

  UnlockGate? nextUnlock(int playerLevel) {
    for (final g in gates) {
      if (g.feature == UnlockableFeature.characterScreen) continue;
      if (g.requiredLevel > playerLevel) return g;
    }
    return null;
  }

  static int xpForLevel(int targetLevel) {
    final t = targetLevel.clamp(1, maxLevel);
    return 50 * t * (t - 1);
  }

  static int totalXpForTier(int tier) {
    if (tier == 1) return 4500;
    if (tier == 10) return 84600;
    return 14500 + (tier - 2) * 10000;
  }

  static int levelFirstClearXp(int tier, String slotId) {
    if (tier == 1) {
      if (slotId == 't1_a_0' || slotId == 't1_a_1' || slotId == 't1_a_2') {
        return 100;
      }
      final isBoss = slotId.endsWith('boss');
      return isBoss ? 400 : 200;
    }
    final isBoss = slotId.endsWith('boss');
    final levelXpTotal = (totalXpForTier(tier) * 0.6).round();
    final baseNormal = levelXpTotal ~/ 15;
    return isBoss ? baseNormal * 2 : baseNormal;
  }

  static int chestXpForTier(int tier) {
    return (totalXpForTier(tier) * 0.4).round();
  }

  static int get maxXp => xpForLevel(maxLevel);

  static int approxBattlesTo(int currentLevel, int targetLevel) {
    if (targetLevel <= currentLevel) return 0;
    final xpNeeded = xpForLevel(targetLevel) - xpForLevel(currentLevel);
    return (xpNeeded / 250).ceil();
  }

  static String fmtInk(int n) {
    if (n >= 1000) {
      final k = n / 1000;
      return '${k == k.truncateToDouble() ? k.toInt() : k.toStringAsFixed(1)}K';
    }
    return '$n';
  }
}

final levelProgressServiceProvider =
    Provider<ProgressionService>((_) => ProgressionService.instance);
