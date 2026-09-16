import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:colosynth/utils/app_config.dart';

class SecurityGuard {
  SecurityGuard._();
  static final SecurityGuard instance = SecurityGuard._();

  static const _kHmacKey = '_sg_hmac_key_v1';
  static const _kMaxAwardsPerWindow = 8;
  static final _envSecret = AppConfig.hmacSecret;

  String? _hmacKey;
  String? _uid;
  final _stopwatch = Stopwatch()..start();
  final _awardTimestamps = <int>[];

  int _battleRewardsClaimedThisSession = 0;
  static const _maxBattleRewardsPerSession = 100;

  Future<void> init(SharedPreferences prefs) async {
    _uid = prefs.getString('colosynth_save_owner_uid') ?? 'local_guest_offline';
    if (_envSecret.isNotEmpty) {
      _hmacKey = _envSecret;
      return;
    }
    var key = prefs.getString(_kHmacKey);
    if (key == null) {
      final entropy =
          '${DateTime.now().microsecondsSinceEpoch}_${Object().hashCode}_${prefs.hashCode}';
      key = sha256.convert(utf8.encode(entropy)).toString();
      await prefs.setString(_kHmacKey, key);
    }
    _hmacKey = key;
  }

  void bindUser(String uid) {
    _uid = uid;
    _awardTimestamps.clear();
    _battleRewardsClaimedThisSession = 0;
  }

  void unbindUser() {
    _uid = null;
    _awardTimestamps.clear();
    _battleRewardsClaimedThisSession = 0;
  }

  bool get isAuthenticated => _uid != null;

  void requireAuth() {
    if (_uid == null) {
      throw const UnauthenticatedException();
    }
  }

  void checkAwardRate(String source) {
    if (_iapSources.contains(source)) return;

    if (source == 'tournament_stage_reward' ||
        source == 'tournament_repeat_battle' ||
        source == 'tournament_extreme_daily' ||
        source == 'tournament_extreme_repeat' ||
        source == 'endless_floor_reward' ||
        source == 'daily_task' ||
        source == 'weekly_activity' ||
        source == 'daily_milestone' ||
        source.startsWith('daily_checkin')) {
      _battleRewardsClaimedThisSession++;
      if (_battleRewardsClaimedThisSession > _maxBattleRewardsPerSession) {
        throw RateLimitException(source);
      }
      return;
    }

    final nowMs = _stopwatch.elapsedMilliseconds;
    _awardTimestamps.removeWhere(
      (ms) => nowMs - ms > 60000,
    );
    if (_awardTimestamps.length >= _kMaxAwardsPerWindow) {
      throw RateLimitException(source);
    }
    _awardTimestamps.add(nowMs);
  }

  static const _iapSources = {
    'store_iap',
    'store_purchase',
    'colosynth_ad_free',
    'colosynth_ink_12000',
    'colosynth_ink_70000',
    'colosynth_ink_160000',
    'colosynth_ink_380000',
    'colosynth_ink_1100000',
    'colosynth_ink_2500000',
    'colosynth_paint_15',
    'colosynth_paint_85',
    'colosynth_paint_190',
    'colosynth_paint_420',
    'colosynth_paint_1150',
    'colosynth_paint_2500',
    'iap:ink_3000',
    'iap:ink_5000',
    'iap:ink_20000',
    'iap:ink_50000',
    'iap:ink_100000',
    'iap:ink_200000',
    'iap:ink_12000',
    'iap:ink_70000',
    'iap:ink_160000',
    'iap:ink_380000',
    'iap:ink_1100000',
    'iap:ink_2500000',
    'iap:paint_60',
    'iap:paint_180',
    'iap:paint_360',
    'iap:paint_500',
    'iap:paint_1200',
    'iap:paint_15',
    'iap:paint_85',
    'iap:paint_190',
    'iap:paint_420',
    'iap:paint_1150',
    'iap:paint_2500',
    'iap:combo_gearup',
    'iap:combo_deep',
    'iap:starter_bundle',
  };

  static const _validAwardSources = {
    'store_iap',
    'store_purchase',
    'shop_refund',
    'daily_bonus',
    'daily_checkin',
    'achievement',
    'first_login',
    'login_reward_google',
    'login_reward_play_games',
    'daily_first_win',
    'tournament_stage_reward',
    'tournament_repeat_battle',
    'ad_double_ink',
    'daily_task',
    'weekly_activity',
    'daily_milestone',
    'endless_floor_reward',
    'tournament_character_unlock',
    'tournament_extreme_daily',
    'tournament_extreme_repeat',
    'tournament_synth_key',
    'colosynth_ad_free',
    'colosynth_ink_12000',
    'colosynth_ink_70000',
    'colosynth_ink_160000',
    'colosynth_ink_380000',
    'colosynth_ink_1100000',
    'colosynth_ink_2500000',
    'colosynth_paint_15',
    'colosynth_paint_85',
    'colosynth_paint_190',
    'colosynth_paint_420',
    'colosynth_paint_1150',
    'colosynth_paint_2500',
    'iap:ink_3000',
    'iap:ink_5000',
    'iap:ink_20000',
    'iap:ink_50000',
    'iap:ink_100000',
    'iap:ink_200000',
    'iap:ink_12000',
    'iap:ink_70000',
    'iap:ink_160000',
    'iap:ink_380000',
    'iap:ink_1100000',
    'iap:ink_2500000',
    'iap:paint_60',
    'iap:paint_180',
    'iap:paint_360',
    'iap:paint_500',
    'iap:paint_1200',
    'iap:paint_15',
    'iap:paint_85',
    'iap:paint_190',
    'iap:paint_420',
    'iap:paint_1150',
    'iap:paint_2500',
    'iap:combo_gearup',
    'iap:combo_deep',
    'iap:starter_bundle',
  };

  static const _validSpendReasons = {
    'shop_item',
    'unlock_character',
    'upgrade_character',
    'upgrade_weapon',
    'upgrade_shield',
    'upgrade_armor',
    'upgrade_helmet',
    'recruit',
    'character_breakthrough',
    'equipment_breakthrough',
    'skill_reset',
    'skill_unlock',
    'exp_item_exchange',
    'synth_crate_open',
    'synth_slot3_unlock',
    'synth_key_purchase',
  };


  bool isIapSource(String source) => _iapSources.contains(source);

  void validateAwardSource(String source) {
    if (_validAwardSources.contains(source) || source.startsWith('daily_checkin')) {
      return;
    }
    throw InvalidSourceException(source);
  }

  void validateSpendReason(String reason) {
    if (!_validSpendReasons.contains(reason)) {
      throw InvalidSourceException(reason);
    }
  }

  String _computeTagForUid(String? targetUid, String fieldName, int value) {
    if (_hmacKey == null) {
      throw StateError('SecurityGuard.init() must be called before computeTag');
    }
    final message = utf8.encode('$fieldName:$value');
    final combinedKey = '$_hmacKey:$targetUid';
    final key = utf8.encode(combinedKey);
    final hmac = Hmac(sha256, key);
    return hmac.convert(message).toString();
  }

  String computeTag(String fieldName, int value) =>
      _computeTagForUid(_uid, fieldName, value);

  bool verifyTag(String fieldName, int value, String? storedTag) {
    if (storedTag == null) return false;
    if (computeTag(fieldName, value) == storedTag) return true;
    if (_uid != null &&
        _uid != 'local_guest_offline' &&
        _computeTagForUid('local_guest_offline', fieldName, value) == storedTag) {
      return true;
    }
    return false;
  }
}

class UnauthenticatedException implements Exception {
  const UnauthenticatedException();
  @override
  String toString() =>
      'UnauthenticatedException: operation requires a signed-in account';
}

class RateLimitException implements Exception {
  const RateLimitException(this.source);
  final String source;
  @override
  String toString() =>
      'RateLimitException: too many awards for source "$source"';
}

class InvalidSourceException implements Exception {
  const InvalidSourceException(this.value);
  final String value;
  @override
  String toString() => 'InvalidSourceException: unknown value "$value"';
}

class TamperDetectedException implements Exception {
  const TamperDetectedException(this.field);
  final String field;
  @override
  String toString() =>
      'TamperDetectedException: local value of "$field" has been modified';
}
