import 'package:flutter/material.dart';
import 'package:colosynth/screens/theme/tokens.dart';

enum ResourceType { ink, paint, synthKey, stamina }

/// Centralized currency and resource badge for displaying Ink, Paint, Synth Keys, and Stamina.
class AppResourceBadge extends StatelessWidget {
  const AppResourceBadge({
    super.key,
    required this.type,
    required this.amount,
    this.fontSize = 14,
    this.iconSize = 18,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  });

  final ResourceType type;
  final int amount;
  final double fontSize;
  final double iconSize;
  final EdgeInsets padding;

  IconData get _icon {
    switch (type) {
      case ResourceType.ink:
        return Icons.water_drop_rounded;
      case ResourceType.paint:
        return Icons.palette_rounded;
      case ResourceType.synthKey:
        return Icons.vpn_key_rounded;
      case ResourceType.stamina:
        return Icons.bolt_rounded;
    }
  }

  Color get _color {
    switch (type) {
      case ResourceType.ink:
        return AppColors.comicBlue;
      case ResourceType.paint:
        return AppColors.comicYellow;
      case ResourceType.synthKey:
        return AppColors.comicRed;
      case ResourceType.stamina:
        return AppColors.comicGreen;
    }
  }

  String get _label {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 10000) {
      return '${(amount / 1000).toStringAsFixed(1)}k';
    }
    return '$amount';
  }

  @override
  Widget build(BuildContext context) {
    final themeInk = AppColors.ink;
    final color = _color;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.paperWhite,
        borderRadius: BorderRadius.circular(PBTokens.chamfer),
        border: Border.all(color: themeInk, width: PBTokens.borderWidth),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF000000),
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: iconSize, color: color),
          const SizedBox(width: 6),
          Text(
            _label,
            style: TextStyle(
              fontFamily: 'Bangers',
              fontSize: fontSize,
              color: themeInk,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
