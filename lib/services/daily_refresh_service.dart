import 'dart:async';
import 'package:flutter/widgets.dart';

class DailyRefreshService extends WidgetsBindingObserver {
  DailyRefreshService._();
  static final DailyRefreshService instance = DailyRefreshService._();

  final List<VoidCallback> _callbacks = [];
  Timer? _midnightTimer;
  String _lastCheckedDate = _todayKey();

  static String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  void init() {
    WidgetsBinding.instance.addObserver(this);
    _scheduleMidnightTimer();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightTimer?.cancel();
  }

  void addCallback(VoidCallback callback) {
    if (!_callbacks.contains(callback)) {
      _callbacks.add(callback);
    }
  }

  void removeCallback(VoidCallback callback) {
    _callbacks.remove(callback);
  }

  void _scheduleMidnightTimer() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final duration = nextMidnight.difference(now);
    
    _midnightTimer = Timer(duration, () {
      _checkAndTrigger();
      _scheduleMidnightTimer();
    });
  }

  void _checkAndTrigger() {
    final today = _todayKey();
    if (_lastCheckedDate != today) {
      _lastCheckedDate = today;
      for (final callback in _callbacks) {
        try {
          callback();
        } catch (_) {}
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndTrigger();
      _scheduleMidnightTimer();
    }
  }
}
