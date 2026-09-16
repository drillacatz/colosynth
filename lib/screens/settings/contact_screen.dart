import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:colosynth/screens/theme/tokens.dart';
import 'package:colosynth/screens/theme/background.dart';

import 'package:colosynth/screens/overlays/locked_feature_overlay.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  static const _email = 'drillacatz@proton.me';
  static const _githubUrl = 'https://github.com/drillacatz';
  static const _steamUrl =
      'https://steamcommunity.com/profiles/76561199141875309/';

  Future<void> _launchEmail(BuildContext context) async {
    ComicButton.playButtonSfx();
    final uri = Uri(scheme: 'mailto', path: _email, queryParameters: {
      'subject': 'Colosynth Feedback',
    });
    if (!await launchUrl(uri)) {
      await Clipboard.setData(const ClipboardData(text: _email));
      if (context.mounted) {
        unawaited(LockedFeatureOverlay.show(
          context,
          customTitle: 'Email Copied',
          customDescription:
              'Could not launch email client. The address has been copied to your clipboard.',
          customConditionText: 'Copied to Clipboard',
          customEmoji: '📋',
        ));
      }
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF1A1A1A), size: 18),
        ),
        title: const Text(
          'Contact Us',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE0E0E0)),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: NotebookBackground()),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            Center(
              child: Image.asset(
                'assets/images/drillacatz_white.png',
                height: 130,
                fit: BoxFit.contain,
              ),
            ).animate().fadeIn(duration: 260.ms).slideY(begin: 0.08, end: 0),
            const SizedBox(height: 24),
            const _SectionLabel(label: 'REACH US AT'),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1A1A1A), width: 1.5),
              ),
              child: Column(
                children: [
                  _ContactTile(
                    icon: Icons.email_outlined,
                    label: 'EMAIL',
                    subtitle: _email,
                    onTap: () => _launchEmail(context),
                  ),
                  const _TileDivider(),
                  _ContactTile(
                    icon: Icons.code_rounded,
                    label: 'GITHUB',
                    subtitle: 'Check out my other works',
                    trailingIcon: Icons.open_in_new,
                    onTap: () => _launch(context, _githubUrl),
                  ),
                  const _TileDivider(),
                  _ContactTile(
                    icon: Icons.sports_esports_outlined,
                    label: 'STEAM',
                    subtitle: 'Catch me on Steam',
                    trailingIcon: Icons.open_in_new,
                    onTap: () => _launch(context, _steamUrl),
                  ),
                ],
              ),
            )
                .animate(delay: 80.ms)
                .fadeIn(duration: 260.ms)
                .slideY(begin: 0.08, end: 0),
            const SizedBox(height: 24),
            const _SectionLabel(label: 'RESPONSE TIME'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFDDDDDD), width: 1),
              ),
              child: const Row(
                children: [
                  Icon(Icons.schedule_outlined,
                      color: Color(0xFF888888), size: 18),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Typically respond within 1–2 business days',
                      style: TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 12,
                        height: 1.6,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            )
                .animate(delay: 160.ms)
                .fadeIn(duration: 260.ms)
                .slideY(begin: 0.08, end: 0),
          ],
        ),
      ),
    ],
  ),
);
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF666666),
            fontSize: 11,
            letterSpacing: 4,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Divider(color: Color(0xFFD0D0D0), thickness: 1),
        ),
      ],
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.trailingIcon = Icons.chevron_right,
  });

  final IconData icon;
  final String label;
  final String subtitle;
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 13,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF999999),
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(trailingIcon, color: const Color(0xFF888888), size: 16),
          ],
        ),
      ),
    );
  }
}

class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) => const Divider(
        color: Color(0xFFE8E8E8),
        height: 1,
        thickness: 1,
        indent: 16,
        endIndent: 16,
      );
}
