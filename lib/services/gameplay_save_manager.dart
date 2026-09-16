import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:colosynth/services/sp_manager.dart';
import 'package:colosynth/services/account_sync_service.dart';
import 'package:colosynth/database/character/character_equipment_slot.dart';
import 'package:colosynth/database/synth/synth_instance.dart';
import 'package:colosynth/growth/character/character_progression.dart';

class GameplaySaveManager {
  GameplaySaveManager(this._p);

  final SharedPreferences _p;

  void bindUser(String uid) {}

  void unbindUser() {}

  int loadCharLevelFor(String characterId) =>
      _p.getInt(SPKeys.charLevel(characterId)) ?? 1;

  int loadCharXpFor(String characterId) =>
      _p.getInt(SPKeys.charXp(characterId)) ?? 0;

  int loadCharBreakthroughFor(String characterId) =>
      _p.getInt(SPKeys.charBreakthrough(characterId)) ?? 0;

  Future<void> addCharXpFor(String characterId, int xp) async {
    if (xp <= 0) throw ArgumentError('addCharXpFor: xp must be > 0');
    final newXp = loadCharXpFor(characterId) + xp;
    final newLevel = _calcCharLevel(newXp);
    await Future.wait([
      _p.setInt(SPKeys.charXp(characterId), newXp),
      _p.setInt(SPKeys.charLevel(characterId), newLevel),
    ]);
    AccountSyncService.instance.push({
      'characters.$characterId.xp': newXp,
    });
  }

  Future<void> saveCharBreakthroughFor(String characterId, int count) async {
    await _p.setInt(SPKeys.charBreakthrough(characterId), count);
    AccountSyncService.instance.push({
      'characters.$characterId.breakthrough': count,
    });
  }

  int _calcCharLevel(int xp) => CharacterProgression.calcLevel(xp);

  Map<String, CharacterEquipmentSlot> loadEquipmentFor(String charId) {
    final weaponLevel = _p.getInt('colosynth_char_${charId}_equip_weapon_level') ?? 1;
    final weaponXp = _p.getInt('colosynth_char_${charId}_equip_weapon_xp') ?? 0;
    final weaponBt = _p.getInt('colosynth_char_${charId}_equip_weapon_breakthrough') ?? 0;

    final shieldLevel = _p.getInt('colosynth_char_${charId}_equip_shield_level') ?? 1;
    final shieldXp = _p.getInt('colosynth_char_${charId}_equip_shield_xp') ?? 0;
    final shieldBt = _p.getInt('colosynth_char_${charId}_equip_shield_breakthrough') ?? 0;

    final armorLevel = _p.getInt('colosynth_char_${charId}_equip_armor_level') ?? 1;
    final armorXp = _p.getInt('colosynth_char_${charId}_equip_armor_xp') ?? 0;
    final armorBt = _p.getInt('colosynth_char_${charId}_equip_armor_breakthrough') ?? 0;

    final helmetLevel = _p.getInt('colosynth_char_${charId}_equip_helmet_level') ?? 1;
    final helmetXp = _p.getInt('colosynth_char_${charId}_equip_helmet_xp') ?? 0;
    final helmetBt = _p.getInt('colosynth_char_${charId}_equip_helmet_breakthrough') ?? 0;

    return {
      'weapon': CharacterEquipmentSlot(level: weaponLevel, xp: weaponXp, breakthroughCount: weaponBt),
      'shield': CharacterEquipmentSlot(level: shieldLevel, xp: shieldXp, breakthroughCount: shieldBt),
      'armor': CharacterEquipmentSlot(level: armorLevel, xp: armorXp, breakthroughCount: armorBt),
      'helmet': CharacterEquipmentSlot(level: helmetLevel, xp: helmetXp, breakthroughCount: helmetBt),
    };
  }

  Future<void> saveEquipmentLevelFor(String charId, String slotKey, int level) async {
    await _p.setInt('colosynth_char_${charId}_equip_${slotKey}_level', level);
    await _p.setInt('colosynth_char_${charId}_equip_${slotKey}_xp', 0);
    AccountSyncService.instance.push({
      'characters.$charId.equipment.$slotKey.level': level,
      'characters.$charId.equipment.$slotKey.xp': 0,
    });
  }

  Future<void> saveEquipmentXpFor(String charId, String slotKey, int xp) async {
    await _p.setInt('colosynth_char_${charId}_equip_${slotKey}_xp', xp);
    AccountSyncService.instance.push({
      'characters.$charId.equipment.$slotKey.xp': xp,
    });
  }

  Future<void> saveEquipmentBreakthroughFor(String charId, String slotKey, int breakthrough) async {
    await _p.setInt('colosynth_char_${charId}_equip_${slotKey}_breakthrough', breakthrough);
    AccountSyncService.instance.push({
      'characters.$charId.equipment.$slotKey.breakthrough': breakthrough,
    });
  }

  Map<String, int> loadExpItems() {
    final raw = _p.getString(SPKeys.expItems);
    if (raw == null) return {};
    return Map<String, int>.from(jsonDecode(raw) as Map);
  }

  Future<void> addExpItem(String itemId, int count) async {
    if (count <= 0) throw ArgumentError('addExpItem: count must be > 0');
    final current = loadExpItems();
    current[itemId] = (current[itemId] ?? 0) + count;
    await _p.setString(SPKeys.expItems, jsonEncode(current));
    AccountSyncService.instance.push({'expItems': current});
  }

  Future<bool> consumeExpItem(String itemId) async {
    final current = loadExpItems();
    final qty = current[itemId] ?? 0;
    if (qty <= 0) return false;
    if (qty == 1) {
      current.remove(itemId);
    } else {
      current[itemId] = qty - 1;
    }
    await _p.setString(SPKeys.expItems, jsonEncode(current));
    AccountSyncService.instance.push({'expItems': current});
    return true;
  }

  Set<String> loadSkillTree() {
    final list = _p.getStringList(SPKeys.skillTree);
    if (list == null) return {};
    return Set<String>.from(list);
  }

  Future<void> saveSkillTree(Set<String> nodes) async {
    await _p.setStringList(SPKeys.skillTree, nodes.toList());
    AccountSyncService.instance.push({
      'skillTree': nodes.toList(),
    });
  }

  Future<void> resetSkillTree() async {
    await _p.setStringList(SPKeys.skillTree, []);
    AccountSyncService.instance.push({'skillTree': []});
  }

  Future<void> syncFromCloud(Map<String, dynamic> d) async {
    if (d['characters'] is Map) {
      final characters = d['characters'] as Map<String, dynamic>;
      for (final entry in characters.entries) {
        final charId = entry.key;
        final data = entry.value as Map<String, dynamic>?;
        if (data == null) continue;

        final xp = (data['xp'] as num?)?.toInt() ?? 0;
        final level = _calcCharLevel(xp);
        final bt = (data['breakthrough'] as num?)?.toInt() ?? 0;

        final futures = <Future<void>>[
          _p.setInt(SPKeys.charXp(charId), xp),
          _p.setInt(SPKeys.charLevel(charId), level),
          _p.setInt(SPKeys.charBreakthrough(charId), bt),
        ];

        final equipment = data['equipment'] as Map<String, dynamic>?;
        if (equipment != null) {
          for (final slotEntry in equipment.entries) {
            final slot = slotEntry.key;
            final slotData = slotEntry.value as Map<String, dynamic>?;
            if (slotData != null) {
              final lvl = (slotData['level'] as num?)?.toInt() ?? 1;
              final slotXp = (slotData['xp'] as num?)?.toInt() ?? 0;
              final slotBt = (slotData['breakthroughCount'] as num?)?.toInt() ?? 0;
              futures.add(_p.setInt('colosynth_char_${charId}_equip_${slot}_level', lvl));
              futures.add(_p.setInt('colosynth_char_${charId}_equip_${slot}_xp', slotXp));
              futures.add(_p.setInt('colosynth_char_${charId}_equip_${slot}_breakthrough', slotBt));
            }
          }
        }

        await Future.wait(futures);
      }
    }

    if (d['expItems'] is Map) {
      await _p.setString(
        SPKeys.expItems,
        jsonEncode(Map<String, int>.from(d['expItems'] as Map)),
      );
    }

    if (d['skillTree'] is List) {
      await _p.setStringList(
        SPKeys.skillTree,
        List<String>.from(d['skillTree'] as List),
      );
    }

    if (d['equipmentProgress'] is Map) {
      final map = d['equipmentProgress'] as Map<String, dynamic>;
      await _p.setString(SPKeys.equipmentInstances, jsonEncode(map));
    }

    if (d['synthInstances'] is Map) {
      await _p.setString(
        SPKeys.synthInstances,
        jsonEncode(d['synthInstances'] as Map),
      );
    }

    if (d['equippedSynths'] is Map) {
      final map = d['equippedSynths'] as Map<String, dynamic>;
      for (final entry in map.entries) {
        await _p.setString(
          SPKeys.equippedSynths(entry.key),
          jsonEncode(entry.value),
        );
      }
    }

    if (d['extremeState'] is Map) {
      await _p.setString(SPKeys.extremeState, jsonEncode(d['extremeState']));
    }

    if (d['synthSlotLevel'] is Map) {
      final map = d['synthSlotLevel'] as Map<String, dynamic>;
      for (final entry in map.entries) {
        final parsedIdx = int.tryParse(entry.key);
        if (parsedIdx != null) {
          await _p.setInt(SPKeys.synthSlotLevel(parsedIdx), (entry.value as num).toInt());
        }
      }
    }

    if (d['synthSlot3Unlocked'] is bool) {
      await _p.setBool(SPKeys.synthSlot3Unlocked, d['synthSlot3Unlocked'] as bool);
    }

    if (d['synthKeys'] != null) {
      await _p.setInt('colosynth_synth_keys', (d['synthKeys'] as num).toInt());
    }
  }

  Map<String, SynthInstance> loadSynthInstances() {
    final raw = _p.getString(SPKeys.synthInstances);
    if (raw == null || raw.isEmpty) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map(
      (k, v) => MapEntry(k, SynthInstance.fromJson(v as Map<String, dynamic>)),
    );
  }

  Future<void> saveSynthInstances(Map<String, SynthInstance> instances) async {
    final jsonMap = instances.map((k, v) => MapEntry(k, v.toJson()));
    await _p.setString(SPKeys.synthInstances, jsonEncode(jsonMap));
    AccountSyncService.instance.push({
      'synthInstances': jsonMap,
    });
  }

  List<String?> loadEquippedSynthsFor(String characterId) {
    final raw = _p.getString(SPKeys.equippedSynths(characterId));
    if (raw == null || raw.isEmpty) {
      return List<String?>.filled(4, null, growable: false);
    }
    final list = jsonDecode(raw) as List<dynamic>;
    return List<String?>.from(list.map((e) => e as String?));
  }

  Future<void> saveEquippedSynthsFor(String characterId, List<String?> equipped) async {
    await _p.setString(SPKeys.equippedSynths(characterId), jsonEncode(equipped));
    AccountSyncService.instance.push({
      'equippedSynths.$characterId': equipped,
    });
  }

  String? loadExtremeStateRaw() => _p.getString(SPKeys.extremeState);

  Future<void> saveExtremeStateRaw(String rawJson) async {
    await _p.setString(SPKeys.extremeState, rawJson);
    AccountSyncService.instance.push({
      'extremeState': jsonDecode(rawJson),
    });
  }

  int loadSynthSlotLevel(int slotIndex) {
    return _p.getInt(SPKeys.synthSlotLevel(slotIndex)) ?? 1;
  }

  Future<void> saveSynthSlotLevel(int slotIndex, int level) async {
    await _p.setInt(SPKeys.synthSlotLevel(slotIndex), level);
    AccountSyncService.instance.push({
      'synthSlotLevel.$slotIndex': level,
    });
  }

  bool loadSynthSlot3Unlocked() {
    return _p.getBool(SPKeys.synthSlot3Unlocked) ?? false;
  }

  Future<void> saveSynthSlot3Unlocked(bool unlocked) async {
    await _p.setBool(SPKeys.synthSlot3Unlocked, unlocked);
    AccountSyncService.instance.push({
      'synthSlot3Unlocked': unlocked,
    });
  }

  int loadSynthKeys() {
    return _p.getInt('colosynth_synth_keys') ?? 0;
  }

  Future<void> saveSynthKeys(int count) async {
    await _p.setInt('colosynth_synth_keys', count);
    AccountSyncService.instance.push({
      'synthKeys': count,
    });
  }

  String? loadDailyCheckInStateRaw() {
    return _p.getString(SPKeys.dailyCheckInState);
  }

  Future<void> saveDailyCheckInStateRaw(String rawJson) async {
    await _p.setString(SPKeys.dailyCheckInState, rawJson);
    AccountSyncService.instance.push({
      'dailyCheckInState': jsonDecode(rawJson),
    });
  }

  String? loadAdSafetyValveStateRaw() {
    return _p.getString(SPKeys.adSafetyValveState);
  }

  Future<void> saveAdSafetyValveStateRaw(String rawJson) async {
    await _p.setString(SPKeys.adSafetyValveState, rawJson);
    AccountSyncService.instance.push({
      'adSafetyValveState': jsonDecode(rawJson),
    });
  }

  String? loadExtremeAdAttemptsRaw() {
    return _p.getString(SPKeys.extremeAdAttempts);
  }

  Future<void> saveExtremeAdAttemptsRaw(String rawJson) async {
    await _p.setString(SPKeys.extremeAdAttempts, rawJson);
    AccountSyncService.instance.push({
      'extremeAdAttempts': jsonDecode(rawJson),
    });
  }
}
