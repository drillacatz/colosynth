import 'package:colosynth/game_data/level_data.dart';

class TItem {
  const TItem(this.tournament, this.style);
  final TournamentData tournament;
  final ArenaStyle style;
}

List<TItem> buildTournamentList() {
  final items = <TItem>[];
  for (final arena in kArenas) {
    for (final t in arena.tournaments) {
      items.add(TItem(t, arena.style));
    }
  }
  items.sort((a, b) => a.tournament.tier.compareTo(b.tournament.tier));
  return items;
}

TSlot? findExtremeSlot() {
  for (final arena in kArenas.reversed) {
    if (arena.extremeSlot != null) return arena.extremeSlot;
  }
  return null;
}

bool isTournamentItemUnlocked(TournamentData t, Map<String, String> progress) {
  if (t.stages.isEmpty || t.stages.first.normalSlots.isEmpty) return false;
  return isSlotUnlocked(t.stages.first.normalSlots.first, progress);
}

bool isExtremeItemUnlocked(TSlot? extreme, Map<String, String> progress) {
  if (extreme == null) return false;
  return isSlotUnlocked(extreme, progress);
}

int tournamentCompletedCount(TournamentData t, Map<String, String> progress) {
  int count = 0;
  for (final stage in t.stages) {
    for (final slot in stage.normalSlots) {
      if (progress[slot.id] != null) count++;
    }
    if (progress[stage.bossSlot.id] != null) count++;
  }
  return count;
}

int tournamentTotalSlots(TournamentData t) {
  int count = 0;
  for (final stage in t.stages) {
    count += stage.normalSlots.length + 1;
  }
  return count;
}
