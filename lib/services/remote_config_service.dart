import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RemoteConfigService {
  RemoteConfigService._();
  static final RemoteConfigService instance = RemoteConfigService._();

  FirebaseRemoteConfig? _rc;

  static const Map<String, dynamic> _defaults = {
    'ad_interstitial_cooldown_seconds': 30,
    'ad_first_show_delay_hours': 24,
    'ad_rewarded_ink_amount': 50,
    'ad_rewarded_paint_amount': 50,
    'daily_reward_ink': 100,
    'daily_reward_paint': 100,
    'daily_reward_streak_bonus_multiplier': 1.5,
    'iap_first_purchase_bonus_multiplier': 2.0,
    'repeat_battle_ink_percentage': 0.1,
    'repeat_battle_paint_drop': false,
    'repeat_battle_exp_item_drop_rate': 0.30,
    'daily_task_total_ink': 30000,
    'daily_task_total_paint': 50,
    'daily_reward_base_ink': 500,
    'daily_reward_base_paint': 5,
    'daily_reward_streak_multiplier': 1.2,
    'tournament_total_ink': 1000000,
    'tournament_total_paint': 1200,
    'tournament_paint_boss_mult_medium': 2.0,
    'tournament_paint_boss_mult_final': 3.0,
    'daily_first_win_paint': 5,
    'synth_key_paint_price': 50,
    'skill_tree_total_ink': 128000,
    'skill_tree_reset_paint': 20,

    'exp_item_hammer_common_exp': 500,
    'exp_item_hammer_rare_exp': 1000,
    'exp_item_hammer_epic_exp': 2500,
    'exp_item_hammer_legendary_exp': 5000,
    'exp_item_note_common_exp': 500,
    'exp_item_note_rare_exp': 1000,
    'exp_item_note_epic_exp': 2500,
    'exp_item_note_legendary_exp': 5000,
    'exp_item_book_common_xp': 500,
    'exp_item_book_rare_xp': 1000,
    'exp_item_book_epic_xp': 2500,
    'exp_item_book_legendary_xp': 5000,

    'exp_item_common_xp': 500,
    'exp_item_rare_xp': 1000,
    'exp_item_epic_xp': 2500,
    'exp_item_legendary_xp': 5000,
    'account_xp_per_level': 500,
    'tournament_account_xp_multiplier': 1.0,
    'battle_account_xp_min': 10,
    'battle_account_xp_max': 600,
    'battle_exp_item_drop_rate': 0.05,
    'battle_equipment_drop_rate': 0.02,
    'daily_task_account_xp': 500,

    'char_max_xp': 99999,
    'equip_max_xp': 99999,
    'equip_max_level': 90,

    'equip_upgrade_ink_base_multiplier': 13,

    'weekly_activity_milestone_400_paint': 10,
    'weekly_activity_milestone_800_paint': 10,
    'task_pool_ink_per_ap': 20,
    'task_pool_paint_per_task': 2,

    'enemy_stamina_easy': 100,
    'enemy_stamina_medium': 150,
    'enemy_stamina_hard': 200,
    'enemy_stamina_extreme': 250,

    'parry_stamina_drain_pct': 0.80,
    'dodge_stamina_drain_pct': 0.30,
    'block_stamina_drain_pct': 0.10,

    'daily_checkin_makeup_limit_per_cycle': 1,
    'daily_checkin_advance_limit_per_cycle': 1,
    'extreme_mode_ad_attempts_per_day': 5,
    'global_rewarded_ads_daily_cap': 20,
  };

  Future<void> init() async {
    try {
      _rc = FirebaseRemoteConfig.instance;
      await _rc!.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ));
      await _rc!.setDefaults(_defaults);
      await _rc!.fetchAndActivate();
    } catch (e) {
      debugPrint('RemoteConfigService error: $e');
    }
  }

  int _getInt(String key, int fallback) {
    if (_rc == null) {
      return fallback;
    }
    try {
      return _rc!.getInt(key);
    } catch (_) {
      return fallback;
    }
  }

  double _getDouble(String key, double fallback) {
    if (_rc == null) {
      return fallback;
    }
    try {
      return _rc!.getDouble(key);
    } catch (_) {
      return fallback;
    }
  }

  bool _getBool(String key, bool fallback) {
    if (_rc == null) {
      return fallback;
    }
    try {
      return _rc!.getBool(key);
    } catch (_) {
      return fallback;
    }
  }

  int get interstitialCooldownSeconds =>
      _getInt('ad_interstitial_cooldown_seconds', 30);

  int get firstShowDelayHours => _getInt('ad_first_show_delay_hours', 24);

  int get rewardedInkAmount => _getInt('ad_rewarded_ink_amount', 50);

  int get rewardedPaintAmount => _getInt('ad_rewarded_paint_amount', 50);

  int get dailyRewardInk => _getInt('daily_reward_ink', 100);

  int get dailyRewardPaint => _getInt('daily_reward_paint', 100);

  double get dailyStreakBonusMultiplier =>
      _getDouble('daily_reward_streak_bonus_multiplier', 1.5);

  double get iapFirstPurchaseBonusMultiplier =>
      _getDouble('iap_first_purchase_bonus_multiplier', 2.0);

  double get repeatBattleInkPercentage =>
      _getDouble('repeat_battle_ink_percentage', 0.1);

  bool get repeatBattlePaintDrop => _getBool('repeat_battle_paint_drop', false);

  int get dailyTaskTotalInk => _getInt('daily_task_total_ink', 3000);

  int get dailyTaskTotalPaint => _getInt('daily_task_total_paint', 10);

  int get dailyRewardBaseInk => _getInt('daily_reward_base_ink', 500);

  int get dailyRewardBasePaint => _getInt('daily_reward_base_paint', 5);

  double get dailyRewardStreakMultiplier =>
      _getDouble('daily_reward_streak_multiplier', 1.2);


  int get tournamentTotalInk => _getInt('tournament_total_ink', 392000);
  int get tournamentTotalPaint => _getInt('tournament_total_paint', 1200);
  double get tournamentPaintBossMultMedium =>
      _getDouble('tournament_paint_boss_mult_medium', 2.0);
  double get tournamentPaintBossMultFinal =>
      _getDouble('tournament_paint_boss_mult_final', 3.0);
  int get dailyFirstWinPaint => _getInt('daily_first_win_paint', 5);
  int get synthKeyPaintPrice => _getInt('synth_key_paint_price', 50);
  int get skillTreeTotalInk => _getInt('skill_tree_total_ink', 128000);
  int get skillTreeResetPaint => _getInt('skill_tree_reset_paint', 20);


  int get expItemCommonXp => _getInt('exp_item_common_xp', 500);
  int get expItemRareXp => _getInt('exp_item_rare_xp', 1000);
  int get expItemEpicXp => _getInt('exp_item_epic_xp', 2500);
  int get expItemLegendaryXp => _getInt('exp_item_legendary_xp', 5000);


  int get expHammerCommon => _getInt('exp_item_hammer_common_exp', 500);
  int get expHammerRare => _getInt('exp_item_hammer_rare_exp', 1000);
  int get expHammerEpic => _getInt('exp_item_hammer_epic_exp', 2500);
  int get expHammerLegendary => _getInt('exp_item_hammer_legendary_exp', 5000);
  int get expNoteCommon => _getInt('exp_item_note_common_exp', 500);
  int get expNoteRare => _getInt('exp_item_note_rare_exp', 1000);
  int get expNoteEpic => _getInt('exp_item_note_epic_exp', 2500);
  int get expNoteLegendary => _getInt('exp_item_note_legendary_exp', 5000);
  int get expBookCommon => _getInt('exp_item_book_common_xp', 500);
  int get expBookRare => _getInt('exp_item_book_rare_xp', 1000);
  int get expBookEpic => _getInt('exp_item_book_epic_xp', 2500);
  int get expBookLegendary => _getInt('exp_item_book_legendary_xp', 5000);


  int get accountXpPerLevel => _getInt('account_xp_per_level', 500);
  double get tournamentAccountXpMultiplier =>
      _getDouble('tournament_account_xp_multiplier', 1.0);
  int get battleAccountXpMin => _getInt('battle_account_xp_min', 10);
  int get battleAccountXpMax => _getInt('battle_account_xp_max', 600);
  int get dailyTaskAccountXp => _getInt('daily_task_account_xp', 500);


  double get battleExpItemDropRate =>
      _getDouble('battle_exp_item_drop_rate', 0.05);
  double get battleEquipmentDropRate =>
      _getDouble('battle_equipment_drop_rate', 0.02);
  double get repeatBattleExpItemDropRate =>
      _getDouble('repeat_battle_exp_item_drop_rate', 0.30);


  int get charMaxXp => _getInt('char_max_xp', 99999);
  int get equipMaxXp => _getInt('equip_max_xp', 99999);
  int get equipMaxLevel => _getInt('equip_max_level', 90);
  int get equipUpgradeInkBaseMultiplier =>
      _getInt('equip_upgrade_ink_base_multiplier', 50);


  int get weeklyMilestone400Paint =>
      _getInt('weekly_activity_milestone_400_paint', 10);
  int get weeklyMilestone800Paint =>
      _getInt('weekly_activity_milestone_800_paint', 10);
  int get taskPoolInkPerAp => _getInt('task_pool_ink_per_ap', 20);
  int get taskPoolPaintPerTask => _getInt('task_pool_paint_per_task', 2);


  int get enemyStaminaEasy => _getInt('enemy_stamina_easy', 100);
  int get enemyStaminaMedium => _getInt('enemy_stamina_medium', 150);
  int get enemyStaminaHard => _getInt('enemy_stamina_hard', 200);
  int get enemyStaminaExtreme => _getInt('enemy_stamina_extreme', 250);


  double get parryStaminaDrainPct =>
      _getDouble('parry_stamina_drain_pct', 0.80);
  double get dodgeStaminaDrainPct =>
      _getDouble('dodge_stamina_drain_pct', 0.30);
  double get blockStaminaDrainPct =>
      _getDouble('block_stamina_drain_pct', 0.10);

  int get dailyCheckinMakeupLimit =>
      _getInt('daily_checkin_makeup_limit_per_cycle', 1);

  int get dailyCheckinAdvanceLimit =>
      _getInt('daily_checkin_advance_limit_per_cycle', 1);

  int get extremeModeAdAttemptsPerDay =>
      _getInt('extreme_mode_ad_attempts_per_day', 5);

  int get globalRewardedAdsDailyCap =>
      _getInt('global_rewarded_ads_daily_cap', 20);







  int expItemXpFor(String itemId) {
    switch (itemId) {

      case 'exp_hammer_common':    return expHammerCommon;
      case 'exp_hammer_rare':      return expHammerRare;
      case 'exp_hammer_epic':      return expHammerEpic;
      case 'exp_hammer_legendary': return expHammerLegendary;

      case 'exp_note_common':      return expNoteCommon;
      case 'exp_note_rare':        return expNoteRare;
      case 'exp_note_epic':        return expNoteEpic;
      case 'exp_note_legendary':   return expNoteLegendary;

      case 'exp_book_common':      return expBookCommon;
      case 'exp_book_rare':        return expBookRare;
      case 'exp_book_epic':        return expBookEpic;
      case 'exp_book_legendary':   return expBookLegendary;

      case 'exp_common':           return expItemCommonXp;
      case 'exp_rare':             return expItemRareXp;
      case 'exp_epic':             return expItemEpicXp;
      case 'exp_legendary':        return expItemLegendaryXp;
      default:                     return 0;
    }
  }
}

final remoteConfigServiceProvider =
    Provider<RemoteConfigService>((_) => RemoteConfigService.instance);
