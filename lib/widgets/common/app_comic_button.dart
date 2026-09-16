import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:colosynth/screens/theme/tokens.dart';
import 'package:colosynth/services/audio_service.dart';
import 'package:colosynth/game_settings.dart';

enum AppButtonStyle { dark, white, accent }

/// Universal atomic comic button component with custom spring physics,
/// press squeeze animations, haptic feedback, and audio integration.
class AppComicButton extends StatefulWidget {
  const AppComicButton({
    super.key,
    required this.label,
    required this.onTap,
    this.style = AppButtonStyle.dark,
    this.fontSize = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    this.leading,
    this.trailing,
    this.width,
    this.height,
  });

  final String label;
  final VoidCallback? onTap;
  final AppButtonStyle style;
  final double fontSize;
  final EdgeInsets padding;
  final Widget? leading;
  final Widget? trailing;
  final double? width;
  final double? height;

  static void playButtonSfx() {
    AudioService.instance.playSfx(SfxEvent.button);
  }

  @override
  State<AppComicButton> createState() => _AppComicButtonState();
}

class _AppComicButtonState extends State<AppComicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;

  static const _spring = SpringDescription(
    mass: 1.0,
    stiffness: 700.0,
    damping: 38.0,
  );

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      lowerBound: 0.0,
      upperBound: 1.0,
      duration: PBTokens.squeezeDuration,
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: PBTokens.pressScale,
    ).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _isDisabled => widget.onTap == null;

  PBStyle get _pbStyle {
    switch (widget.style) {
      case AppButtonStyle.dark:
      case AppButtonStyle.accent:
        return PBStyle.dark;
      case AppButtonStyle.white:
        return PBStyle.white;
    }
  }

  void _onTapDown(TapDownDetails _) {
    if (_isDisabled) return;
    HapticFeedback.lightImpact();
    AudioService.instance.playSfx(SfxEvent.button);
    _ctrl.animateTo(1.0,
        duration: PBTokens.squeezeDuration, curve: Curves.easeIn);
  }

  void _onTapUp(TapUpDetails _) {
    if (_isDisabled) return;
    widget.onTap?.call();
    _springBack();
  }

  void _onTapCancel() => _springBack();

  void _springBack() {
    _ctrl.animateWith(SpringSimulation(_spring, _ctrl.value, 0.0, -3.0));
  }

  @override
  Widget build(BuildContext context) {
    final pbStyle = _pbStyle;
    final colors = PBTokens.colors[pbStyle]!;

    final faceColor = widget.style == AppButtonStyle.accent
        ? AppColors.comicYellow
        : colors.face;
    final textColor = widget.style == AppButtonStyle.accent
        ? const Color(0xFF1A0E00)
        : colors.text;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnim.value,
            child: Opacity(
              opacity: _isDisabled ? 0.5 : 1.0,
              child: SizedBox(
                width: widget.width,
                height: widget.height,
                child: CustomPaint(
                  painter: DoodleBorderPainter(
                    faceColor: faceColor,
                    inkColor: colors.ink,
                    shadowColor: colors.shadow,
                    style: pbStyle,
                  ),
                  child: Padding(
                    padding: widget.padding,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.leading != null) ...[
                          widget.leading!,
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.label,
                          style: TextStyle(
                            fontFamily: 'Bangers',
                            fontSize: widget.fontSize,
                            color: textColor,
                            letterSpacing: 2,
                          ),
                        ),
                        if (widget.trailing != null) ...[
                          const SizedBox(width: 8),
                          widget.trailing!,
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
