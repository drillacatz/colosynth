import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colosynth/providers/shared_preferences_provider.dart';

class NotificationSettingsState {
  final bool dailySignInEnabled;
  final bool bossAdsRefreshEnabled;

  const NotificationSettingsState({
    required this.dailySignInEnabled,
    required this.bossAdsRefreshEnabled,
  });

  NotificationSettingsState copyWith({
    bool? dailySignInEnabled,
    bool? bossAdsRefreshEnabled,
  }) {
    return NotificationSettingsState(
      dailySignInEnabled: dailySignInEnabled ?? this.dailySignInEnabled,
      bossAdsRefreshEnabled: bossAdsRefreshEnabled ?? this.bossAdsRefreshEnabled,
    );
  }
}

final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsNotifier, NotificationSettingsState>(
  NotificationSettingsNotifier.new,
);

class NotificationSettingsNotifier
    extends Notifier<NotificationSettingsState> {
  static const _kDailySignInKey = 'notif_daily_signin_enabled';
  static const _kBossAdsRefreshKey = 'notif_boss_ads_refresh_enabled';

  @override
  NotificationSettingsState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final dailySignIn = prefs.getBool(_kDailySignInKey) ?? true;
    final bossAds = prefs.getBool(_kBossAdsRefreshKey) ?? true;

    return NotificationSettingsState(
      dailySignInEnabled: dailySignIn,
      bossAdsRefreshEnabled: bossAds,
    );
  }

  Future<void> toggleDailySignIn(bool value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_kDailySignInKey, value);
    state = state.copyWith(dailySignInEnabled: value);
  }

  Future<void> toggleBossAdsRefresh(bool value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_kBossAdsRefreshKey, value);
    state = state.copyWith(bossAdsRefreshEnabled: value);
  }
}
