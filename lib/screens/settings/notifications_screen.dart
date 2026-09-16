import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colosynth/providers/notification_providers.dart';
import 'package:colosynth/screens/theme/tokens.dart';
import 'package:colosynth/screens/theme/background.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider);
    final notifier = ref.read(notificationSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontFamily: 'Bangers',
            fontSize: 20,
            letterSpacing: 1.5,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFF1A1A1A), height: 1.5),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: NotebookBackground()),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                'GAME ALERTS & REMINDERS',
                style: TextStyle(
                  fontFamily: 'Bangers',
                  fontSize: 16,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1A1A1A), width: 1.5),
              ),
              child: Column(
                children: [
                  _NotificationSwitchTile(
                    title: 'DAILY SIGN-IN REMINDER',
                    subtitle:
                        'Receive daily alerts when your daily check-in rewards are ready to claim.',
                    icon: Icons.calendar_today_rounded,
                    iconColor: AppColors.comicYellow,
                    value: settings.dailySignInEnabled,
                    onChanged: (val) => notifier.toggleDailySignIn(val),
                  ),
                  const Divider(
                      color: Color(0xFFE8E8E8), height: 1, thickness: 1),
                  _NotificationSwitchTile(
                    title: 'BOSS DAILY REWARDED ADS REFRESH',
                    subtitle:
                        'Get notified when daily boss battle double-rewards and free ad boosts reset.',
                    icon: Icons.card_giftcard_rounded,
                    iconColor: AppColors.comicRed,
                    value: settings.bossAdsRefreshEnabled,
                    onChanged: (val) => notifier.toggleBossAdsRefresh(val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Notifications can also be managed anytime from your device system settings.',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  ),
);
  }
}

class _NotificationSwitchTile extends StatelessWidget {
  const _NotificationSwitchTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: iconColor.withValues(alpha: 0.5)),
            ),
            child: Icon(icon, color: const Color(0xFF1A1A1A), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Bangers',
                    fontSize: 14,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF666666),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            activeThumbColor: const Color(0xFF00E5FF),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
