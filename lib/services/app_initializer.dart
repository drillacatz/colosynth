import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:colosynth/utils/app_config.dart';
import 'package:colosynth/utils/app_logger.dart';
import 'package:colosynth/guide/guide_persistence.dart';
import 'package:colosynth/services/save_manager.dart';
import 'package:colosynth/services/security_guard.dart';
import 'package:colosynth/services/stats/player_stats_tracker.dart';
import 'package:colosynth/services/app_memory_manager.dart';
import 'package:colosynth/services/audio_service.dart';
import 'package:colosynth/services/auth_service.dart';
import 'package:colosynth/services/battle_ads_service.dart';
import 'package:colosynth/services/daily_task_service.dart';
import 'package:colosynth/services/fcm_service.dart';
import 'package:colosynth/services/tutorial/tutorial_service.dart';
import 'package:colosynth/services/level_progress_service.dart';
import 'package:colosynth/services/battle_stats_service.dart';
import 'package:colosynth/services/purchase_ledger_service.dart';
import 'package:colosynth/services/iap_service.dart';

class AppInitializationResult {
  final SharedPreferences prefs;
  final bool warmStart;

  const AppInitializationResult({
    required this.prefs,
    required this.warmStart,
  });
}

class AppInitializer {
  static const String _kHomeTsKey = '_colosynth_home_ts';
  static const int _kWarmWindowMs = 8 * 60 * 60 * 1000;

  static Completer<AppInitializationResult>? _initCompleter;

  static Future<AppInitializationResult> run([SharedPreferences? prefs]) {
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }
    _initCompleter = Completer<AppInitializationResult>();
    _doRun(prefs).then((result) {
      _initCompleter!.complete(result);
    }).catchError((e, stack) {
      _initCompleter!.completeError(e, stack);
      _initCompleter = null;
    });
    return _initCompleter!.future;
  }

  static Future<AppInitializationResult> _doRun([SharedPreferences? existingPrefs]) async {
    AppConfig.validate();

    if (Firebase.apps.isEmpty) {
      try {
        final apiKey = AppConfig.firebaseAndroidApiKey;
        if (apiKey.isEmpty || apiKey.startsWith('YOUR_')) {
          throw StateError('Firebase keys are not configured');
        }
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: AppConfig.firebaseAndroidApiKey,
            appId: AppConfig.firebaseAndroidAppId,
            messagingSenderId: AppConfig.firebaseMessagingSenderId,
            projectId: AppConfig.firebaseProjectId,
            storageBucket: AppConfig.firebaseStorageBucket,
          ),
        ).timeout(const Duration(seconds: 10));
      } catch (e) {
        final errorStr = e.toString();
        if (errorStr.contains('duplicate-app') || errorStr.contains('already exists')) {
          AppLogger.d('AppInitializer', 'Firebase prod initialization: app already exists, ignoring. ($e)');
        } else {
          AppLogger.w('AppInitializer', 'Firebase initialization failed ($e). Operating in offline local mode.');
        }
      }
    }

    final existingFlutterErrorHandler = FlutterError.onError;
    if (Firebase.apps.isNotEmpty) {
      try {
        FlutterError.onError = (details) {
          existingFlutterErrorHandler?.call(details);
          try {
            FirebaseCrashlytics.instance.recordFlutterFatalError(details);
          } catch (_) {}
        };
        PlatformDispatcher.instance.onError = (error, stack) {
          try {
            FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          } catch (_) {}
          return true;
        };
        unawaited(AppLogger.flushOfflineQueue());
      } catch (e) {
        debugPrint('Crashlytics setup failed: $e');
      }
    } else {
      FlutterError.onError = (details) {
        existingFlutterErrorHandler?.call(details);
        AppLogger.e('FlutterError', details.exceptionAsString(), details.stack);
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        AppLogger.e('PlatformError', error, stack);
        return true;
      };
    }

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    final prefs = existingPrefs ?? await SharedPreferences.getInstance().timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('SharedPreferences initialization timed out'),
    );
    final lastHomeTs = prefs.getInt(_kHomeTsKey) ?? 0;
    final elapsed = DateTime.now().millisecondsSinceEpoch - lastHomeTs;
    final warmStart = elapsed < _kWarmWindowMs;

    unawaited(prefs.setInt(_kHomeTsKey, DateTime.now().millisecondsSinceEpoch));

    AppMemoryManager.instance.init();
    try {
      await AudioService.instance.init();
    } catch (e) {
      AppLogger.w('AppInitializer', 'AudioService initialization warning: $e');
    }
    await SaveManager.instance.init(prefs);
    await PurchaseLedgerService.instance.init(prefs);
    await SecurityGuard.instance.init(prefs);
    await PlayerStatsTracker.instance.init(prefs);
    await DailyTaskService.instance.init(prefs);
    await BattleAdsService.instance.init(prefs);
    await TutorialService.instance.init(prefs);
    await ProgressionService.instance.init();
    await BattleStatsService.instance.init();
    GuidePersistence.init(prefs);
    await SaveManager.instance.grantStarterLoadoutIfNeeded();

    if (Firebase.apps.isNotEmpty) {
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          await SaveManager.instance.bindUser(currentUser.uid);
          await FcmService.instance.bindUser(currentUser.uid);
          unawaited(IapService.instance.logIn(currentUser.uid));
        } else {
          final anonUser = await AuthService.instance.signInAnonymously();
          if (anonUser == null) {
            final fallbackUid = prefs.getString('colosynth_save_owner_uid') ?? 'local_guest_offline';
            await SaveManager.instance.bindUser(fallbackUid);
          }
        }
      } catch (e) {
        AppLogger.w('AppInitializer', 'Auth sign-in fallback to offline guest: $e');
        final fallbackUid = prefs.getString('colosynth_save_owner_uid') ?? 'local_guest_offline';
        await SaveManager.instance.bindUser(fallbackUid);
      }
    } else {
      final fallbackUid = prefs.getString('colosynth_save_owner_uid') ?? 'local_guest_offline';
      await SaveManager.instance.bindUser(fallbackUid);
    }

    await _reconcileStartupState(prefs);

    return AppInitializationResult(
      prefs: prefs,
      warmStart: warmStart,
    );
  }

  static Future<void> _reconcileStartupState(SharedPreferences prefs) async {
    try {
      final tProgress = Map<String, String>.from(SaveManager.instance.loadTournamentProgress());
      bool tProgressChanged = false;

      // 1. Check tutorial completion status
      final isTutorialDone =
          TutorialService.instance.isTutorialComplete || tProgress.containsKey('tutorial_2');
      if (isTutorialDone) {
        if (!TutorialService.instance.isTutorialComplete) {
          await TutorialService.instance.completeTutorial();
        }
        if (!tProgress.containsKey('tutorial_2')) {
          tProgress['tutorial_2'] = 'completed';
          tProgressChanged = true;
        }
        await ProgressionService.instance.markPermanentUnlock(UnlockableFeature.characterScreen);
      }

      // 2. Check tournament completion status and unlock features / upcoming tournaments
      final nonTutorialStagesCleared = tProgress.keys
          .where((k) => !k.startsWith('tutorial_') && !k.startsWith('tier_'))
          .length;
      if (nonTutorialStagesCleared >= 3) {
        await ProgressionService.instance.markPermanentUnlock(UnlockableFeature.upgradeTab);
      }

      // Ensure tier cleared markers are synchronized if boss is cleared to unlock upcoming tournaments
      for (int tier = 1; tier <= 10; tier++) {
        if (tProgress['t${tier}_c_boss'] != null && !tProgress.containsKey('tier_${tier}_cleared')) {
          tProgress['tier_${tier}_cleared'] = 'completed';
          tProgressChanged = true;
        }
      }

      if (tProgressChanged) {
        await SaveManager.instance.saveTournamentProgress(tProgress);
      }
    } catch (e, st) {
      AppLogger.e('AppInitializer', 'Reconcile startup state error: $e', st);
    }
  }
}

