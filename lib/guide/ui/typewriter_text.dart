import 'package:flutter/material.dart';

/// A widget that prints text character-by-character to simulate speech.
///
/// Refactored from the old story module:
/// - **AnimationController** replaces `Timer.periodic` for proper lifecycle.
/// - **Generic [onCompleted] callback** replaces direct `storyStateProvider`
///   mutation — the widget no longer knows about state management.
/// - Supports external fast-forward via [showAll] parameter.
class TypewriterText extends StatefulWidget {
  /// The full string text to type out.
  final String text;

  /// Speed of typewriter in milliseconds per character.
  final int msPerChar;

  /// Called once when all characters have been revealed.
  final VoidCallback? onCompleted;

  /// When set to `true` externally, instantly reveals all text.
  /// Useful for "tap to skip typing" interactions.
  final bool showAll;

  const TypewriterText({
    super.key,
    required this.text,
    this.msPerChar = 30,
    this.onCompleted,
    this.showAll = false,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _charCountAnimation;
  bool _hasNotifiedCompletion = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _charCountAnimation = const AlwaysStoppedAnimation(0);
    _setupAnimation();
  }

  @override
  void didUpdateWidget(TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.text != widget.text) {
      _hasNotifiedCompletion = false;
      _setupAnimation();
      return;
    }

    if (widget.showAll && !oldWidget.showAll) {
      _fastForward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setupAnimation() {
    _controller
      ..stop()
      ..removeStatusListener(_onAnimationStatus);

    final charCount = widget.text.length;
    if (charCount == 0) {
      _notifyCompleted();
      return;
    }

    final totalDuration = Duration(milliseconds: widget.msPerChar * charCount);
    _controller.duration = totalDuration;

    _charCountAnimation = StepTween(
      begin: 0,
      end: charCount,
    ).animate(_controller);

    _controller.addStatusListener(_onAnimationStatus);

    if (widget.showAll) {
      _fastForward();
    } else {
      _controller.forward(from: 0);
    }
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _notifyCompleted();
    }
  }

  void _fastForward() {
    _controller.value = 1.0;
    _notifyCompleted();
  }

  void _notifyCompleted() {
    if (!_hasNotifiedCompletion) {
      _hasNotifiedCompletion = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onCompleted?.call();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final int visibleCount;
        if (widget.showAll) {
          visibleCount = widget.text.length;
        } else if (_charCountAnimation is AlwaysStoppedAnimation) {
          visibleCount = 0;
        } else {
          visibleCount = _charCountAnimation.value;
        }

        final displayText = widget.text.substring(
          0,
          visibleCount.clamp(0, widget.text.length),
        );

        return Text(
          displayText,
          style: const TextStyle(
            fontSize: 16.5,
            color: Color(0xFF1E1100),
            height: 1.45,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        );
      },
    );
  }
}
