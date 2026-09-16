import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:colosynth/screens/settings/profile_panel.dart';
import 'package:colosynth/screens/settings/preferences_panel.dart';
import 'package:colosynth/screens/settings/app_support_panel.dart';
import 'package:colosynth/screens/theme/tokens.dart';
import 'package:colosynth/screens/theme/background.dart';
import 'package:colosynth/screens/overlays/locked_feature_overlay.dart';

class SettingsOverlay extends ConsumerStatefulWidget {
  const SettingsOverlay({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => const SettingsOverlay(),
    );
  }

  @override
  ConsumerState<SettingsOverlay> createState() => _SettingsOverlayState();
}

typedef SettingsScreen = SettingsOverlay;

class _SettingsOverlayState extends ConsumerState<SettingsOverlay> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final maxHeight = size.height * 0.85;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 440,
          maxHeight: maxHeight,
        ),
        decoration: BoxDecoration(
          color: AppColors.paperWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.ink, width: 3.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.4),
              blurRadius: 0,
              offset: const Offset(6, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              const Positioned.fill(child: NotebookBackground()),
              _GearDecoration(),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DialogHeader(
                    onClose: () {
                      ComicButton.playButtonSfx();
                      Navigator.of(context).pop();
                    },
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _SectionHeader(label: 'PROFILE', icon: Icons.person)
                              .animate(delay: 30.ms)
                              .fadeIn(duration: 140.ms)
                              .slideX(
                                begin: 0.1,
                                end: 0,
                                duration: 200.ms,
                                curve: Curves.easeOutCubic,
                              ),
                          const SizedBox(height: 8),
                          const ProfilePanel()
                              .animate(delay: 60.ms)
                              .fadeIn(duration: 140.ms)
                              .slideX(
                                begin: 0.1,
                                end: 0,
                                duration: 200.ms,
                                curve: Curves.easeOutCubic,
                              ),
                          const SizedBox(height: 18),
                          const _SectionHeader(
                                  label: 'GAMEPLAY PREFERENCES', icon: Icons.settings)
                              .animate(delay: 110.ms)
                              .fadeIn(duration: 140.ms)
                              .slideX(
                                begin: 0.1,
                                end: 0,
                                duration: 200.ms,
                                curve: Curves.easeOutCubic,
                              ),
                          const SizedBox(height: 8),
                          const GameplayPreferencesPanel()
                              .animate(delay: 140.ms)
                              .fadeIn(duration: 140.ms)
                              .slideX(
                                begin: 0.1,
                                end: 0,
                                duration: 200.ms,
                                curve: Curves.easeOutCubic,
                              ),
                          const SizedBox(height: 18),
                          const _SectionHeader(
                                  label: 'APP SUPPORT', icon: Icons.help_outline)
                              .animate(delay: 190.ms)
                              .fadeIn(duration: 140.ms)
                              .slideX(
                                begin: 0.1,
                                end: 0,
                                duration: 200.ms,
                                curve: Curves.easeOutCubic,
                              ),
                          const SizedBox(height: 10),
                          const AppSupportPanel()
                              .animate(delay: 220.ms)
                              .fadeIn(duration: 140.ms)
                              .slideX(
                                begin: 0.1,
                                end: 0,
                                duration: 200.ms,
                                curve: Curves.easeOutCubic,
                              ),
                          const SizedBox(height: 20),
                          const _AboutFooter()
                              .animate(delay: 280.ms)
                              .fadeIn(duration: 160.ms),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.paperWhite,
        border: Border(
          bottom: BorderSide(color: AppColors.ink, width: 2),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.settings, color: AppColors.ink, size: 20),
          const SizedBox(width: 8),
          const Text(
            'SETTINGS',
            style: TextStyle(
              color: AppColors.ink,
              fontFamily: 'Bangers',
              fontSize: 20,
              letterSpacing: 2.5,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.ink, width: 1.8),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.ink,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.close, color: AppColors.ink, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GearDecoration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -28,
      right: -38,
      child: IgnorePointer(
        child: RepaintBoundary(
          child: SizedBox(
            width: 210,
            height: 210,
            child: CustomPaint(
              painter: _GearPainter(
                color: const Color(0xFF1A1A1A).withValues(alpha: 0.065),
                teeth: 14,
              ),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .rotate(begin: 0, end: 1, duration: 50.seconds)
              .animate()
              .rotate(
                begin: 0,
                end: 1.5,
                duration: 1200.ms,
                curve: Curves.easeOutCubic,
              )
              .fadeIn(
                duration: 400.ms,
                curve: Curves.easeOut,
              )
              .scale(
                begin: const Offset(0.55, 0.55),
                end: const Offset(1.0, 1.0),
                duration: 900.ms,
                curve: Curves.easeOutBack,
              ),
        ),
      ),
    );
  }
}

class _GearPainter extends CustomPainter {
  const _GearPainter({required this.color, this.teeth = 12});

  final Color color;
  final int teeth;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = math.min(size.width, size.height) / 2;
    final innerR = outerR * 0.70;
    final holeR = outerR * 0.26;
    final halfTooth = math.pi / teeth * 0.44;
    final gap = math.pi / teeth * 0.13;

    final path = Path()..fillType = PathFillType.evenOdd;
    for (int i = 0; i < teeth; i++) {
      final base = (math.pi * 2 * i) / teeth;
      final a1 = base - halfTooth;
      final a2 = base + halfTooth;
      final a3 = base + halfTooth + gap;
      final a4 = base + math.pi * 2 / teeth - halfTooth - gap;

      if (i == 0) {
        path.moveTo(
          cx + innerR * math.cos(a1),
          cy + innerR * math.sin(a1),
        );
      } else {
        path.lineTo(
          cx + innerR * math.cos(a1),
          cy + innerR * math.sin(a1),
        );
      }
      path.lineTo(cx + outerR * math.cos(a1), cy + outerR * math.sin(a1));
      path.lineTo(cx + outerR * math.cos(a2), cy + outerR * math.sin(a2));
      path.lineTo(cx + innerR * math.cos(a3), cy + innerR * math.sin(a3));
      path.lineTo(cx + innerR * math.cos(a4), cy + innerR * math.sin(a4));
    }
    path.close();

    path.addOval(
      Rect.fromCircle(center: Offset(cx, cy), radius: holeR),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: color.a * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(_GearPainter old) =>
      old.color != color || old.teeth != teeth;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF1A1A1A), size: 16),
        const SizedBox(width: 8),
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

class _AboutFooter extends StatelessWidget {
  const _AboutFooter();

  static const _termsUrl =
      'https://sites.google.com/view/terms-of-colosynth/%E9%A6%96%E9%A1%B5';
  static const _privacyUrl =
      'https://sites.google.com/view/privacy-policy-of-colosynth/%E9%A6%96%E9%A1%B5';

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
    return Column(
      children: [
        const Text(
          'COLOSYNTH',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'v0.5.3 (3)',
          style: TextStyle(
            color: Color(0xFF888888),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => _launch(context, _termsUrl),
              child: const Text(
                'TERMS OF SERVICE',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '|',
                style: TextStyle(
                  color: Color(0xFFCCCCCC),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _launch(context, _privacyUrl),
              child: const Text(
                'PRIVACY POLICY',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          '© DRILLACATZ 2026',
          style: TextStyle(
            color: Color(0xFFAAAAAA),
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
