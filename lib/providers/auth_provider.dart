import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:colosynth/providers/service_providers.dart';
import 'package:colosynth/providers/shared_preferences_provider.dart';
import 'package:colosynth/services/sp_manager.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).userStream;
});

final isGuestProvider = Provider<bool>((ref) {
  final user = ref.watch(authStateProvider).value;
  return user?.isAnonymous ?? true;
});

/// The display name shown in the UI. Priority:
/// 1. Custom display name override stored in SharedPreferences
/// 2. Google display name (from Firebase Auth)
/// 3. Email (without domain)
/// 4. 'Guest'
final displayNameProvider = Provider<String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final custom = prefs.getString(SPKeys.customDisplayName);
  if (custom != null && custom.trim().isNotEmpty) return custom.trim();
  final user = ref.watch(authStateProvider).value;
  if (user == null || user.isAnonymous) return 'Guest';
  return user.displayName ?? user.email?.split('@').first ?? 'Player';
});

/// Notifier that lets screens trigger a refresh of displayNameProvider
/// after saving a new custom name to SharedPreferences.
final displayNameRefreshProvider = NotifierProvider<_DisplayNameRefreshNotifier, int>(_DisplayNameRefreshNotifier.new);

class _DisplayNameRefreshNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void refresh() => state++;
}
