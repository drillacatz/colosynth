import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:colosynth/screens/theme/tokens.dart';
import 'package:colosynth/screens/settings/devlog_screen.dart';
import 'package:colosynth/screens/settings/contact_screen.dart';

import 'package:colosynth/screens/overlays/locked_feature_overlay.dart';

class AboutPanel extends StatelessWidget {
  const AboutPanel({super.key});

  static const _termsUrl =
      'https://sites.google.com/view/terms-of-colosynth/%E9%A6%96%E9%A1%B5';
  static const _privacyUrl =
      'https://sites.google.com/view/privacy-policy-of-colosynth/%E9%A6%96%E9%A1%B5';
  static const _storeId = 'com.drillacatz.colosynth';

  Future<void> _launch(BuildContext context, String url) async {
    ComicButton.playButtonSfx();
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        unawaited(LockedFeatureOverlay.show(
          context,
          customTitle: 'Link Failed',
          customDescription: 'Could not open the link.',
          customConditionText: 'Failed to Open',
          customEmoji: '❌',
        ));
      }
    }
  }

  Future<void> _rateApp() async {
    ComicButton.playButtonSfx();
    final marketUri = Uri.parse('market://details?id=$_storeId');
    if (!await launchUrl(marketUri, mode: LaunchMode.externalApplication)) {
      await launchUrl(
        Uri.parse('https://play.google.com/store/apps/details?id=$_storeId'),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  void _openDevlog(BuildContext context) {
    ComicButton.playButtonSfx();
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const DevlogScreen()),
    );
  }

  void _openContact(BuildContext context) {
    ComicButton.playButtonSfx();
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const ContactScreen()),
    );
  }

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
          _AboutTile(
            icon: Icons.auto_stories_outlined,
            label: 'DEVLOG & VERSION HISTORY',
            trailingIcon: Icons.chevron_right,
            onTap: () => _openDevlog(context),
          ),
          const _Divider(),
          _AboutTile(
            icon: Icons.mail_outline,
            label: 'CONTACT US',
            trailingIcon: Icons.chevron_right,
            onTap: () => _openContact(context),
          ),
          const _Divider(),
          _AboutTile(
            icon: Icons.star_outline,
            label: 'RATE THE APP',
            trailingIcon: Icons.open_in_new,
            onTap: _rateApp,
          ),
          const _Divider(),
          _AboutTile(
            icon: Icons.article_outlined,
            label: 'TERMS OF SERVICE',
            trailingIcon: Icons.open_in_new,
            onTap: () => _launch(context, _termsUrl),
          ),
          const _Divider(),
          _AboutTile(
            icon: Icons.privacy_tip_outlined,
            label: 'PRIVACY POLICY',
            trailingIcon: Icons.open_in_new,
            onTap: () => _launch(context, _privacyUrl),
          ),
        ],
      ),
    );
  }
}

class _AboutTile extends StatelessWidget {
  const _AboutTile({
    required this.icon,
    required this.label,
    required this.trailingIcon,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final IconData trailingIcon;
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
            Icon(trailingIcon, color: const Color(0xFF888888), size: 16),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => const Divider(
        color: Color(0xFFE8E8E8),
        height: 1,
        thickness: 1,
        indent: 16,
        endIndent: 16,
      );
}
