import 'package:flame/flame.dart';
import 'package:flutter/widgets.dart';

import 'package:colosynth/services/audio_service.dart';
import 'package:colosynth/utils/app_logger.dart';

/// Centralized memory management service aligned with Google Play Android memory guidelines.
///
/// Responsibilities:
/// - Bounds Flutter's raster image cache to prevent unbounded growth.
/// - Listens for OS low-memory signals via [WidgetsBindingObserver.didHaveMemoryPressure].
/// - Proactively releases raster caches when the app is placed in background to reduce
///   Android Low Memory Killer (LMK) kill rates.
/// - Trims Flame engine textures and idle secondary audio player handles.
class AppMemoryManager with WidgetsBindingObserver {
  AppMemoryManager._();

  static final AppMemoryManager instance = AppMemoryManager._();

  bool _initialized = false;

  /// Max image cache size (75 MB) to keep memory footprint lean on budget/mid-tier devices.
  static const int _kMaxImageCacheSizeBytes = 75 * 1024 * 1024;
  static const int _kMaxImageCacheCount = 100;

  /// Initializes the memory manager and hooks into the Flutter binding lifecycle.
  void init() {
    if (_initialized) return;
    _initialized = true;

    final cache = PaintingBinding.instance.imageCache;
    cache.maximumSizeBytes = _kMaxImageCacheSizeBytes;
    cache.maximumSize = _kMaxImageCacheCount;

    WidgetsBinding.instance.addObserver(this);
    AppLogger.d('AppMemoryManager', 'Initialized with bounded image cache ($_kMaxImageCacheSizeBytes bytes).');
  }

  /// Called by the operating system when the device is under memory pressure.
  @override
  void didHaveMemoryPressure() {
    AppLogger.w('AppMemoryManager', 'OS memory pressure detected. Executing emergency cache trim.');
    _flushCaches();
  }

  /// Trims non-essential caches when the application enters the background to lower
  /// the resident set size (RSS) and avoid Android 14/15/16 Low Memory Killer terminations.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    AudioService.instance.handleLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        PaintingBinding.instance.imageCache.clear();
        AudioService.instance.trimMemory();
        AppLogger.d('AppMemoryManager', 'Proactive background memory trim executed.');
        break;
      case AppLifecycleState.resumed:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  /// Flushes raster image caches, Flame textures, and secondary audio handles.
  void _flushCaches() {
    try {
      final cache = PaintingBinding.instance.imageCache;
      cache.clear();
      cache.clearLiveImages();
    } catch (e) {
      AppLogger.e('AppMemoryManager._flushCaches [imageCache]', e);
    }

    try {
      Flame.images.clearCache();
    } catch (_) {}

    try {
      AudioService.instance.trimMemory();
    } catch (_) {}
  }

  void dispose() {
    if (!_initialized) return;
    WidgetsBinding.instance.removeObserver(this);
    _initialized = false;
  }
}
