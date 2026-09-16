import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:colosynth/utils/app_logger.dart';
import 'package:colosynth/services/iap_service.dart';
import 'package:colosynth/utils/app_config.dart';

class InterstitialAdService {
  InterstitialAdService._();
  static final InterstitialAdService instance = InterstitialAdService._();

  static final bool _useTestAd = AppConfig.env != 'production';
  static const String _testAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _realAdUnitId = 'ca-app-pub-4957092897769827/7049045145';
  static String get _adUnitId => _useTestAd ? _testAdUnitId : _realAdUnitId;

  static const int _battleThreshold = 4;
  static const String _countKey = 'interstitial_battle_count';

  InterstitialAd? _ad;
  bool _isLoaded = false;
  int _battleCount = 0;
  bool _isInitialized = false;
  bool _isShowing = false;
  bool _isPreloading = false;

  bool get _supported => !kIsWeb && Platform.isAndroid;

  Future<void> init() async {
    if (!_supported) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _battleCount = prefs.getInt(_countKey) ?? 0;
      _isInitialized = true;
      AppLogger.d('InterstitialAdService', 'Initialized with count: $_battleCount');
    } catch (e, stack) {
      AppLogger.e('InterstitialAdService', 'Init error: $e', stack);
    }
  }

  Future<void> preload() async {
    if (!_supported) return;
    if (IapService.instance.adFreeActive) return;
    if (_isPreloading || _isLoaded) return;

    _isPreloading = true;
    AppLogger.d('InterstitialAdService', 'Preloading ad...');
    try {
      await InterstitialAd.load(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            AppLogger.d('InterstitialAdService', 'Ad loaded successfully.');
            _ad = ad;
            _isLoaded = true;
            _isPreloading = false;
            _ad!.setImmersiveMode(true);
          },
          onAdFailedToLoad: (error) {
            AppLogger.d('InterstitialAdService', 'Ad failed to load: $error');
            _isLoaded = false;
            _isPreloading = false;
            _ad = null;
          },
        ),
      );
    } catch (e, stack) {
      _isPreloading = false;
      AppLogger.e('InterstitialAdService', 'Load error: $e', stack);
    }
  }

  Future<void> show() async {
    if (IapService.instance.adFreeActive) return;
    if (!_isLoaded || _ad == null || _isShowing) {
      AppLogger.d('InterstitialAdService', 'Cannot show: not loaded or already showing.');
      if (!_isShowing) unawaited(preload());
      return;
    }

    _isShowing = true;
    AppLogger.d('InterstitialAdService', 'Showing interstitial ad.');
    _ad!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        AppLogger.d('InterstitialAdService', 'Ad dismissed.');
        ad.dispose();
        _ad = null;
        _isLoaded = false;
        _isShowing = false;
        preload();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        AppLogger.d('InterstitialAdService', 'Ad failed to show: $error');
        ad.dispose();
        _ad = null;
        _isLoaded = false;
        _isShowing = false;
        preload();
      },
    );

    try {
      await _ad!.show();
    } catch (e, stack) {
      AppLogger.e('InterstitialAdService', 'Show error: $e', stack);
      _isLoaded = false;
      _isShowing = false;
      _ad = null;
      unawaited(preload());
    }
  }

  Future<void> recordBattleAndMaybeShow() async {
    if (IapService.instance.adFreeActive) return;

    if (!_isInitialized) await init();

    _battleCount++;


    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_countKey, _battleCount);
    } catch (e, stack) {
      AppLogger.e('InterstitialAdService', 'Save error: $e', stack);
    }

    AppLogger.d('InterstitialAdService', 'Battle count: $_battleCount/$_battleThreshold');

    if (_battleCount >= _battleThreshold) {


      _battleCount = 0;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_countKey, 0);
      } catch (e, stack) {
        AppLogger.e('InterstitialAdService', 'Reset save error: $e', stack);
      }

      if (isReady) {
        await show();
      } else {
        AppLogger.d('InterstitialAdService', 'Threshold reached but ad not ready. Preloading for next cycle.');
        unawaited(preload());
      }
    }
  }

  bool get isReady => _supported && !IapService.instance.adFreeActive && _isLoaded && _ad != null;
}

final interstitialAdServiceProvider =
    Provider<InterstitialAdService>((_) => InterstitialAdService.instance);

