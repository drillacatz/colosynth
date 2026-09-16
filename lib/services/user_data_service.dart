
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:colosynth/utils/app_logger.dart';
import 'package:colosynth/growth/character/character_progression.dart';
import 'package:colosynth/services/sp_manager.dart';

class UserDataService {
  final _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  Future<void> initUser(
    String uid, {
    required bool isGuest,
  }) async {
    if (uid == 'local_guest_offline') return;
    final ref = _userDoc(uid);
    try {
      final snap = await ref.get().timeout(const Duration(seconds: 4));
      if (snap.exists) {
        final currentIsGuest = snap.data()?['isGuest'] as bool? ?? true;
        if (!isGuest && currentIsGuest) {
          await ref.update({
            'isGuest': false,
            'updatedAt': FieldValue.serverTimestamp(),
          }).timeout(const Duration(seconds: 4));
        }
        return;
      }

      await ref.set({
        'uid': uid,
        'isGuest': isGuest,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'ink': 0,
        'paint': 0,
        'charLevel': 1,
        'charXp': 0,
        'accountLevel': 1,
        'accountXp': 0,
        'unlockedCharacters': <String>['arthur'],
        'equippedCharacter': 'arthur',
        'tournamentProgress': <String, String>{},
        'fcmToken': '',
      }).timeout(const Duration(seconds: 4));
    } catch (e, stack) {
      AppLogger.e('UserDataService', 'initUser timed out or failed ($e). Continuing in offline/fallback mode.', stack);
    }
  }

  Future<void> deleteUser(String uid) async {
    try {
      final txnSnap = await _userDoc(uid).collection('transactions').get();
      for (final doc in txnSnap.docs) {
        await doc.reference.delete();
      }
      await _userDoc(uid).delete();
    } catch (e, stack) {
      AppLogger.e('UserDataService', 'deleteUser error: $e', stack);
    }
  }

  Future<void> migrateGuestData(String guestUid, String newUid) async {
    final guestSnap = await _userDoc(guestUid).get();
    if (!guestSnap.exists) return;

    final g = guestSnap.data()!;
    final newSnap = await _userDoc(newUid).get();
    final n = newSnap.exists ? newSnap.data()! : <String, dynamic>{};

    final mergedInk = _intOf(g, 'ink') + _intOf(n, 'ink');
    final mergedPaint = _intOf(g, 'paint') + _intOf(n, 'paint');
    final mergedCharXp = _charXpOf(g) + _charXpOf(n);
    final mergedCharLevel = CharacterProgression.calcLevel(mergedCharXp);
    final mergedAccountXp = _intOf(g, 'accountXp') + _intOf(n, 'accountXp');
    final mergedAccountLevel = _calcAccountLevel(mergedAccountXp);

    final gChars = _listOf(g, 'unlockedCharacters');
    final nChars = _listOf(n, 'unlockedCharacters');
    final mergedChars = {...gChars, ...nChars}.toList();

    final gProgress = _mapOf(g, 'tournamentProgress');
    final nProgress = _mapOf(n, 'tournamentProgress');
    final mergedProgress = {...gProgress, ...nProgress};


    

    final gCharacters = _mapOfDynamic(g, 'characters');
    final nCharacters = _mapOfDynamic(n, 'characters');
    final mergedCharacters = <String, dynamic>{};
    for (final charId in {...gCharacters.keys, ...nCharacters.keys}) {
      final gChar = _mapOfDynamic(gCharacters, charId);
      final nChar = _mapOfDynamic(nCharacters, charId);
      
      final charXp = _intOf(gChar, 'xp') + _intOf(nChar, 'xp');
      final charLevel = CharacterProgression.calcLevel(charXp);
      
      final gGear = gChar['gear'] as Map<dynamic, dynamic>? ?? {};
      final nGear = nChar['gear'] as Map<dynamic, dynamic>? ?? {};
      final gear = {...gGear, ...nGear};
      
      mergedCharacters[charId] = {
        'xp': charXp,
        'level': charLevel,
        'gear': gear,
      };
    }


    final gEquip = _mapOfDynamic(g, 'equipmentProgress');
    final nEquip = _mapOfDynamic(n, 'equipmentProgress');
    final mergedEquip = {...gEquip, ...nEquip};


    final gExp = _mapOfDynamic(g, 'expItems');
    final nExp = _mapOfDynamic(n, 'expItems');
    final mergedExp = <String, dynamic>{};
    for (final key in {...gExp.keys, ...nExp.keys}) {
      mergedExp[key] = _intOf(gExp, key) + _intOf(nExp, key);
    }



    final gInv = _listOf(g, 'inventory');
    final nInv = _listOf(n, 'inventory');
    final mergedInv = {...gInv, ...nInv}.toList();


    final gPerm = _listOf(g, 'permanentUnlocks');
    final nPerm = _listOf(n, 'permanentUnlocks');
    final mergedPerm = {...gPerm, ...nPerm}.toList();


    final mergedGamesPlayed = _intOf(g, 'gamesPlayed') + _intOf(n, 'gamesPlayed');

    await _userDoc(newUid).set({
      'isGuest': false,
      'ink': mergedInk,
      'paint': mergedPaint,
      'charXp': mergedCharXp,
      'charLevel': mergedCharLevel,
      'accountXp': mergedAccountXp,
      'accountLevel': mergedAccountLevel,
      'unlockedCharacters': mergedChars,
      'tournamentProgress': mergedProgress,
      'characters': mergedCharacters,
      'equipmentProgress': mergedEquip,
      'expItems': mergedExp,
      'inventory': mergedInv,
      'permanentUnlocks': mergedPerm,
      'gamesPlayed': mergedGamesPlayed,
      'migratedFrom': guestUid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _userDoc(guestUid).delete();
  }

  int _intOf(Map<String, dynamic> m, String key) =>
      (m[key] as num?)?.toInt() ?? 0;

  int _charXpOf(Map<String, dynamic> m) {
    final charXp = (m['charXp'] as num?)?.toInt();
    if (charXp != null && charXp > 0) return charXp;
    return (m['xp'] as num?)?.toInt() ?? 0;
  }

  int _calcAccountLevel(int xp) {
    if (xp <= 0) return 1;
    final val = (1.0 + math.sqrt(1.0 + 0.08 * xp)) / 2.0;
    return val.floor().clamp(1, 99);
  }

  List<String> _listOf(Map<String, dynamic> m, String key) {
    final v = m[key];
    if (v is List) return List<String>.from(v);
    return [];
  }

  Map<String, String> _mapOf(Map<String, dynamic> m, String key) {
    final v = m[key];
    if (v is Map) return Map<String, String>.from(v);
    return {};
  }

  Map<String, dynamic> _mapOfDynamic(Map<String, dynamic> m, String key) {
    final v = m[key];
    if (v is Map) return Map<String, dynamic>.from(v);
    return {};
  }


  /// Returns true if the one-time login reward for [type] ('google' or
  /// 'play_games') has already been claimed for [uid].
  /// Checks Firestore first; falls back to [prefs] local cache.
  Future<bool> hasClaimedLoginReward(
    String uid,
    String type, {
    SharedPreferences? prefs,
  }) async {
    if (uid == 'local_guest_offline') return true;
    if (prefs != null) {
      final key = type == 'google'
          ? SPKeys.loginRewardClaimedGoogle
          : SPKeys.loginRewardClaimedPlayGames;
      if (prefs.getBool(key) == true) return true;
    }
    try {
      final snap = await _userDoc(uid)
          .get()
          .timeout(const Duration(seconds: 4));
      final claimed = snap.data()?['loginRewardClaimed'] as Map?;
      return claimed?[type] == true;
    } catch (e) {
      AppLogger.w('UserDataService', 'hasClaimedLoginReward error: $e');
      return false;
    }
  }

  /// Atomically claims the login reward for [type]. Returns true if the claim
  /// succeeded (first time), false if it was already claimed.
  Future<bool> claimLoginReward(
    String uid,
    String type, {
    SharedPreferences? prefs,
  }) async {
    if (uid == 'local_guest_offline') return false;
    try {
      final ref = _userDoc(uid);
      bool didClaim = false;
      await _db.runTransaction((txn) async {
        final snap = await txn.get(ref);
        final claimed = (snap.data()?['loginRewardClaimed'] as Map?) ?? {};
        if (claimed[type] == true) {
          didClaim = false;
          return;
        }
        txn.set(
          ref,
          {
            'loginRewardClaimed': {...claimed, type: true},
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        didClaim = true;
      });
      if (didClaim && prefs != null) {
        final key = type == 'google'
            ? SPKeys.loginRewardClaimedGoogle
            : SPKeys.loginRewardClaimedPlayGames;
        await prefs.setBool(key, true);
      }
      return didClaim;
    } catch (e) {
      AppLogger.e('UserDataService', 'claimLoginReward error: $e');
      return false;
    }
  }


  /// Saves a custom display name override for the user (both locally and
  /// in Firestore so it's available across devices).
  Future<void> saveCustomDisplayName(
    String uid,
    String name, {
    required SharedPreferences prefs,
  }) async {
    await prefs.setString(SPKeys.customDisplayName, name);
    if (uid == 'local_guest_offline') return;
    try {
      await _userDoc(uid).set(
        {'customDisplayName': name, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    } catch (e) {
      AppLogger.w('UserDataService', 'saveCustomDisplayName error: $e');
    }
  }

  /// Loads custom display name from [prefs] (local cache). Returns null if
  /// no override has been set.
  String? loadCustomDisplayName({required SharedPreferences prefs}) =>
      prefs.getString(SPKeys.customDisplayName);
}

