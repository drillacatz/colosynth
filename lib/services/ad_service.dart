import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:colosynth/utils/app_logger.dart';

/// Lightweight service that only tracks the install date for the
/// first-interstitial-show delay.  All actual interstitial ad logic
/// has been consolidated into [InterstitialAdService].
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  static const _installDateKey = 'ad_install_date_ms';

  static bool get _supported => !kIsWeb && Platform.isAndroid;

  Future<void> init() async {
    if (!_supported) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey(_installDateKey)) {
        await prefs.setInt(
            _installDateKey, DateTime.now().millisecondsSinceEpoch);
      }
    } catch (e, stack) {
      AppLogger.e('AdService', 'init error: $e', stack);
    }
  }
}

final adServiceProvider = Provider<AdService>((_) => AdService.instance);
