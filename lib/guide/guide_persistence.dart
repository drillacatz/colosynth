import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight persistence layer for tracking which [GuideSequence]s
/// the player has already completed.
///
/// Uses [SharedPreferences] with a namespaced key prefix to avoid
/// collisions with other stored data. Separate from the existing
/// [TutorialService] which tracks in-battle tutorial step progress.
abstract final class GuidePersistence {
  static const _prefix = 'guide_completed_';

  static SharedPreferences? _prefs;

  /// Must be called once during app initialization (after SharedPreferences
  /// is available). Safe to call multiple times.
  static void init(SharedPreferences prefs) {
    _prefs = prefs;
  }

  /// Returns `true` if the guide with [guideId] has been marked as completed.
  static bool isCompleted(String guideId) {
    return _prefs?.getBool('$_prefix$guideId') ?? false;
  }

  /// Marks the guide with [guideId] as completed.
  static Future<void> markCompleted(String guideId) async {
    await _prefs?.setBool('$_prefix$guideId', true);
  }

  /// Resets completion status for a single guide (useful for replay / testing).
  static Future<void> reset(String guideId) async {
    await _prefs?.remove('$_prefix$guideId');
  }

  /// Resets completion status for ALL guides. Debug / testing only.
  static Future<void> resetAll() async {
    if (_prefs == null) return;
    final keys = _prefs!.getKeys().where((k) => k.startsWith(_prefix));
    for (final key in keys) {
      await _prefs!.remove(key);
    }
  }
}
