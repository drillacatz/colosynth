import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:colosynth/database/synth/synth_definition.dart';
import 'package:colosynth/screens/synth/synth_holo_card.dart';
import 'package:colosynth/screens/theme/tokens.dart';

/// Dedicated full-screen modal showcase overlay for inspecting 3D holographic Synth cards.
///
/// Inspired by Pokebox:
/// - Frosted dark scrim backdrop.
/// - Centered 3D holographic card with touch drag and gyroscope motion.
/// - Manga comic header and close controls.
class SynthCardShowcaseOverlay extends StatelessWidget {
  const SynthCardShowcaseOverlay({
    super.key,
    required this.definition,
    this.level = 1,
  });

  final SynthDefinition definition;
  final int level;

  static Future<void> show(
    BuildContext context, {
    required SynthDefinition definition,
    int level = 1,
  }) {
    HapticFeedback.lightImpact();
    return Navigator.of(context, rootNavigator: true).push<void>(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.75),
        fullscreenDialog: true,
        pageBuilder: (ctx, anim, secAnim) => SynthCardShowcaseOverlay(
          definition: definition,
          level: level,
        ),
        transitionsBuilder: (ctx, anim, secAnim, child) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.88, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 280),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final cardHeight = (size.height * 0.62).clamp(360.0, 480.0);
    final cardWidth = cardHeight * 0.66; // Standard 2.5:3.5 TCG ratio

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Frosted Glass Scrim
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(color: Colors.black.withValues(alpha: 0.65)),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Close Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.paperWhite,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.ink, width: 2),
                          boxShadow: const [
                            BoxShadow(color: Colors.black54, offset: Offset(2, 2)),
                          ],
                        ),
                        child: const Icon(
                          Icons.close,
                          color: AppColors.ink,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Center Floating 3D Card
                Center(
                  child: SynthHoloCard(
                    definition: definition,
                    level: level,
                    width: cardWidth,
                    height: cardHeight,
                    isInteractive: true,
                  ),
                ),

                const Spacer(),

                // Bottom Hint Pill
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161522).withValues(alpha: 0.90),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24, width: 1.2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 10),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.touch_app_outlined,
                          color: AppColors.comicYellow,
                          size: 15,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'DRAG OR TILT DEVICE TO VIEW HOLOGRAPHIC FOIL',
                          style: TextStyle(
                            fontFamily: 'Bangers',
                            fontSize: 12,
                            letterSpacing: 1.2,
                            color: Colors.white70,
                          ),
                        ),
                      ],
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
