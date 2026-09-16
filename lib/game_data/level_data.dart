import 'package:flutter/material.dart';
import 'package:colosynth/game/ai/ai_profiles.dart';
import 'package:colosynth/screens/theme/tokens.dart';





enum ArenaStyle { notebook, comicBurst, darkComic }

class TSlot {
  const TSlot({
    required this.id,
    required this.enemyName,
    required this.profile,
    required this.tournamentTier,
    required this.accentColor,
    this.isBoss = false,
    this.isExtreme = false,
  });

  final String id;
  final String enemyName;
  final AiProfile profile;
  final int tournamentTier;
  final Color accentColor;
  final bool isBoss;
  final bool isExtreme;
}

class StageData {
  StageData({
    required this.stageKey,
    required this.label,
    required this.inkReward,
    required this.paintReward,
    required this.normalSlots,
    required this.bossSlot,
  });

  final String stageKey;
  final String label;
  final int inkReward;
  final int paintReward;
  final List<TSlot> normalSlots;
  final TSlot bossSlot;

  List<TSlot> get allSlots => [...normalSlots, bossSlot];
}

class LevelData {
  LevelData({
    required this.tier,
    required this.name,
    required this.recLv,
    required this.stages,
    required this.accentColor,
  });

  final int tier;
  final String name;
  final String recLv;
  final List<StageData> stages;
  final Color accentColor;

  List<TSlot> get allSlots => stages.expand((s) => s.allSlots).toList();
}



typedef TournamentData = LevelData;

class ArenaData {
  ArenaData({
    required this.style,
    required this.name,
    required this.subtitle,
    required this.tierRange,
    required this.tournaments,
    required this.primaryColor,
    required this.accentColor,
    required this.iconData,
    this.extremeSlot,
  });

  final ArenaStyle style;
  final String name;
  final String subtitle;
  final String tierRange;
  final List<LevelData> tournaments;
  final Color primaryColor;
  final Color accentColor;
  final IconData iconData;
  final TSlot? extremeSlot;

  List<TSlot> get allSlots {
    final list = <TSlot>[...tournaments.expand((t) => t.allSlots)];
    if (extremeSlot != null) list.add(extremeSlot!);
    return list;
  }
}

StageData makeStage(
  int tier,
  String stageKey,
  int inkReward,
  int paintReward,
  List<String> normalNames,
  String bossName,
  AiProfile profile,
  Color accent,
) {
  return StageData(
    stageKey: stageKey,
    label: 'STAGE ${stageKey.toUpperCase()}',
    inkReward: inkReward,
    paintReward: paintReward,
    normalSlots: List.generate(
      3,
      (i) => TSlot(
        id: 't${tier}_${stageKey}_$i',
        enemyName: normalNames[i],
        profile: profile,
        tournamentTier: tier,
        accentColor: accent,
      ),
    ),
    bossSlot: TSlot(
      id: 't${tier}_${stageKey}_boss',
      enemyName: bossName,
      profile: profile,
      tournamentTier: tier,
      accentColor: accent,
      isBoss: true,
    ),
  );
}

final List<ArenaData> kArenas = () {
  final nb = AppColors.sketchGray;
  final cb = AppColors.comicBlue;
  final dc = AppColors.comicYellow;
  final ex = AppColors.comicRed;

  final easy = AiProfile.easy();
  final medium = AiProfile.medium();
  final hard = AiProfile.hard();
  final extreme = AiProfile.extreme();

  final t1 = LevelData(
    tier: 1,
    name: 'ROUGH SKETCH',
    recLv: 'Lv5+',
    accentColor: nb,
    stages: [
      makeStage(1, 'a', 666, 1, ['CHALK', 'SMUDGE', 'DOODLE'], 'IRON LINE',
          easy, nb),
      makeStage(1, 'b', 666, 1, ['SCRAWL', 'BLOT', 'DRAFT'], 'PENCIL DUKE',
          easy, nb),
      makeStage(1, 'c', 666, 1, ['CARBON', 'ERASER', 'CREASE'], 'SKETCH KING',
          easy, nb),

    ],
  );
  final t2 = LevelData(
    tier: 2,
    name: 'INK OUTLINE',
    recLv: 'Lv10+',
    accentColor: nb,
    stages: [
      makeStage(
          2, 'a', 1333, 1, ['CINDER', 'GRAVEL', 'SLATE'], 'ASH EDGE', easy, nb),
      makeStage(2, 'b', 1333, 1, ['EMBER', 'TINDER', 'FLINT'], 'SOOT REAPER',
          easy, nb),
      makeStage(
          2, 'c', 1333, 1, ['CHAR', 'GRIT', 'SMEAR'], 'BLACK INK', easy, nb),

    ],
  );
  final t3 = LevelData(
    tier: 3,
    name: 'SKETCH COMBAT',
    recLv: 'Lv20+',
    accentColor: nb,
    stages: [
      makeStage(
          3, 'a', 1666, 2, ['BARK', 'HUSK', 'CRUST'], 'CHALK TITAN', easy, nb),
      makeStage(3, 'b', 1666, 2, ['GRAIN', 'MORTAR', 'FOSSIL'], 'GREY HAMMER',
          easy, nb),
      makeStage(
          3, 'c', 1666, 2, ['RUBBLE', 'GRIT', 'STONE'], 'DUST KING', easy, nb),

    ],
  );
  final t4 = LevelData(
    tier: 4,
    name: 'COMIC BLAST',
    recLv: 'Lv30+',
    accentColor: cb,
    stages: [
      makeStage(4, 'a', 3333, 2, ['BURST', 'FLARE', 'ZAPPER'], 'BOOM SKULL',
          medium, cb),
      makeStage(4, 'b', 3333, 2, ['CRACKER', 'SHARD', 'SPARK'], 'POP TITAN',
          medium, cb),
      makeStage(4, 'c', 3333, 2, ['STRIKER', 'BLAZE', 'BANG'], 'KABOOM',
          medium, cb),

    ],
  );
  final t5 = LevelData(
    tier: 5,
    name: 'HALFTONE CLASH',
    recLv: 'Lv40+',
    accentColor: cb,
    stages: [
      makeStage(
          5, 'a', 4666, 3, ['DOT', 'PIXEL', 'MESH'], 'HALFTONE', medium, cb),
      makeStage(
          5, 'b', 4666, 3, ['RASTER', 'GRID', 'PATCH'], 'BEN-DAY', medium, cb),
      makeStage(5, 'c', 4666, 3, ['SCREEN', 'FILTER', 'MATRIX'], 'POINT KING',
          medium, cb),

    ],
  );
  final t6 = LevelData(
    tier: 6,
    name: 'PANEL BREAK',
    recLv: 'Lv50+',
    accentColor: cb,
    stages: [
      makeStage(6, 'a', 5000, 4, ['FRAME', 'PANEL', 'BORDER'], 'BOX BREAKER',
          medium, cb),
      makeStage(6, 'b', 5000, 4, ['STRIP', 'GUTTER', 'SPLICE'], 'PANEL KING',
          medium, cb),
      makeStage(6, 'c', 5000, 4, ['INSET', 'BLEED', 'CROP'], 'EDGE MASTER',
          medium, cb),

    ],
  );
  final t7 = LevelData(
    tier: 7,
    name: 'DARK INK ONSET',
    recLv: 'Lv60+',
    accentColor: dc,
    stages: [
      makeStage(
          7, 'a', 6666, 5, ['SHADE', 'DIMMER', 'VEIL'], 'INK SHROUD', hard, dc),
      makeStage(
          7, 'b', 6666, 5, ['MURK', 'HAZE', 'GLOOM'], 'DARK HERALD', hard, dc),
      makeStage(7, 'c', 6666, 5, ['PALL', 'DUSK', 'PYRE'], 'NIGHT BREAKER',
          hard, dc),

    ],
  );
  final t8 = LevelData(
    tier: 8,
    name: 'SHADOW BLADE',
    recLv: 'Lv70+',
    accentColor: dc,
    stages: [
      makeStage(8, 'a', 6666, 6, ['SHADOW', 'FLICKER', 'SMEAR'], 'BLADE VEIL',
          hard, dc),
      makeStage(8, 'b', 6666, 6, ['UMBRA', 'SPECTER', 'PENUMBRA'], 'ECLIPSE',
          hard, dc),
      makeStage(8, 'c', 6666, 6, ['WRAITH', 'SILHOUETTE', 'GHOST'],
          'PHANTOM KING', hard, dc),

    ],
  );
  final t9 = LevelData(
    tier: 9,
    name: 'VOID TRIAL',
    recLv: 'Lv80+',
    accentColor: dc,
    stages: [
      makeStage(9, 'a', 8333, 8, ['VOID', 'HOLLOW', 'LACUNA'], 'NULL HERALD',
          hard, dc),
      makeStage(9, 'b', 8333, 8, ['ABYSS', 'CHASM', 'RIFT'], 'ABYSS LORD',
          hard, dc),
      makeStage(9, 'c', 8333, 8, ['VORTEX', 'SINGULARITY', 'NULL'],
          'VOID TYRANT', hard, dc),

    ],
  );
  final t10 = LevelData(
    tier: 10,
    name: 'FINAL INK CLASH',
    recLv: 'Lv85+',
    accentColor: dc,
    stages: [
      makeStage(10, 'a', 10000, 10, ['RUIN', 'DECAY', 'ENTROPY'], 'CHAOS HERALD',
          hard, dc),
      makeStage(10, 'b', 10000, 10, ['FRACTURE', 'OBLIVION', 'RAVAGER'],
          'CHAOS KING', hard, dc),
      makeStage(10, 'c', 10000, 10, ['ANNIHILATOR', 'OMEGA', 'MAELSTROM'],
          'FINAL INK', hard, dc),

    ],
  );

  final extremeSlot = TSlot(
    id: 'extreme_boss',
    enemyName: 'VOID KING',
    profile: extreme,
    tournamentTier: 10,
    accentColor: ex,
    isBoss: true,
    isExtreme: true,
  );

  return [
    ArenaData(
      style: ArenaStyle.notebook,
      name: 'NOTEBOOK',
      subtitle: 'WHITE CANVAS · SKETCH STYLE',
      tierRange: 'T1 – T3',
      tournaments: [t1, t2, t3],
      primaryColor: AppColors.paperWhite,
      accentColor: nb,
      iconData: Icons.edit_note,
    ),
    ArenaData(
      style: ArenaStyle.comicBurst,
      name: 'COMIC BURST',
      subtitle: 'PANEL EXPLOSION · POP ART',
      tierRange: 'T4 – T6',
      tournaments: [t4, t5, t6],
      primaryColor: const Color(0xFFFFF5E0),
      accentColor: cb,
      iconData: Icons.auto_awesome,
    ),
    ArenaData(
      style: ArenaStyle.darkComic,
      name: 'DARK COMIC',
      subtitle: 'BLACK MANGA · INK NOIR',
      tierRange: 'T7 – T10 + Extreme',
      tournaments: [t7, t8, t9, t10],
      primaryColor: AppColors.ink,
      accentColor: dc,
      iconData: Icons.whatshot,
      extremeSlot: extremeSlot,
    ),
  ];
}();

bool isSlotUnlocked(TSlot slot, Map<String, String> progress) {
  if (slot.isExtreme) return progress['t10_c_boss'] != null;

  final parts = slot.id.split('_');
  final tier = int.parse(parts[0].substring(1));
  final stage = parts[1];
  final pos = parts[2];

  if (stage == 'a' && pos != 'boss') {
    return tier == 1 || progress['t${tier - 1}_c_boss'] != null;
  }
  if (stage == 'a') {
    return progress['t${tier}_a_0'] != null &&
        progress['t${tier}_a_1'] != null &&
        progress['t${tier}_a_2'] != null;
  }
  if (stage == 'b' && pos != 'boss') {
    return progress['t${tier}_a_boss'] != null;
  }
  if (stage == 'b') {
    return progress['t${tier}_b_0'] != null &&
        progress['t${tier}_b_1'] != null &&
        progress['t${tier}_b_2'] != null;
  }
  if (stage == 'c' && pos != 'boss') {
    return progress['t${tier}_b_boss'] != null;
  }
  return progress['t${tier}_c_0'] != null &&
      progress['t${tier}_c_1'] != null &&
      progress['t${tier}_c_2'] != null;
}

bool isArenaUnlocked(ArenaData arena, Map<String, String> progress) {
  return switch (arena.style) {
    ArenaStyle.notebook => true,
    ArenaStyle.comicBurst => progress['t3_c_boss'] != null,
    ArenaStyle.darkComic => progress['t6_c_boss'] != null,
  };
}

int arenaCompletedCount(ArenaData arena, Map<String, String> progress) =>
    arena.allSlots.where((s) => progress[s.id] != null).length;

int arenaTotalSlots(ArenaData arena) => arena.allSlots.length;

int countCompleted(Map<String, String> progress) => progress.length;
