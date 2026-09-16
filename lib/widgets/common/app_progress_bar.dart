import 'package:flutter/material.dart';
import 'package:colosynth/screens/theme/tokens.dart';

/// Atomic custom-painted animated progress bar for HP, Stamina, EXP, and Skill meters.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.progress,
    this.height = 16.0,
    this.fillColor = AppColors.comicYellow,
    this.backgroundColor = const Color(0xFF222222),
    this.borderColor = const Color(0xFF111111),
    this.showPercentage = false,
    this.label,
  });

  /// Progress value between 0.0 and 1.0.
  final double progress;
  final double height;
  final Color fillColor;
  final Color backgroundColor;
  final Color borderColor;
  final bool showPercentage;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null || showPercentage)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (label != null)
                  Text(
                    label!,
                    style: const TextStyle(
                      fontFamily: 'Bangers',
                      fontSize: 14,
                      color: AppColors.ink,
                      letterSpacing: 1.2,
                    ),
                  ),
                if (showPercentage)
                  Text(
                    '${(clampedProgress * 100).toInt()}%',
                    style: const TextStyle(
                      fontFamily: 'Bangers',
                      fontSize: 14,
                      color: AppColors.ink,
                      letterSpacing: 1,
                    ),
                  ),
              ],
            ),
          ),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(height / 2),
            border: Border.all(color: borderColor, width: PBTokens.borderWidth),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                offset: Offset(0, 2),
                blurRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular((height / 2) - 1),
            child: Stack(
              children: [
                FractionallySizedBox(
                  widthFactor: clampedProgress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: fillColor,
                      gradient: LinearGradient(
                        colors: [
                          fillColor,
                          fillColor.withValues(alpha: 0.85),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
