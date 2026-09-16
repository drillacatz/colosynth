import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colosynth/services/battle_ads_service.dart';
import 'package:colosynth/services/security_guard.dart';
import 'package:colosynth/services/save_manager.dart';
import 'package:colosynth/services/battle/extreme_rotation/extreme_rotation_service.dart';
import 'package:colosynth/services/tutorial/tutorial_service.dart';
import 'package:colosynth/services/user_data_service.dart';

export 'package:colosynth/services/achievement_service.dart' show achievementServiceProvider;
export 'package:colosynth/services/ad_service.dart' show adServiceProvider;
export 'package:colosynth/services/analytics_service.dart' show analyticsServiceProvider;
export 'package:colosynth/services/auth_service.dart' show authServiceProvider;
export 'package:colosynth/services/battle_stats_service.dart' show battleStatsServiceProvider;
export 'package:colosynth/services/daily_task_service.dart'
    show dailyTaskServiceProvider, dailyTaskNotifierProvider;
export 'package:colosynth/services/fcm_service.dart' show fcmServiceProvider;
export 'package:colosynth/services/iap_service.dart'
    show iapServiceProvider, iapPricesProvider;
export 'package:colosynth/services/interstitial_ad_service.dart'
    show interstitialAdServiceProvider;
export 'package:colosynth/services/level_progress_service.dart'
    show levelProgressServiceProvider;
export 'package:colosynth/services/notification_service.dart' show notificationServiceProvider;
export 'package:colosynth/services/remote_config_service.dart'
    show remoteConfigServiceProvider;
export 'package:colosynth/services/review_service.dart' show reviewServiceProvider;
export 'package:colosynth/services/rewarded_ad_service.dart' show rewardedAdServiceProvider;
export 'package:colosynth/services/save_manager.dart' show saveManagerProvider, ISaveRepository;

final saveRepositoryProvider = Provider<ISaveRepository>((_) => SaveManager.instance);

final battleAdsServiceProvider =
    Provider<BattleAdsService>((_) => BattleAdsService.instance);

final securityGuardProvider =
    Provider<SecurityGuard>((_) => SecurityGuard.instance);

final extremeRotationServiceProvider =
    Provider<ExtremeRotationService>((ref) {
  final service = ExtremeRotationService.instance;
  service.ref = ref;
  return service;
});

final tutorialServiceProvider =
    Provider<TutorialService>((_) => TutorialService.instance);

final userDataServiceProvider =
    Provider<UserDataService>((_) => UserDataService());

