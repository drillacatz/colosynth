import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:colosynth/database/character/character_equipment_slot.dart';
import 'package:colosynth/database/synth/synth_instance.dart';
import 'package:colosynth/services/security_guard.dart';
import 'package:colosynth/services/sp_manager.dart';
import 'package:colosynth/services/account_save_manager.dart';
import 'package:colosynth/services/account_sync_service.dart';
import 'package:colosynth/services/gameplay_save_manager.dart';
import 'package:colosynth/services/battle_stats_service.dart';
import 'package:colosynth/services/daily_task_service.dart';
import 'package:colosynth/services/stats/player_stats_tracker.dart';
import 'package:colosynth/services/daily_bonus_service.dart';
import 'package:colosynth/services/battle/extreme_rotation/extreme_rotation_service.dart';
import 'package:colosynth/game_settings.dart';
import 'package:colosynth/utils/date_utils.dart';
import 'package:colosynth/utils/app_logger.dart';
import 'package:colosynth/utils/async_mutex.dart';

abstract class ISaveRepository {
  AccountSaveManager get account;
  GameplaySaveManager get gameplay;
  Future<void> init([SharedPreferences? prefs]);
  Future<void> flushDebouncedWrites();
}

class SaveManager implements ISaveRepository {
  SaveManager._();
  static final SaveManager instance = SaveManager._();

  AccountSaveManager? _account;
  GameplaySaveManager? _gameplay;
  Timer? _debounceFlushTimer;
  bool _isDirty = false;

  @override
  AccountSaveManager get account {
    final a = _account;
    if (a == null) {
      throw StateError('SaveManager has not been initialized. Call init() first.');
    }
    return a;
  }

  @override
  GameplaySaveManager get gameplay {
    final g = _gameplay;
    if (g == null) {
      throw StateError('SaveManager has not been initialized. Call init() first.');
    }
    return g;
  }

  void markDirty() {
    _isDirty = true;
    _debounceFlushTimer?.cancel();
    _debounceFlushTimer = Timer(const Duration(milliseconds: 500), () {
      unawaited(flushDebouncedWrites());
    });
  }

  @override
  Future<void> flushDebouncedWrites() async {
    _debounceFlushTimer?.cancel();
    _debounceFlushTimer = null;
    if (!_isDirty) return;
    await _cloudMutex.protect(() async {
      if (!_isDirty) return;
      _isDirty = false;
      await AccountSyncService.instance.flushNow();
    });
  }

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  final _guard = SecurityGuard.instance;
  SharedPreferences? _prefs;
  String? _uid;
  final _cloudMutex = AsyncMutex();

  Timer? _dailyPushTimer;
  Future<void>? initialSyncFuture;
  bool get isInitialized => _prefs != null;

  static const _kCheckInterval = Duration(hours: 1);

  @override
  Future<void> init([SharedPreferences? prefs]) async {
    _prefs = prefs ?? _prefs ?? await SharedPreferences.getInstance().timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('SharedPreferences timed out'),
    );
    await _guard.init(_p);
    
    _account = AccountSaveManager(_p, _guard);
    _gameplay = GameplaySaveManager(_p);
  }

  SharedPreferences get _p {
    final p = _prefs;
    if (p == null) {
      throw StateError('SaveManager.init() must be called before use');
    }
    return p;
  }

  DocumentReference<Map<String, dynamic>> get _userDoc {
    final uid = _uid;
    if (uid == null) throw StateError('No user bound');
    return _db.collection('users').doc(uid);
  }

  Future<void> _wipeLocalSave() async {
    final keys = _p.getKeys();
    final toKeep = {
      SPKeys.settingsSfx,
      SPKeys.settingsBgm,
      SPKeys.settingsSfxVolume,
      SPKeys.settingsBgmVolume,
      SPKeys.settingsLobbyBgmType,
      SPKeys.hmacKey,
      'ad_install_date_ms',
    };
    for (final key in keys) {
      if (!toKeep.contains(key)) {
        await _p.remove(key);
      }
    }
  }

  Future<void> bindUser(String uid) async {
    _uid = uid;
    account.bindUser(uid);
    gameplay.bindUser(uid);

    final prevOwner = _p.getString('colosynth_save_owner_uid');
    if (prevOwner == null || prevOwner.isEmpty) {
      await _p.setString('colosynth_save_owner_uid', uid);
      _guard.bindUser(uid);
    } else if (prevOwner != uid) {
      debugPrint('SaveManager: Owner changed from $prevOwner to $uid. Wiping local save to prevent cross-contamination.');
      await _wipeLocalSave();
      await _p.setString('colosynth_save_owner_uid', uid);
      _guard.bindUser(uid);

      await DailyTaskService.instance.reload();
      await BattleStatsService.instance.reload();
      await PlayerStatsTracker.instance.reload();
      await DailyRewardService.instance.reload();
      await ExtremeRotationService.instance.refresh();
    } else {
      _guard.bindUser(uid);
    }

    initialSyncFuture = _syncFromCloud();
    await initialSyncFuture;
    _startDailyPushScheduler();
  }

  Future<void> unbindUser() async {
    _dailyPushTimer?.cancel();
    _dailyPushTimer = null;
    _uid = null;
    account.unbindUser();
    gameplay.unbindUser();
    _guard.unbindUser();

    try { await DailyTaskService.instance.reload(); } catch (_) {}
    try { await BattleStatsService.instance.reload(); } catch (_) {}
    try { await PlayerStatsTracker.instance.reload(); } catch (_) {}
    try { await DailyRewardService.instance.reload(); } catch (_) {}
    try { await ExtremeRotationService.instance.refresh(); } catch (_) {}
  }



  void _startDailyPushScheduler() {
    _dailyPushTimer?.cancel();
    unawaited(_maybePushToCloud());
    _dailyPushTimer = Timer.periodic(_kCheckInterval, (_) {
      unawaited(_maybePushToCloud());
    });
  }

  Future<void> _maybePushToCloud() async {
    if (_uid == null || _prefs == null) return;
    final lastPush = _p.getString(SPKeys.lastDailyPush) ?? '';
    if (lastPush == AppDateUtils.todayKey()) return;
    await _cloudMutex.protect(() => _pushToCloud());
  }

  Future<void> forcePushToCloud() async {
    if (_uid == null || _uid == 'local_guest_offline') return;
    await _cloudMutex.protect(() => _pushToCloud());
  }

  Future<void> _pushToCloud() async {
    if (_uid == null) return;
    try {
      final payload = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      payload['ink'] = account.loadInk();
      payload['paint'] = account.loadPaint();

      final unlockedChars = account.loadUnlockedCharacters();
      if (unlockedChars.isNotEmpty) {
        final characters = <String, dynamic>{};
        for (final charId in unlockedChars) {
          final equipMap = gameplay.loadEquipmentFor(charId);
          characters[charId] = {
            'level': gameplay.loadCharLevelFor(charId),
            'xp': gameplay.loadCharXpFor(charId),
            'breakthrough': gameplay.loadCharBreakthroughFor(charId),
            'equipment': equipMap.map((k, v) => MapEntry(k, v.toJson())),
          };
        }
        payload['characters'] = characters;
      }

      payload['expItems'] = gameplay.loadExpItems();
      payload['inventory'] = account.loadInventory();
      payload['permanentUnlocks'] = account.loadPermanentUnlocks();
      payload['gamesPlayed'] = _p.getInt(SPKeys.gamesPlayed) ?? 0;
      payload['bestEndlessFloor'] = loadBestEndlessFloor();
      payload['totalWins'] = account.getTotalWins();
      payload['totalParries'] = account.getTotalParries();
      payload['totalBroken'] = account.getTotalBroken();
      payload['totalLogins'] = account.getTotalLogins();
      payload['longestWinStreak'] = _p.getInt(SPKeys.longestWinStreak) ?? 0;
      payload['currentWinStreak'] = _p.getInt(SPKeys.currentWinStreak) ?? 0;

      AccountSyncService.instance.push(payload);
      await _p.setString(SPKeys.lastDailyPush, AppDateUtils.todayKey());
    } catch (e) {
      debugPrint('SaveManager._pushToCloud error: $e');
    }
  }

  Future<void> _syncFromCloud() async {
    if (_uid == null || _uid == 'local_guest_offline') return;
    await _cloudMutex.protect(() async {
      try {
        final snap = await _userDoc.get().timeout(const Duration(seconds: 4));
        if (!snap.exists) {
          await _bootstrapCloudDocument();
          return;
        }

        final hasLocalSave = _p.getBool(SPKeys.starterGranted) ?? false;
        if (hasLocalSave) {
          debugPrint('SaveManager: Local save already exists. Skipping startup cloud pull.');
          return;
        }

        final d = snap.data()!;

        await account.syncFromCloud(d);
        await gameplay.syncFromCloud(d);
        await _p.setBool(SPKeys.starterGranted, true);

        if (d['bestEndlessFloor'] is int) {
          final cloud = d['bestEndlessFloor'] as int;
          final local = loadBestEndlessFloor();
          if (cloud > local) {
            await _p.setInt(SPKeys.bestEndlessFloor, cloud);
          }
        }

        await BattleStatsService.instance.reload();
      } catch (e) {
        debugPrint('SaveManager._syncFromCloud error: $e');
      }
    });
  }

  Future<void> _bootstrapCloudDocument() async {
    if (_uid == null) return;
    try {
      final localInk = account.loadInk();
      final localPaint = account.loadPaint();

      await _userDoc.set({
        'uid': _uid,
        'isGuest': false,
        'ink': localInk,
        'paint': localPaint,
        'charLevel': 1,
        'charXp': 0,
        'accountLevel': account.loadAccountLevel(),
        'accountXp': account.loadAccountXp(),
        'totalWins': 0,
        'totalParries': 0,
        'totalBroken': 0,
        'totalLogins': 0,
        'highScore': 0,
        'unlockedCharacters': <String>['arthur'],
        'equippedCharacter': 'arthur',
        'tournamentProgress': <String, String>{},
        'bestEndlessFloor': loadBestEndlessFloor(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 4));

      final permanentUnlocks = List<String>.from(account.loadPermanentUnlocks());
      if (!permanentUnlocks.contains('first_login_reward')) {
        await account.awardPaint(100, source: 'first_login');
        permanentUnlocks.add('first_login_reward');
        await _p.setStringList(SPKeys.permanentUnlocks, permanentUnlocks);
        AccountSyncService.instance.push({'permanentUnlocks': permanentUnlocks});
      }
    } catch (e, st) {
      AppLogger.e('SaveManager', 'SaveManager._bootstrapCloudDocument error: $e', st);
    }
  }


  int loadInk() => account.loadInk();
  Future<void> awardInk(int amount, {String source = 'unknown'}) => account.awardInk(amount, source: source);
  Future<void> spendInk(int amount, {String reason = 'unknown'}) => account.spendInk(amount, reason: reason);
  int loadPaint() => account.loadPaint();
  Future<void> awardPaint(int amount, {String source = 'unknown'}) => account.awardPaint(amount, source: source);
  Future<void> spendPaint(int amount, {String reason = 'unknown'}) => account.spendPaint(amount, reason: reason);
  int loadAccountLevel() => account.loadAccountLevel();
  int loadAccountXp() => account.loadAccountXp();
  Future<void> addAccountXp(int xp) => account.addAccountXp(xp);
  int loadCharLevelFor(String characterId) => gameplay.loadCharLevelFor(characterId);
  int loadCharXpFor(String characterId) => gameplay.loadCharXpFor(characterId);
  Future<void> addCharXpFor(String characterId, int xp) => gameplay.addCharXpFor(characterId, xp);

  Map<String, CharacterEquipmentSlot> loadEquipmentFor(String charId) => gameplay.loadEquipmentFor(charId);
  Future<void> saveEquipmentLevelFor(String charId, String slotKey, int level) => gameplay.saveEquipmentLevelFor(charId, slotKey, level);
  Future<void> saveEquipmentXpFor(String charId, String slotKey, int xp) => gameplay.saveEquipmentXpFor(charId, slotKey, xp);
  Future<void> saveEquipmentBreakthroughFor(String charId, String slotKey, int breakthrough) => gameplay.saveEquipmentBreakthroughFor(charId, slotKey, breakthrough);

  Map<String, int> loadExpItems() => gameplay.loadExpItems();
  Future<void> addExpItem(String itemId, int count) => gameplay.addExpItem(itemId, count);
  Future<bool> consumeExpItem(String itemId) => gameplay.consumeExpItem(itemId);
  Set<String> loadSkillTree() => gameplay.loadSkillTree();
  Future<void> saveSkillTree(Set<String> unlockedIds) => gameplay.saveSkillTree(unlockedIds);
  Future<void> resetSkillTree() => gameplay.resetSkillTree();
  void incrementTotalWins() => account.incrementTotalWins();
  void incrementTotalParries(int count) => account.incrementTotalParries(count);
  void incrementTotalBroken() => account.incrementTotalBroken();
  void incrementTotalLogins() => account.incrementTotalLogins();
  int getTotalWins() => account.getTotalWins();
  int getTotalParries() => account.getTotalParries();
  int getTotalBroken() => account.getTotalBroken();
  int getTotalLogins() => account.getTotalLogins();
  List<String> loadUnlockedCharacters() => account.loadUnlockedCharacters();
  Future<void> unlockCharacter(String characterId) => account.unlockCharacter(characterId);
  String? loadEquippedCharacter() => account.loadEquippedCharacter();
  Future<void> saveEquippedCharacter(String characterId) => account.saveEquippedCharacter(characterId);
  List<String> loadInventory() => account.loadInventory();
  Future<void> saveInventory(List<String> ids) => account.saveInventory(ids);
  List<String> loadUnlockedItems() => account.loadUnlockedItems();
  Future<void> saveUnlockedItems(List<String> ids) => account.saveUnlockedItems(ids);
  Map<String, String> loadTournamentProgress() => account.loadTournamentProgress();
  Future<void> saveTournamentProgress(Map<String, String> progress) => account.saveTournamentProgress(progress);
  Future<GameSettings> loadSettings() => account.loadSettings();
  Future<void> saveSettings(GameSettings s) => account.saveSettings(s);

  Future<void> resetAll() => account.resetAll();
  int loadGamesPlayed() => _p.getInt(SPKeys.gamesPlayed) ?? 0;

  int loadSynthSlotLevel(int slotIndex) => gameplay.loadSynthSlotLevel(slotIndex);
  Future<void> saveSynthSlotLevel(int slotIndex, int level) => gameplay.saveSynthSlotLevel(slotIndex, level);
  bool loadSynthSlot3Unlocked() => gameplay.loadSynthSlot3Unlocked();
  Future<void> saveSynthSlot3Unlocked(bool unlocked) => gameplay.saveSynthSlot3Unlocked(unlocked);
  int loadSynthKeys() => gameplay.loadSynthKeys();
  Future<void> saveSynthKeys(int count) => gameplay.saveSynthKeys(count);

  int loadBestEndlessFloor() => _p.getInt(SPKeys.bestEndlessFloor) ?? 0;
  Future<void> saveBestEndlessFloor(int floor) async {
    await _p.setInt(SPKeys.bestEndlessFloor, floor);
    AccountSyncService.instance.push({'bestEndlessFloor': floor});
  }

  Future<void> grantStarterLoadoutIfNeeded() async {
    final granted = _p.getBool(SPKeys.starterGranted) ?? false;
    if (granted) return;

    await account.unlockCharacter('arthur');
    await account.saveEquippedCharacter('arthur');

    await gameplay.saveEquipmentLevelFor('arthur', 'weapon', 1);
    await gameplay.saveEquipmentLevelFor('arthur', 'shield', 1);
    await gameplay.saveEquipmentLevelFor('arthur', 'armor', 1);
    await gameplay.saveEquipmentLevelFor('arthur', 'helmet', 1);

    final starterSynthId = 'synth_01';
    final starterInstance = SynthInstance(
      instanceId: 'starter_synth',
      definitionId: starterSynthId,
      equippedCharacterId: 'arthur',
      slotIndex: 0,
      unlockedAtMs: DateTime.now().millisecondsSinceEpoch,
    );

    final instances = gameplay.loadSynthInstances();
    instances['starter_synth'] = starterInstance;
    await gameplay.saveSynthInstances(instances);

    final equipped = gameplay.loadEquippedSynthsFor('arthur');
    equipped[0] = 'starter_synth';
    await gameplay.saveEquippedSynthsFor('arthur', equipped);

    await _p.setString('colosynth_unlocked_synth_ids', jsonEncode([starterSynthId]));

    await _p.setBool(SPKeys.starterGranted, true);
  }
}

final saveManagerProvider = Provider<SaveManager>((_) => SaveManager.instance);
final accountSaveProvider = Provider<AccountSaveManager>((ref) => ref.watch(saveManagerProvider).account);
final gameplaySaveProvider = Provider<GameplaySaveManager>((ref) => ref.watch(saveManagerProvider).gameplay);

class InsufficientFundsException implements Exception {
  InsufficientFundsException(this.currency);
  final String currency;
  @override
  String toString() => 'InsufficientFundsException: not enough $currency';
}
