import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
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
import 'package:colosynth/services/daily_task_service.dart';

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
        if (apiKey.isEmpty) {
          throw StateError('Firebase keys are empty');
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

    if (Firebase.apps.isNotEmpty) {
      try {
        FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
        unawaited(AppLogger.flushOfflineQueue());
      } catch (e) {
        debugPrint('Crashlytics setup failed: $e');
      }
    } else {
      FlutterError.onError = (details) {
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
    await SecurityGuard.instance.init(prefs);
    await PlayerStatsTracker.instance.init(prefs);
    await DailyTaskService.instance.init(prefs);
    GuidePersistence.init(prefs);

    return AppInitializationResult(
      prefs: prefs,
      warmStart: warmStart,
    );
  }
}

