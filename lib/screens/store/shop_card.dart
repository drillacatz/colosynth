import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ShopCard extends StatefulWidget {
  const ShopCard({
    super.key,
    this.icon,
    this.imagePath,
    required this.mainLabel,
    required this.subLabel,
    required this.highlighted,
    required this.onTap,
    this.dimmed = false,
    this.compact = false,
    this.showRedDot = false,
    this.accentColor,
    this.badgeText,
  }) : assert(icon != null || imagePath != null, 'Must provide either an icon or imagePath');

  final IconData? icon;
  final String? imagePath;
  final String mainLabel;
  final String subLabel;
  final bool highlighted;
  final bool dimmed;
  final bool compact;
  final bool showRedDot;
  final Color? accentColor;
  final String? badgeText;
  final VoidCallback? onTap;

  @override
  State<ShopCard> createState() => _ShopCardState();
}

class _ShopCardState extends State<ShopCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.93).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveAccent =
        widget.highlighted ? Colors.white : const Color(0xFF1A1A1A);

    final Color bg = widget.highlighted
        ? const Color(0xFF1A1A1A)
        : const Color(0xFFFFFFFF);

    final Color borderCol = const Color(0xFF1A1A1A);

    final double borderWidth = widget.highlighted ? 2.2 : 1.5;

    final Color fg = widget.highlighted ? Colors.white : const Color(0xFF111111);
    final Color iconColor = widget.highlighted
        ? Colors.white
        : const Color(0xFF111111);

    final Color iconBg = widget.highlighted
        ? Colors.white.withValues(alpha: 0.15)
        : const Color(0xFFF2EFEA);

    final Color subColor = widget.highlighted
        ? const Color(0xFFCCCCCC)
        : const Color(0xFF555555);

    final double iconBoxSize = widget.compact ? 30.0 : 44.0;
    final double iconSize = widget.compact ? 16.0 : 22.0;
    final double titleSize = widget.compact ? 11.5 : 14.0;
    final double subSize = widget.compact ? 9.0 : 10.5;
    final double gap1 = widget.compact ? 4.0 : 8.0;

    return AnimatedOpacity(
      opacity: widget.dimmed ? 0.50 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: GestureDetector(
        onTapDown: widget.onTap == null
            ? null
            : (_) {
                HapticFeedback.lightImpact();
                _ctrl.animateTo(1.0);
              },
        onTapUp: widget.onTap == null
            ? null
            : (_) {
                widget.onTap?.call();
                _ctrl.animateTo(0.0);
              },
        onTapCancel: widget.onTap == null ? null : () => _ctrl.animateTo(0.0),
        child: AnimatedBuilder(
          animation: _scale,
          builder: (_, child) =>
              Transform.scale(scale: _scale.value, child: child),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: double.infinity,
                height: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: widget.compact ? 4.0 : 8.0,
                  vertical: widget.compact ? 6.0 : 10.0,
                ),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderCol, width: borderWidth),
                  boxShadow: [
                    BoxShadow(
                      color: widget.highlighted
                          ? borderCol.withValues(alpha: 0.35)
                          : Colors.black.withValues(alpha: 0.15),
                      blurRadius: widget.highlighted ? 6 : 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: iconBoxSize,
                      height: iconBoxSize,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(6),
                        border: widget.highlighted
                            ? Border.all(color: borderCol.withValues(alpha: 0.4), width: 1.0)
                            : null,
                      ),
                      child: widget.imagePath != null
                          ? Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Image.asset(
                                '${widget.imagePath}.png',
                                fit: BoxFit.contain,
                              ),
                            )
                          : Icon(widget.icon, color: iconColor, size: iconSize),
                    ),
                    SizedBox(height: gap1),
                    Text(
                      widget.mainLabel,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Bangers',
                        fontSize: titleSize,
                        color: fg,
                        letterSpacing: 1.2,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.subLabel,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: subSize,
                        color: subColor,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.badgeText != null)
                Positioned(
                  top: -5,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: effectiveAccent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF1A1A1A), width: 1.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      widget.badgeText!,
                      style: TextStyle(
                        fontFamily: 'Bangers',
                        fontSize: widget.compact ? 8.5 : 10.0,
                        color: ThemeData.estimateBrightnessForColor(effectiveAccent) == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF111111),
                        letterSpacing: 0.8,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              if (widget.showRedDot)
                Positioned(
                  top: -3,
                  right: -3,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
