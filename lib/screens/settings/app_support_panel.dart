import 'dart:async';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:colosynth/screens/theme/tokens.dart';
import 'package:colosynth/screens/feedback/feedback_faq_screen.dart';
import 'package:colosynth/screens/settings/contact_screen.dart';
import 'package:colosynth/screens/settings/devlog_screen.dart';

class AppSupportPanel extends StatelessWidget {
  const AppSupportPanel({super.key});

  static const _storeId = 'com.drillacatz.colosynth';
  static const _shareText =
      'Play ColoSynth — action combat with comic-book style! '
      'https://play.google.com/store/apps/details?id=$_storeId';

  void _openFeedback(BuildContext context) {
    ComicButton.playButtonSfx();
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const FeedbackFaqScreen()),
    );
  }

  void _openContact(BuildContext context) {
    ComicButton.playButtonSfx();
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const ContactScreen()),
    );
  }

  void _openDevlog(BuildContext context) {
    ComicButton.playButtonSfx();
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const DevlogScreen()),
    );
  }

  Future<void> _shareApp() async {
    ComicButton.playButtonSfx();
    await SharePlus.instance.share(ShareParams(text: _shareText));
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

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _SupportSquareButton(
          icon: Icons.chat_bubble_outline,
          tooltip: 'Feedback & FAQ',
          onTap: () => _openFeedback(context),
        ),
        _SupportSquareButton(
          icon: Icons.mail_outline,
          tooltip: 'Contact Us',
          onTap: () => _openContact(context),
        ),
        _SupportSquareButton(
          icon: Icons.auto_stories_outlined,
          tooltip: 'Devlog & Versions',
          onTap: () => _openDevlog(context),
        ),
        _SupportSquareButton(
          icon: Icons.share_outlined,
          tooltip: 'Share App',
          onTap: _shareApp,
        ),
        _SupportSquareButton(
          icon: Icons.star_outline,
          tooltip: 'Rate App',
          onTap: _rateApp,
        ),
      ],
    );
  }
}

class _SupportSquareButton extends StatefulWidget {
  const _SupportSquareButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_SupportSquareButton> createState() => _SupportSquareButtonState();
}

class _SupportSquareButtonState extends State<_SupportSquareButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 52,
          height: 52,
          transform: _pressed
              ? Matrix4.translationValues(2, 2, 0)
              : Matrix4.translationValues(0, 0, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF1A1A1A), width: 2),
            boxShadow: _pressed
                ? const []
                : const [
                    BoxShadow(
                      color: Color(0xFF1A1A1A),
                      offset: Offset(3, 3),
                    ),
                  ],
          ),
          child: Center(
            child: Icon(
              widget.icon,
              color: const Color(0xFF1A1A1A),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
