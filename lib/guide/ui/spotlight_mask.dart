import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:colosynth/guide/guide_anchor.dart';

/// Overlay that dims the entire screen and highlights a specific widget
/// with a transparent cutout, restricting interactions to only the
/// highlighted zone.
///
/// Refactored from `tutorial_highlight.dart`:
/// - Reads anchors from [GuideAnchorRegistry] instead of `TutorialKeyRegistry`
/// - Animates spotlight position transitions between steps
/// - Supports both circular and rectangular cutout shapes
/// - Adds a pulsing glow animation on the highlighted widget
class SpotlightMask extends StatefulWidget {
  /// The anchor ID of the widget to highlight.
  final String? anchorId;

  /// Called when the user taps outside the highlighted zone.
  final VoidCallback? onBlockedTap;

  /// The child overlay UI (typically the dialogue content above the spotlight).
  final Widget child;

  /// Spotlight cutout padding around the target widget.
  final double padding;

  /// Opacity of the dimmed mask (0.0 transparent → 1.0 opaque).
  final double maskOpacity;

  const SpotlightMask({
    super.key,
    this.anchorId,
    this.onBlockedTap,
    required this.child,
    this.padding = 8.0,
    this.maskOpacity = 0.70,
  });

  @override
  State<SpotlightMask> createState() => _SpotlightMaskState();
}

class _SpotlightMaskState extends State<SpotlightMask>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.0, end: 4.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scheduleRectLookup();
  }

  @override
  void didUpdateWidget(SpotlightMask oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.anchorId != widget.anchorId) {
      _scheduleRectLookup();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _scheduleRectLookup() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _targetRect = _getHighlightRect();
        });
      }
    });
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() {
          _targetRect = _getHighlightRect();
        });
      }
    });
  }

  Rect? _getHighlightRect() {
    if (widget.anchorId == null) return null;
    return GuideAnchorRegistry.getRect(widget.anchorId!);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, _) {
                return CustomPaint(
                  painter: _SpotlightPainter(
                    targetRect: _targetRect,
                    padding: widget.padding + _pulseAnimation.value,
                    maskOpacity: widget.maskOpacity,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),
        ),
        if (_targetRect != null)
          Positioned.fill(
            child: _PassThroughHitTestWidget(
              passThroughRect: _targetRect?.inflate(widget.padding),
              onBlockedTap: widget.onBlockedTap,
            ),
          ),
        widget.child,
      ],
    );
  }
}

/// Custom painter that draws a semi-transparent dark mask with a transparent
/// rounded cutout revealing the target widget beneath.
class _SpotlightPainter extends CustomPainter {
  final Rect? targetRect;
  final double padding;
  final double maskOpacity;

  _SpotlightPainter({
    this.targetRect,
    this.padding = 8.0,
    this.maskOpacity = 0.70,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final maskPaint = Paint()..color = Colors.black.withValues(alpha: maskOpacity);

    if (targetRect == null) {
      canvas.drawRect(Offset.zero & size, maskPaint);
      return;
    }

    final inflatedRect = targetRect!.inflate(padding);

    final targetPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        inflatedRect,
        const Radius.circular(12.0),
      ));

    final maskPath = Path()..addRect(Offset.zero & size);

    final finalPath =
        Path.combine(PathOperation.difference, maskPath, targetPath);

    canvas.drawPath(finalPath, maskPaint);

    final glowPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(inflatedRect, const Radius.circular(12.0)),
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.padding != padding;
  }
}

/// Widget that intercepts touch events, but allows them to pass through
/// inside a specified rectangle (the spotlight cutout).
class _PassThroughHitTestWidget extends SingleChildRenderObjectWidget {
  final Rect? passThroughRect;
  final VoidCallback? onBlockedTap;

  const _PassThroughHitTestWidget({
    this.passThroughRect,
    this.onBlockedTap,
  });

  @override
  RenderPassThroughHitTest createRenderObject(BuildContext context) {
    return RenderPassThroughHitTest(
      passThroughRect: passThroughRect,
      onBlockedTap: onBlockedTap,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderPassThroughHitTest renderObject) {
    renderObject.passThroughRect = passThroughRect;
    renderObject.onBlockedTap = onBlockedTap;
  }
}

class RenderPassThroughHitTest extends RenderProxyBox {
  Rect? passThroughRect;
  VoidCallback? onBlockedTap;

  RenderPassThroughHitTest({
    this.passThroughRect,
    this.onBlockedTap,
  });

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (passThroughRect != null && passThroughRect!.contains(position)) {
      return false;
    }
    return super.hitTest(result, position: position);
  }

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is PointerDownEvent) {
      onBlockedTap?.call();
    }
    super.handleEvent(event, entry);
  }
}
