import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:colosynth/providers/shared_preferences_provider.dart';
import 'package:colosynth/screens/home/home_screen.dart';
import 'package:colosynth/screens/splash/splash_screen.dart';
import 'package:colosynth/screens/error/initialization_error_screen.dart';
import 'package:colosynth/screens/error/error_boundary.dart';
import 'package:colosynth/services/account_sync_service.dart';
import 'package:colosynth/services/save_manager.dart';
import 'package:colosynth/services/audio_service.dart';
import 'package:colosynth/services/app_initializer.dart';
import 'package:colosynth/screens/theme/tokens.dart';
import 'package:colosynth/utils/app_logger.dart';

class RootApp extends ConsumerStatefulWidget {
  const RootApp({super.key});

  @override
  ConsumerState<RootApp> createState() => _RootAppState();
}

class _RootAppState extends ConsumerState<RootApp> {
  bool _initialized = false;
  bool _warmStart = false;
  Object? _error;
  StackTrace? _stackTrace;
  AppLifecycleListener? _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onStateChange: _handleLifecycleState,
    );
    _init();
  }

  @override
  void dispose() {
    _lifecycleListener?.dispose();
    super.dispose();
  }

  Future<void> _handleLifecycleState(AppLifecycleState state) async {
    AudioService.instance.handleLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else if (state == AppLifecycleState.paused ||
         state == AppLifecycleState.detached) {
      await SaveManager.instance.flushDebouncedWrites();
      await AccountSyncService.instance.flushNow();
    }
  }

  Future<void> _init() async {
    try {
      setState(() {
        _error = null;
        _stackTrace = null;
      });

      final prefs = ref.read(sharedPreferencesProvider);
      final result = await AppInitializer.run(prefs);

      if (!mounted) return;
      setState(() {
        _warmStart = result.warmStart;
        _initialized = true;
      });
    } catch (e, stack) {
      AppLogger.e('RootApp', 'Critical initialization error: $e', stack);
      if (!mounted) return;
      setState(() {
        _error = e;
        _stackTrace = stack;
      });

      try {
        unawaited(FirebaseCrashlytics.instance.recordError(e, stack, fatal: true));
      } catch (_) {}
    }
  }

  static final ThemeData _appTheme = _buildTheme();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Colosynth',
      debugShowCheckedModeBanner: false,
      theme: _appTheme,
      home: _buildHome(),
      onUnknownRoute: (_) => _instantRoute(const HomeScreen()),
    );
  }

  Widget _buildHome() {
    if (_error != null) {
      return InitializationErrorScreen(
        error: _error!,
        stackTrace: _stackTrace,
        onRetry: _init,
      );
    }

    if (!_initialized) {
      return const Scaffold(
        backgroundColor: AppColors.paperWhite,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.ink),
          ),
        ),
      );
    }

    return _warmStart ? const HomeScreen() : const SplashScreen();
  }

  static ThemeData _buildTheme() {
    const primaryColor = AppColors.ink;
    const secondaryColor = AppColors.charcoal;
    const paperColor = AppColors.paperWhite;
    const inkColor = AppColors.ink;
    const brightness = Brightness.light;

    return ThemeData(
      brightness: brightness,
      fontFamily: 'Bangers',
      textTheme: const TextTheme().apply(
        fontFamily: 'Bangers',
        bodyColor: inkColor,
        displayColor: inkColor,
      ),
      scaffoldBackgroundColor: paperColor,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _NoTransition(),
          TargetPlatform.iOS: _NoTransition(),
          TargetPlatform.macOS: _NoTransition(),
          TargetPlatform.linux: _NoTransition(),
          TargetPlatform.windows: _NoTransition(),
        },
      ),
      colorScheme: const ColorScheme(
        brightness: brightness,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: paperColor,
        error: Colors.red,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: inkColor,
        onError: Colors.white,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? primaryColor : Colors.grey,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primaryColor.withValues(alpha: 0.4)
              : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: inkColor),
        titleTextStyle: TextStyle(
          color: inkColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 3,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF2A1500),
        contentTextStyle: TextStyle(color: primaryColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          side: BorderSide(color: primaryColor, width: 1),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _NoTransition extends PageTransitionsBuilder {
  const _NoTransition();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      child;
}

PageRoute<T> _instantRoute<T>(Widget page) => PageRouteBuilder<T>(
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (_, __, ___) => page,
    );

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppLogger.e('FlutterError', details.exceptionAsString(), details.stack);
    try {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    } catch (_) {}
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.fatal('PlatformError', error, stack);
    try {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    } catch (_) {}
    return true;
  };

  unawaited(runZonedGuarded(() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      runApp(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const ErrorBoundary(
            child: RootApp(),
          ),
        ),
      );
    } catch (e, stack) {
      AppLogger.fatal('RunAppError', e, stack);
      try {
        await FirebaseCrashlytics.instance.recordError(e, stack, fatal: true);
      } catch (_) {}
      runApp(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: InitializationErrorScreen(
            error: e,
            stackTrace: stack,
            onRetry: () => main(),
          ),
        ),
      );
    }
  }, (error, stack) {
    AppLogger.fatal('UncaughtAsync', error, stack);
    try {
      unawaited(FirebaseCrashlytics.instance.recordError(error, stack, fatal: true));
    } catch (_) {}
  }));
}

