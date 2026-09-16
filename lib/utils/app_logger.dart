import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class CachedLogEntry {
  final String tag;
  final Object error;
  final StackTrace? stack;
  final bool fatal;
  final DateTime timestamp;

  CachedLogEntry({
    required this.tag,
    required this.error,
    this.stack,
    this.fatal = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AppLogger {
  AppLogger._();

  static final List<CachedLogEntry> _offlineQueue = [];
  static const int _maxQueueSize = 100;

  static void e(String tag, Object error, [StackTrace? stack]) {
    if (kDebugMode) {
      debugPrint('[$tag] ERROR: $error');
      if (stack != null) {
        debugPrint(stack.toString());
      }
    }
    _recordOrQueue(tag: tag, error: error, stack: stack, fatal: false);
  }

  static void fatal(String tag, Object error, [StackTrace? stack]) {
    if (kDebugMode) {
      debugPrint('[$tag] FATAL: $error');
      if (stack != null) {
        debugPrint(stack.toString());
      }
    }
    _recordOrQueue(tag: tag, error: error, stack: stack, fatal: true);
  }

  static void d(String tag, String message) {
    if (kDebugMode) {
      debugPrint('[$tag] $message');
    }
  }

  static void w(String tag, String message) {
    if (kDebugMode) {
      debugPrint('[$tag] WARNING: $message');
    }
    try {
      FirebaseCrashlytics.instance.log('[$tag] WARNING: $message');
    } catch (_) {}
  }

  static void _recordOrQueue({
    required String tag,
    required Object error,
    StackTrace? stack,
    required bool fatal,
  }) {
    try {
      FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        reason: 'Tag: $tag',
        fatal: fatal,
      );
    } catch (_) {
      if (_offlineQueue.length >= _maxQueueSize) {
        _offlineQueue.removeAt(0);
      }
      _offlineQueue.add(CachedLogEntry(
        tag: tag,
        error: error,
        stack: stack,
        fatal: fatal,
      ));
    }
  }

  /// Flushes all cached offline logs to Crashlytics once online connection is established.
  static Future<void> flushOfflineQueue() async {
    if (_offlineQueue.isEmpty) return;
    final entries = List<CachedLogEntry>.from(_offlineQueue);
    _offlineQueue.clear();

    for (final entry in entries) {
      try {
        await FirebaseCrashlytics.instance.recordError(
          entry.error,
          entry.stack,
          reason: 'CachedOfflineLog [${entry.tag}] at ${entry.timestamp}',
          fatal: entry.fatal,
        );
      } catch (_) {
        _offlineQueue.add(entry);
        break;
      }
    }
  }
}

