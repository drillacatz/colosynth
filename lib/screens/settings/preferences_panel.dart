import 'package:flutter/material.dart';
import 'package:colosynth/screens/settings/music_screen.dart';
import 'package:colosynth/screens/settings/notifications_screen.dart';
import 'package:colosynth/screens/settings/edit_profile_screen.dart';

class GameplayPreferencesPanel extends StatelessWidget {
  const GameplayPreferencesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1A1A1A), width: 1.5),
      ),
      child: Column(
        children: [
          _NavTile(
            label: 'Music & Sound',
            icon: Icons.music_note,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const MusicScreen()),
            ),
          ),
          const _SettingsDivider(),
          _NavTile(
            label: 'Notifications',
            icon: Icons.notifications_none_outlined,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                  builder: (_) => const NotificationsScreen()),
            ),
          ),
          const _SettingsDivider(),
          _StatsTile(
            onTap: () => Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute<void>(
                fullscreenDialog: true,
                builder: (_) => const EditProfileScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF888888), size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 13,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF888888), size: 16),
          ],
        ),
      ),
    );
  }
}

class _StatsTile extends StatelessWidget {
  const _StatsTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(Icons.bar_chart_rounded, color: Color(0xFF888888), size: 18),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'PLAYER STATS',
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 13,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Color(0xFF888888), size: 16),
          ],
        ),
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) => const Divider(
        color: Color(0xFFE8E8E8),
        height: 1,
        thickness: 1,
        indent: 16,
        endIndent: 16,
      );
}
