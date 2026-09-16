import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:colosynth/game_settings.dart';
import 'package:colosynth/services/security_guard.dart';
import 'package:colosynth/services/sp_manager.dart';
import 'package:colosynth/services/account_sync_service.dart';
import 'package:colosynth/utils/async_mutex.dart';
import 'package:colosynth/utils/app_logger.dart';


class AccountSaveManager {
  AccountSaveManager(this._p, this._guard);

  final SharedPreferences _p;
  final SecurityGuard _guard;
  final _sync = AccountSyncService.instance;

  static const int _kMaxInkAwardPerWrite = 30000;
  static const int _kMaxPaintAwardPerWrite = 1000;

  String? _uid;

  final _inkMutex = AsyncMutex();
  final _paintMutex = AsyncMutex();
  final _xpMutex = AsyncMutex();




  void bindUser(String uid) {
    _uid = uid;
    _sync.bindUser(uid);
  }

  void unbindUser() {
    _uid = null;
    _sync.unbindUser();
  }

  Future<void> _writeIntegrityInt(String key, String tagKey, int value) async {
    final tag = _guard.computeTag(key, value);
    await Future.wait([
      _p.setInt(key, value),
      _p.setString(tagKey, tag),
    ]);
  }

  int _readIntegrityInt(String key, String tagKey) {
    final value = _p.getInt(key) ?? 0;
    final tag = _p.getString(tagKey);
    if (tag == null) {
      if (value > 0) {
        final uid = _uid;
        if (uid != null && uid != 'local_guest_offline') {
          AppLogger.w('AccountSaveManager', 'Integrity check failed: missing tag for key: $key. Value: $value. Scheduling cloud recovery.');
          unawaited(_recoverFieldFromCloud(key, tagKey));
          return 0;
        } else {
          AppLogger.d('AccountSaveManager', 'Missing tag for guest key: $key. Regenerating tag.');
          unawaited(_writeIntegrityInt(key, tagKey, value));
          return value;
        }
      }
      return value;
    }
    if (!_guard.verifyTag(key, value, tag)) {
      AppLogger.w('AccountSaveManager', 'Integrity check failed for key: $key. Value: $value. Scheduling cloud recovery.');
      final uid = _uid;
      if (uid != null && uid != 'local_guest_offline') {
        unawaited(_recoverFieldFromCloud(key, tagKey));
      } else {
        unawaited(_p.setInt(key, 0));
        unawaited(_p.remove(tagKey));
      }
      return 0;
    }
    return value;
  }

  Future<void> _recoverFieldFromCloud(String key, String tagKey) async {
    final uid = _uid;
    if (uid == null || uid == 'local_guest_offline') return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          String? fieldName;
          if (key == SPKeys.ink) {
            fieldName = 'ink';
          } else if (key == SPKeys.paint) {
            fieldName = 'paint';
          } else if (key == SPKeys.accountXp) {
            fieldName = 'accountXp';
          } else if (key == SPKeys.accountLevel) {
            fieldName = 'accountLevel';
          }

          if (fieldName != null && data.containsKey(fieldName)) {
            final cloudVal = (data[fieldName] as num?)?.toInt() ?? 0;
            await _writeIntegrityInt(key, tagKey, cloudVal);
            AppLogger.d('AccountSaveManager', 'Successfully recovered field $key from cloud. Value: $cloudVal');
          }
        }
      }
    } catch (e, st) {
      AppLogger.e('AccountSaveManager', 'Failed to recover field $key from cloud: $e', st);
    }
  }

  int loadInk() => _readIntegrityInt(SPKeys.ink, SPKeys.inkTag);

  Future<void> awardInk(int amount, {String source = 'unknown'}) async {
    _guard.validateAwardSource(source);
    _guard.checkAwardRate(source);

    if (amount <= 0) {
      throw ArgumentError('awardInk: amount must be > 0');
    }
    if (!_guard.isIapSource(source) && amount > _kMaxInkAwardPerWrite) {
      throw ArgumentError('awardInk: non-IAP amount exceeds cap');
    }

    await _inkMutex.protect(() async {
      final newBalance = loadInk() + amount;
      await _writeIntegrityInt(SPKeys.ink, SPKeys.inkTag, newBalance);
      _sync.push({'ink': newBalance}, immediate: _guard.isIapSource(source));
    });
  }

  Future<void> spendInk(int amount, {String reason = 'unknown'}) async {
    _guard.requireAuth();
    _guard.validateSpendReason(reason);

    if (amount <= 0) {
      throw ArgumentError('spendInk: amount must be > 0');
    }

    await _inkMutex.protect(() async {
      final localBalance = loadInk();
      if (localBalance < amount) throw Exception('Insufficient ink');

      final newBalance = localBalance - amount;
      await _writeIntegrityInt(SPKeys.ink, SPKeys.inkTag, newBalance);

      _sync.push({'ink': newBalance});
    });
  }

  int loadPaint() => _readIntegrityInt(SPKeys.paint, SPKeys.paintTag);

  Future<void> awardPaint(int amount, {String source = 'unknown'}) async {
    _guard.validateAwardSource(source);
    _guard.checkAwardRate(source);

    if (amount <= 0) {
      throw ArgumentError('awardPaint: amount must be > 0');
    }
    if (!_guard.isIapSource(source) && amount > _kMaxPaintAwardPerWrite) {
      throw ArgumentError('awardPaint: non-IAP amount exceeds cap');
    }

    await _paintMutex.protect(() async {
      final newBalance = loadPaint() + amount;
      await _writeIntegrityInt(SPKeys.paint, SPKeys.paintTag, newBalance);
      _sync.push({'paint': newBalance}, immediate: _guard.isIapSource(source));
    });
  }

  Future<void> spendPaint(int amount, {String reason = 'unknown'}) async {
    _guard.requireAuth();
    _guard.validateSpendReason(reason);

    if (amount <= 0) {
      throw ArgumentError('spendPaint: amount must be > 0');
    }

    await _paintMutex.protect(() async {
      final localBalance = loadPaint();
      if (localBalance < amount) throw Exception('Insufficient paint');

      final newBalance = localBalance - amount;
      await _writeIntegrityInt(SPKeys.paint, SPKeys.paintTag, newBalance);

      _sync.push({'paint': newBalance});
    });
  }

  int loadAccountLevel() => _p.getInt(SPKeys.accountLevel) ?? 1;
  int loadAccountXp() =>
      _readIntegrityInt(SPKeys.accountXp, SPKeys.accountXpTag);

  Future<void> addAccountXp(int xp) async {
    if (xp <= 0) throw ArgumentError('addAccountXp: xp must be > 0');

    await _xpMutex.protect(() async {
      final newXp = loadAccountXp() + xp;
      final newLevel = _calcAccountLevel(newXp);
      await _writeIntegrityInt(SPKeys.accountXp, SPKeys.accountXpTag, newXp);
      await _p.setInt(SPKeys.accountLevel, newLevel);

      _sync.push({
        'accountXp': newXp,
        'accountLevel': newLevel,
      });
    });
  }


  int _calcAccountLevel(int xp) {
    if (xp <= 0) return 1;
    final val = (1.0 + math.sqrt(1.0 + 0.08 * xp)) / 2.0;
    return val.floor().clamp(1, 99);
  }

  List<String> loadUnlockedCharacters() {
    final raw = _p.getString(SPKeys.unlockedCharacters);
    if (raw == null) return ['arthur'];
    return List<String>.from(jsonDecode(raw) as List);
  }

  List<String> loadPermanentUnlocks() {
    return _p.getStringList(SPKeys.permanentUnlocks) ?? [];
  }

  Future<void> unlockCharacter(String characterId) async {
    _guard.requireAuth();

    final current = loadUnlockedCharacters();
    if (current.contains(characterId)) return;
    current.add(characterId);
    await _p.setString(SPKeys.unlockedCharacters, jsonEncode(current));

    _sync.push({'unlockedCharacters': current});
  }

  String? loadEquippedCharacter() => _p.getString(SPKeys.equippedCharacter) ?? 'arthur';

  Future<void> saveEquippedCharacter(String characterId) async {
    await _p.setString(SPKeys.equippedCharacter, characterId);
    _sync.push({'equippedCharacter': characterId});
  }

  List<String> loadInventory() {
    final raw = _p.getString(SPKeys.inventory);
    return raw == null ? [] : List<String>.from(jsonDecode(raw) as List);
  }

  Future<void> saveInventory(List<String> ids) =>
      _p.setString(SPKeys.inventory, jsonEncode(ids));

  List<String> loadUnlockedItems() {
    final raw = _p.getString(SPKeys.unlockedItems);
    return raw == null ? [] : List<String>.from(jsonDecode(raw) as List);
  }

  Future<void> saveUnlockedItems(List<String> ids) async {
    await _p.setString(SPKeys.unlockedItems, jsonEncode(ids));
    _sync.push({'unlockedItems': ids});
  }

  Map<String, String> loadTournamentProgress() {
    final raw = _p.getString(SPKeys.tournamentProgress);
    return raw == null ? {} : Map<String, String>.from(jsonDecode(raw) as Map);
  }

  Future<void> saveTournamentProgress(Map<String, String> progress) async {
    await _p.setString(SPKeys.tournamentProgress, jsonEncode(progress));
    _sync.push({'tournamentProgress': progress});
  }

  Future<GameSettings> loadSettings() async => GameSettings(
        sfxEnabled: _p.getBool(SPKeys.settingsSfx) ?? true,
        bgmEnabled: _p.getBool(SPKeys.settingsBgm) ?? true,

        sfxVolume: _p.getInt(SPKeys.settingsSfxVolume) ?? 80,
        bgmVolume: _p.getInt(SPKeys.settingsBgmVolume) ?? 80,
        selectedLobbyBgm: LobbyBgmType.values[(_p.getInt(SPKeys.settingsLobbyBgmType) ?? 0).clamp(0, LobbyBgmType.values.length - 1)],
      );

  Future<void> saveSettings(GameSettings s) async {
    await Future.wait([
      _p.setBool(SPKeys.settingsSfx, s.sfxEnabled),
      _p.setBool(SPKeys.settingsBgm, s.bgmEnabled),

      _p.setInt(SPKeys.settingsSfxVolume, s.sfxVolume),
      _p.setInt(SPKeys.settingsBgmVolume, s.bgmVolume),
      _p.setInt(SPKeys.settingsLobbyBgmType, s.selectedLobbyBgm.index),
    ]);

    _sync.push({
      'settings': {'sfx': s.sfxEnabled, 'bgm': s.bgmEnabled},
    });
  }

  void incrementTotalWins() {
    final n = getTotalWins() + 1;
    _p.setInt(SPKeys.totalWins, n);

  }

  void incrementTotalParries(int count) {
    final n = getTotalParries() + count;
    _p.setInt(SPKeys.totalParries, n);

  }

  void incrementTotalBroken() {
    final n = getTotalBroken() + 1;
    _p.setInt(SPKeys.totalBroken, n);

  }

  void incrementTotalLogins() {
    final n = (_p.getInt(SPKeys.totalLogins) ?? 0) + 1;
    _p.setInt(SPKeys.totalLogins, n);
    _sync.push({'totalLogins': n});
  }

  int getTotalWins() {
    return _p.getInt(SPKeys.totalWins) ?? 0;
  }

  int getTotalParries() {
    return _p.getInt(SPKeys.totalParries) ?? 0;
  }

  int getTotalBroken() {
    return _p.getInt(SPKeys.totalBroken) ?? 0;
  }

  int getTotalLogins() {
    return _p.getInt(SPKeys.totalLogins) ?? 0;
  }



  Future<void> resetAll() async {
    final keysToKeep = {
      SPKeys.hmacKey,
      SPKeys.adInstallDate,
    };
    final allKeys = _p.getKeys();
    for (final key in allKeys) {
      if (!keysToKeep.contains(key)) {
        await _p.remove(key);
      }
    }
  }


  Future<void> syncFromCloud(Map<String, dynamic> d) async {
    try {
      if (d['ink'] is int) {
        final cloud = d['ink'] as int;
        final local = loadInk();
        if (cloud > local) {
          await _writeIntegrityInt(SPKeys.ink, SPKeys.inkTag, cloud);
        }
      }
    } catch (_) {}

    try {
      if (d['paint'] is int) {
        final cloud = d['paint'] as int;
        final local = loadPaint();
        if (cloud > local) {
          await _writeIntegrityInt(SPKeys.paint, SPKeys.paintTag, cloud);
        }
      }
    } catch (_) {}

    try {
      if (d['accountXp'] is int) {
        await _writeIntegrityInt(
            SPKeys.accountXp, SPKeys.accountXpTag, d['accountXp'] as int);
      }
    } catch (_) {}

    try {
      if (d['tournamentProgress'] is Map) {
        final rawMap = d['tournamentProgress'] as Map;
        final safe = <String, String>{};
        for (final e in rawMap.entries) {
          safe[e.key.toString()] = e.value.toString();
        }
        await _p.setString(SPKeys.tournamentProgress, jsonEncode(safe));
      }
    } catch (e) {
      AppLogger.w('AccountSaveManager', 'syncFromCloud (tournamentProgress) error: $e');
    }

    final accountLevel = (d['accountLevel'] as num?)?.toInt() ?? 1;
    await _p.setInt(SPKeys.accountLevel, accountLevel);

    if (d['unlockedCharacters'] is List) {
      await _p.setString(
        SPKeys.unlockedCharacters,
        jsonEncode(List<String>.from(d['unlockedCharacters'] as List)),
      );
    }
    if (d['equippedCharacter'] is String) {
      await _p.setString(SPKeys.equippedCharacter, d['equippedCharacter'] as String);
    }


    if (d['permanentUnlocks'] is List) {
      await _p.setStringList(
        SPKeys.permanentUnlocks,
        List<String>.from(d['permanentUnlocks'] as List),
      );
    }
    if (d['gamesPlayed'] != null) {
      await _p.setInt(SPKeys.gamesPlayed, (d['gamesPlayed'] as num).toInt());
    }
    if (d['totalWins'] is int) {
      await _p.setInt(SPKeys.totalWins, d['totalWins'] as int);
    }
    if (d['totalParries'] is int) {
      await _p.setInt(SPKeys.totalParries, d['totalParries'] as int);
    }
    if (d['totalBroken'] is int) {
      await _p.setInt(SPKeys.totalBroken, d['totalBroken'] as int);
    }
    if (d['totalLogins'] is int) {
      await _p.setInt(SPKeys.totalLogins, d['totalLogins'] as int);
    }
    if (d['longestWinStreak'] is int) {
      await _p.setInt(SPKeys.longestWinStreak, d['longestWinStreak'] as int);
    }
    if (d['currentWinStreak'] is int) {
      await _p.setInt(SPKeys.currentWinStreak, d['currentWinStreak'] as int);
    }
  }
}
