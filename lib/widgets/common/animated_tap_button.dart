import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A reusable widget that adds a smooth press scale-down animation,
/// haptic feedback, and tap callbacks to any child widget.
class AnimatedTapButton extends StatefulWidget {
  const AnimatedTapButton({
    super.key,
    required this.child,
    required this.onTap,
    this.scaleDown = 0.93,
    this.duration = const Duration(milliseconds: 100),
    this.enableHaptics = true,
    this.behavior = HitTestBehavior.opaque,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;
  final Duration duration;
  final bool enableHaptics;
  final HitTestBehavior behavior;

  @override
  State<AnimatedTapButton> createState() => _AnimatedTapButtonState();
}

class _AnimatedTapButtonState extends State<AnimatedTapButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (widget.onTap == null) return;
    if (widget.enableHaptics) {
      HapticFeedback.lightImpact();
    }
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.onTap == null) return;
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    if (widget.onTap == null) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;

    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: enabled ? _handleTapDown : null,
      onTapUp: enabled ? _handleTapUp : null,
      onTapCancel: enabled ? _handleTapCancel : null,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? widget.scaleDown : 1.0,
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
