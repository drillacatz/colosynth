import 'package:flutter/material.dart';
import 'package:colosynth/screens/theme/tokens.dart';

/// Atomic custom-painted card container replacing duplicate custom card boxes
/// across Store, Upgrade, Character, and Tournament screens.
class AppCardContainer extends StatelessWidget {
  const AppCardContainer({
    super.key,
    required this.child,
    this.style = PBStyle.dark,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.faceColorOverride,
    this.width,
    this.height,
  });

  final Widget child;
  final PBStyle style;
  final EdgeInsets padding;
  final EdgeInsets? margin;
  final Color? faceColorOverride;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final colors = PBTokens.colors[style]!;
    final faceColor = faceColorOverride ?? colors.face;

    Widget card = CustomPaint(
      painter: DoodleBorderPainter(
        faceColor: faceColor,
        inkColor: colors.ink,
        shadowColor: colors.shadow,
        style: style,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );

    if (width != null || height != null) {
      card = SizedBox(
        width: width,
        height: height,
        child: card,
      );
    }

    if (margin != null) {
      card = Padding(
        padding: margin!,
        child: card,
      );
    }

    return card;
  }
}
