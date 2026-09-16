import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:colosynth/utils/app_logger.dart';
import 'package:colosynth/utils/app_config.dart';

class RewardedAdService {
  RewardedAdService._();
  static final RewardedAdService instance = RewardedAdService._();

  static final bool _useTestAd = AppConfig.env != 'production';

  static const String _testAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const String _realAdUnitId = 'ca-app-pub-4957092897769827/4804230570';

  static String get _adUnitId => _useTestAd ? _testAdUnitId : _realAdUnitId;

  RewardedAd? _rewardedAd;
  bool _isLoading = false;
  bool _adShowing = false;

  static bool get _supported => !kIsWeb && Platform.isAndroid;

  bool get isReady => _supported && _rewardedAd != null;
  bool get isLoading => _isLoading;

  Future<void> preload() async {
    if (!_supported) return;
    if (_isLoading || _rewardedAd != null) return;

    _isLoading = true;
    AppLogger.d('RewardedAdService', 'Preloading rewarded ad...');

    try {
      await RewardedAd.load(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            AppLogger.d('RewardedAdService', 'Ad loaded successfully.');
            _rewardedAd = ad;
            _isLoading = false;
          },
          onAdFailedToLoad: (LoadAdError error) {
            _isLoading = false;
            _rewardedAd = null;
            AppLogger.e('RewardedAdService', 'load failed — $error');
          },
        ),
      );
    } catch (e, stack) {
      _isLoading = false;
      AppLogger.e('RewardedAdService', 'preload exception: $e', stack);
    }
  }

  Future<bool> showAd({
    required VoidCallback onRewarded,
    VoidCallback? onDismissed,
  }) async {
    if (!_supported) return false;
    if (_rewardedAd == null || _adShowing) {
      if (!_adShowing) unawaited(preload());
      return false;
    }
    _adShowing = true;
    AppLogger.d('RewardedAdService', 'Showing rewarded ad.');

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        AppLogger.d('RewardedAdService', 'Ad dismissed.');
        ad.dispose();
        _rewardedAd = null;
        _adShowing = false;
        onDismissed?.call();
        unawaited(preload());
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        ad.dispose();
        _rewardedAd = null;
        _adShowing = false;
        AppLogger.e('RewardedAdService', 'show failed — $error');
        onDismissed?.call();
        unawaited(preload());
      },
    );

    try {
      await _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView _, RewardItem reward) {
          onRewarded();
        },
      );
      return true;
    } catch (e, stack) {
      AppLogger.e('RewardedAdService', 'show exception: $e', stack);
      unawaited(_rewardedAd?.dispose() ?? Future.value());
      _rewardedAd = null;
      _adShowing = false;
      onDismissed?.call();
      unawaited(preload());
      return false;
    }
  }

  void disposeAd() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }

  void dispose() {
    disposeAd();
  }
}

final rewardedAdServiceProvider =
    Provider<RewardedAdService>((_) => RewardedAdService.instance);
