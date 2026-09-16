class SPKeys {
  static const String ink = 'colosynth_ink';
  static const String inkTag = 'colosynth_ink_tag';
  static const String paint = 'colosynth_paint';
  static const String paintTag = 'colosynth_paint_tag';
  static const String accountLevel = 'colosynth_account_level';
  static const String accountXp = 'colosynth_account_xp';
  static const String accountXpTag = 'colosynth_account_xp_tag';
  static const String unlockedCharacters = 'colosynth_unlocked_characters';
  static const String equippedCharacter = 'colosynth_equipped_character';
  static const String inventory = 'colosynth_inventory';
  static const String unlockedItems = 'colosynth_unlocked_items';
  static const String tournamentProgress = 'tournament_progress';
  static const String settingsSfx = 'colosynth_settings_sfx';
  static const String settingsBgm = 'colosynth_settings_bgm';

  static String settingsSfxVolume = 'colosynth_settings_sfx_volume';
  static const String settingsBgmVolume = 'colosynth_settings_bgm_volume';
  static const String settingsLobbyBgmType = 'colosynth_settings_lobby_bgm_type';
  static const String settingsAutoRotate3d = 'colosynth_settings_auto_rotate_3d';


  static String charLevel(String id) => 'char_level_$id';
  static String charXp(String id) => 'char_xp_$id';
  static String charBreakthrough(String id) => 'char_bt_$id';
  static String gear(String id) => 'gear_$id';
  static const String expItems = 'colosynth_exp_items';
  static const String skillTree = 'skill_tree';
  static String equipLevel(String slot) => 'colosynth_equip_${slot}_level';
  static String equipXp(String slot) => 'colosynth_equip_${slot}_xp';
  static String equipBreakthrough(String slot) => 'colosynth_equip_${slot}_breakthrough';
  static const String equipmentInstances = 'equipment_instances';
  static const String synthInstances = 'colosynth_synth_instances';
  static String equippedSynths(String charId) => 'colosynth_equipped_synths_$charId';


  static const String hmacKey = '_sg_hmac_key_v1';
  static const String adInstallDate = 'ad_install_date_ms';
  static const String lastDailyPush = 'colosynth_last_daily_push';
  static const String permanentUnlocks = 'colosynth_permanent_unlocks';
  static const String starterGranted = 'colosynth_starter_granted';
  static const String extremeState = 'colosynth_extreme_state';
  static String synthSlotLevel(int slotIndex) => 'colosynth_synth_slot_${slotIndex}_level';
  static const String synthSlot3Unlocked = 'colosynth_synth_slot_3_unlocked';


  static const String gamesPlayed = 'colosynth_games_played';
  static const String totalBattles = 'colosynth_total_battles';

  static const String totalWins = 'colosynth_total_wins';
  static const String totalParries = 'colosynth_total_parries';
  static const String totalBroken = 'colosynth_total_broken';
  static const String longestWinStreak = 'colosynth_longest_win_streak';
  static const String currentWinStreak = 'colosynth_current_win_streak';
  static const String bestEndlessFloor = 'colosynth_best_endless_floor';
  static const String totalLogins = 'colosynth_total_logins';
  static const String tournamentWinsPrefix = 'colosynth_t_win_';

  static const String customDisplayName = 'colosynth_custom_display_name';
  static const String customAvatarId = 'colosynth_custom_avatar_id';
  static const String customBannerId = 'colosynth_custom_banner_id';

  static const String dailyCheckInState = 'colosynth_daily_checkin_state';
  static const String adSafetyValveState = 'colosynth_ad_safety_valve_state';
  static const String extremeAdAttempts = 'colosynth_extreme_ad_attempts';

  static const String loginRewardClaimedGoogle = 'colosynth_login_reward_claimed_google';
  static const String loginRewardClaimedPlayGames = 'colosynth_login_reward_claimed_play_games';
}
