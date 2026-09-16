import 'package:flutter/material.dart';
import 'package:colosynth/game/ai/ai_profiles.dart';

/// A single stage in the 120-stage linear tournament.
class TournamentStageData {
  const TournamentStageData({
    required this.stageNumber,
    required this.tier,
    required this.enemyName,
    required this.profile,
    required this.isBoss,
    required this.inkReward,
    required this.paintReward,
    required this.accentColor,
  });

  final int stageNumber;
  final int tier;
  final String enemyName;
  final AiProfile profile;
  final bool isBoss;
  final int inkReward;
  final int paintReward;
  final Color accentColor;

  String get slotId => 'stage_$stageNumber';
}


const Color _nb = Color(0xFF6E6E6E);
const Color _cb = Color(0xFF3399FF);
const Color _dc = Color(0xFFFFCC00);

Color _accentForTier(int tier) {
  if (tier <= 3) return _nb;
  if (tier <= 6) return _cb;
  return _dc;
}

AiProfile _profileForTier(int tier) {
  if (tier <= 3) return AiProfile.easy();
  if (tier <= 6) return AiProfile.medium();
  if (tier <= 9) return AiProfile.hard();
  return AiProfile.extreme();
}

int _inkForTier(int tier, bool isBoss) {
  const base = [666, 1333, 2000, 3333, 4666, 5000, 6666, 6666, 8333, 10000];
  final b = base[(tier - 1).clamp(0, 9)];
  return isBoss ? (b * 1.5).round() : b;
}

int _paintForStage(int stageNumber) {
  final tier = ((stageNumber - 1) ~/ 12) + 1;
  final stageInTier = ((stageNumber - 1) % 12) + 1;
  const normalBase = [1, 2, 4, 5, 7, 8, 10, 11, 13, 14];
  const midBossBase = [1, 5, 8, 11, 14, 18, 21, 25, 28, 32];
  const finalBossBase = [1, 11, 12, 23, 24, 34, 35, 45, 46, 56];
  final tIdx = (tier - 1).clamp(0, 9);

  if (stageInTier == 4) return midBossBase[tIdx];
  if (stageInTier == 12) return finalBossBase[tIdx];
  return normalBase[tIdx];
}

const _normalNames = [
  ['CHALK', 'SMUDGE', 'DOODLE', 'SCRAWL', 'BLOT', 'DRAFT', 'CARBON', 'ERASER', 'CREASE'],
  ['CINDER', 'GRAVEL', 'SLATE', 'EMBER', 'TINDER', 'FLINT', 'CHAR', 'GRIT', 'SMEAR'],
  ['BARK', 'HUSK', 'CRUST', 'GRAIN', 'MORTAR', 'FOSSIL', 'RUBBLE', 'GRIT-II', 'STONE'],
  ['BURST', 'FLARE', 'ZAPPER', 'CRACKER', 'SHARD', 'SPARK', 'STRIKER', 'BLAZE', 'BANG'],
  ['DOT', 'PIXEL', 'MESH', 'RASTER', 'GRID', 'PATCH', 'SCREEN', 'FILTER', 'MATRIX'],
  ['FRAME', 'PANEL', 'BORDER', 'STRIP', 'GUTTER', 'SPLICE', 'INSET', 'BLEED', 'CROP'],
  ['SHADE', 'DIMMER', 'VEIL', 'MURK', 'HAZE', 'GLOOM', 'PALL', 'DUSK', 'PYRE'],
  ['SHADOW', 'FLICKER', 'SMEAR-II', 'UMBRA', 'SPECTER', 'PENUMBRA', 'WRAITH', 'SILHOUETTE', 'GHOST'],
  ['VOID', 'HOLLOW', 'LACUNA', 'ABYSS', 'CHASM', 'RIFT', 'VORTEX', 'SINGULARITY', 'NULL'],
  ['RUIN', 'DECAY', 'ENTROPY', 'FRACTURE', 'OBLIVION', 'RAVAGER', 'ANNIHILATOR', 'OMEGA', 'MAELSTROM'],
];

const _eliteNames = [
  ['IRON LINE', 'PENCIL DUKE'],
  ['ASH EDGE', 'SOOT REAPER'],
  ['CHALK TITAN', 'GREY HAMMER'],
  ['BOOM SKULL', 'POP TITAN'],
  ['HALFTONE', 'BEN-DAY'],
  ['BOX BREAKER', 'PANEL KING'],
  ['INK SHROUD', 'DARK HERALD'],
  ['BLADE VEIL', 'ECLIPSE'],
  ['NULL HERALD', 'ABYSS LORD'],
  ['CHAOS HERALD', 'CHAOS KING'],
];

const _bossNames = [
  'SKETCH KING',
  'BLACK INK',
  'DUST KING',
  'KABOOM',
  'POINT KING',
  'EDGE MASTER',
  'NIGHT BREAKER',
  'PHANTOM KING',
  'VOID TYRANT',
  'FINAL INK',
];

/// Generates the full linear 120-stage tournament progression.
List<TournamentStageData> buildLinearTournamentStages() {
  final stages = <TournamentStageData>[];
  for (int tier = 1; tier <= 10; tier++) {
    final tierStart = (tier - 1) * 12;
    final profile = _profileForTier(tier);
    final accent = _accentForTier(tier);
    final normals = _normalNames[tier - 1];
    final elites = _eliteNames[tier - 1];
    final bossName = _bossNames[tier - 1];

    for (int i = 0; i < 9; i++) {
      final n = tierStart + i + 1;
      stages.add(TournamentStageData(
        stageNumber: n,
        tier: tier,
        enemyName: normals[i],
        profile: profile,
        isBoss: false,
        inkReward: _inkForTier(tier, false),
        paintReward: _paintForStage(n),
        accentColor: accent,
      ));
    }
    for (int i = 0; i < 2; i++) {
      final n = tierStart + 10 + i;
      stages.add(TournamentStageData(
        stageNumber: n,
        tier: tier,
        enemyName: elites[i],
        profile: profile,
        isBoss: false,
        inkReward: _inkForTier(tier, false),
        paintReward: _paintForStage(n),
        accentColor: accent,
      ));
    }
    final bossStageNum = tierStart + 12;
    stages.add(TournamentStageData(
      stageNumber: bossStageNum,
      tier: tier,
      enemyName: bossName,
      profile: profile,
      isBoss: true,
      inkReward: _inkForTier(tier, true),
      paintReward: _paintForStage(bossStageNum),
      accentColor: accent,
    ));
  }
  return stages;
}

/// Cached linear stage list (120 entries, indices 0-119).
final List<TournamentStageData> kLinearTournamentStages =
    buildLinearTournamentStages();

/// Highest stage unlocked = last stage where slotId key exists in progress.
/// Stage 1 is always unlocked.
int highestUnlockedStage(Map<String, String> progress) {
  if (progress.isEmpty) return 1;
  int highest = 1;
  for (int i = 1; i <= 120; i++) {
    if (progress.containsKey('stage_$i')) {
      highest = i + 1;
    }
  }
  return highest.clamp(1, 120);
}

bool isLinearStageUnlocked(int stageNumber, Map<String, String> progress) {
  if (stageNumber <= 1) return true;
  return progress.containsKey('stage_${stageNumber - 1}');
}
