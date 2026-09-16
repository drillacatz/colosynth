import 'package:flutter/material.dart';
import 'package:colosynth/screens/theme/tokens.dart';

class MiniStarRow extends StatelessWidget {
  const MiniStarRow({
    super.key,
    required this.stars,
    this.size = 26,
    this.spacing = 3,
  });

  final int stars;
  final double size;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final earned = i < stars;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing),
          child: Icon(
            earned ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: earned ? AppColors.comicYellow : const Color(0xFFCCCCCC),
          ),
        );
      }),
    );
  }
}

class RewardRow extends StatelessWidget {
  const RewardRow({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.valueColor = const Color(0xFF1A0E00),
    this.labelWidth = 64,
    this.valueFontSize = 22,
  });

  final IconData icon;
  final Color color;
  final String label;
  final int value;
  final Color valueColor;
  final double labelWidth;
  final double valueFontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        SizedBox(
          width: labelWidth,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Bangers',
              color: color,
              fontSize: 16,
              letterSpacing: 2,
            ),
          ),
        ),
        Text(
          '+$value',
          style: TextStyle(
            fontFamily: 'Bangers',
            color: valueColor,
            fontSize: valueFontSize,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
