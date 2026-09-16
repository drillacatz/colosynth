import 'package:flutter/material.dart';

import 'package:colosynth/guide/guide_anchor.dart';
import 'package:colosynth/guide/models/guide_step.dart';

/// A compact, notebook-paper-themed tooltip bubble with a triangular pointer
/// that points at a specific [GuideAnchor] widget.
///
/// Used for [GuideStepType.coachMark] steps — contextual hints that explain
/// individual UI elements without the full dialogue box treatment.
///
/// The bubble auto-positions itself relative to the anchor based on
/// [GuidePosition] and adjusts if it would overflow the screen.
class CoachBubble extends StatefulWidget {
  /// The anchor ID to point at.
  final String? anchorId;

  /// The tooltip text content.
  final String text;

  /// Where to position the bubble relative to the anchor widget.
  final GuidePosition position;

  /// Called when the user taps the bubble to advance.
  final VoidCallback? onTap;

  const CoachBubble({
    super.key,
    this.anchorId,
    required this.text,
    this.position = GuidePosition.bottom,
    this.onTap,
  });

  @override
  State<CoachBubble> createState() => _CoachBubbleState();
}

class _CoachBubbleState extends State<CoachBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;
  Rect? _anchorRect;

  static const double _bubbleMaxWidth = 280;
  static const double _arrowSize = 10;
  static const double _bubblePadding = 16;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutBack),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut),
    );

    _schedulePositionAndAnimate();
  }

  @override
  void didUpdateWidget(CoachBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.anchorId != widget.anchorId) {
      _schedulePositionAndAnimate();
    }
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  void _schedulePositionAndAnimate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _anchorRect = widget.anchorId != null
            ? GuideAnchorRegistry.getRect(widget.anchorId!)
            : null;
      });
      _entranceCtrl.forward(from: 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_anchorRect == null) {
      return _buildCenteredFallback(context);
    }

    final screenSize = MediaQuery.sizeOf(context);
    final pos = _calculatePosition(screenSize);

    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: _buildBubbleContent(),
    );
  }

  Widget _buildCenteredFallback(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: _buildBubbleContent(),
      ),
    );
  }

  Offset _calculatePosition(Size screenSize) {
    final anchor = _anchorRect!;
    final anchorCenter = anchor.center;

    double dx = 0;
    double dy = 0;

    switch (widget.position) {
      case GuidePosition.top:
        dx = (anchorCenter.dx - _bubbleMaxWidth / 2)
            .clamp(_bubblePadding, screenSize.width - _bubbleMaxWidth - _bubblePadding);
        dy = anchor.top - _arrowSize - 120;
        break;
      case GuidePosition.bottom:
        dx = (anchorCenter.dx - _bubbleMaxWidth / 2)
            .clamp(_bubblePadding, screenSize.width - _bubbleMaxWidth - _bubblePadding);
        dy = anchor.bottom + _arrowSize + 4;
        break;
      case GuidePosition.left:
        dx = anchor.left - _bubbleMaxWidth - _arrowSize - 4;
        dy = anchorCenter.dy - 60;
        break;
      case GuidePosition.right:
        dx = anchor.right + _arrowSize + 4;
        dy = anchorCenter.dy - 60;
        break;
      case GuidePosition.center:
        dx = (screenSize.width - _bubbleMaxWidth) / 2;
        dy = (screenSize.height - 120) / 2;
        break;
    }

    dy = dy.clamp(_bubblePadding, screenSize.height - 160);
    dx = dx.clamp(_bubblePadding, screenSize.width - _bubbleMaxWidth - _bubblePadding);

    return Offset(dx, dy);
  }

  Widget _buildBubbleContent() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        alignment: _getScaleAlignment(),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            constraints: const BoxConstraints(maxWidth: _bubbleMaxWidth),
            child: CustomPaint(
              painter: _CoachBubblePainter(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.text,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1E1100),
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'TAP TO CONTINUE ▶',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF888888),
                          fontFamily: 'Bangers',
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Alignment _getScaleAlignment() {
    switch (widget.position) {
      case GuidePosition.top:
        return Alignment.bottomCenter;
      case GuidePosition.bottom:
        return Alignment.topCenter;
      case GuidePosition.left:
        return Alignment.centerRight;
      case GuidePosition.right:
        return Alignment.centerLeft;
      case GuidePosition.center:
        return Alignment.center;
    }
  }
}

/// Painter for the coach bubble — a notebook-paper-styled rounded rectangle
/// with a hand-drawn aesthetic (subtle jitter, paper texture lines).
class _CoachBubblePainter extends CustomPainter {
  static const double _borderWidth = 2.5;
  static const double _radius = 10.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final shadowRect = rect.translate(4, 4);
    final shadowRRect = RRect.fromRectAndRadius(
      shadowRect,
      const Radius.circular(_radius),
    );
    canvas.drawRRect(
      shadowRRect,
      Paint()..color = const Color(0xFFD0C8C0),
    );

    final faceRRect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(_radius),
    );
    canvas.drawRRect(
      faceRRect,
      Paint()..color = const Color(0xFFFDFDFB),
    );

    canvas.save();
    canvas.clipRRect(faceRRect);
    final linePaint = Paint()
      ..color = const Color(0xFFB8D4F0).withValues(alpha: 0.5)
      ..strokeWidth = 0.8;
    double y = 20;
    while (y < size.height) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        linePaint,
      );
      y += 18;
    }
    canvas.restore();

    canvas.drawRRect(
      faceRRect,
      Paint()
        ..color = const Color(0xFF111111)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _borderWidth
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
