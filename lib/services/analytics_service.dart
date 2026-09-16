import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  FirebaseAnalytics? _analytics;

  Future<void> init() async {
    try {
      _analytics = FirebaseAnalytics.instance;
    } catch (e) {
      debugPrint('AnalyticsService init error: $e');
    }
  }

  Future<void> _log(String name, {Map<String, Object>? params}) async {
    try {
      await _analytics?.logEvent(name: name, parameters: params);
    } catch (e) {
      debugPrint('AnalyticsService logEvent error: $e');
    }
  }

  Future<void> logTabChanged(String tabName) =>
      _log('tab_changed', params: {'tab': tabName});

  Future<void> logPurchaseInitiated(String productId) =>
      _log('purchase_initiated', params: {'product_id': productId});

  Future<void> setUserId(String id) async {
    try {
      await _analytics?.setUserId(id: id);
    } catch (e) {
      debugPrint('AnalyticsService setUserId error: $e');
    }
  }
}

final analyticsServiceProvider =
    Provider<AnalyticsService>((_) => AnalyticsService.instance);
