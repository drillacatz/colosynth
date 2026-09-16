import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:colosynth/screens/theme/tokens.dart';

class CurrencyPill extends StatefulWidget {
  const CurrencyPill({
    super.key,
    required this.icon,
    required this.color,
    required this.amount,
    this.onAdd,
    this.animateGain = false,
  });

  final IconData icon;
  final Color color;
  final int amount;
  final VoidCallback? onAdd;
  final bool animateGain;

  @override
  State<CurrencyPill> createState() => _CurrencyPillState();
}

class _CurrencyPillState extends State<CurrencyPill>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    if (widget.animateGain) {
      _animController.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(covariant CurrencyPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animateGain &&
        (!oldWidget.animateGain || widget.amount != oldWidget.amount)) {
      _animController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  static const _ink = Color(0xFF1A1A1A);

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final pill = AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      transform: _pressed
          ? Matrix4.translationValues(1.5, 1.5, 0)
          : Matrix4.translationValues(0, 0, 0),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFB),
        borderRadius: BorderRadius.zero,
        border: Border.all(color: const Color(0xFF1A1A1A), width: 1.8),
        boxShadow: _pressed
            ? const []
            : const [
                BoxShadow(
                  color: Color(0xFF1A1A1A),
                  offset: Offset(2, 2),
                ),
              ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, color: widget.color, size: 15),
          const SizedBox(width: 3),
          Text(
            _fmt(widget.amount),
            style: const TextStyle(
              color: _ink,
              fontSize: 13,
              fontFamily: 'Bangers',
              letterSpacing: 0.5,
            ),
          ),
          if (widget.onAdd != null) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.add_circle_outline,
              color: _pressed ? widget.color : _ink.withValues(alpha: 0.55),
              size: 14,
            ),
          ],
        ],
      ),
    );

    final child = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onAdd != null ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.onAdd != null ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: widget.onAdd != null ? () => setState(() => _pressed = false) : null,
      onTap: widget.onAdd != null
          ? () {
              ComicButton.playButtonSfx();
              unawaited(HapticFeedback.lightImpact());
              widget.onAdd!();
            }
          : null,
      child: pill,
    );

    if (widget.animateGain) {
      return ScaleTransition(
        scale: TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween(begin: 1.0, end: 1.25)
                .chain(CurveTween(curve: Curves.easeOut)),
            weight: 45,
          ),
          TweenSequenceItem(
            tween: Tween(begin: 1.25, end: 1.0)
                .chain(CurveTween(curve: Curves.elasticOut)),
            weight: 55,
          ),
        ]).animate(_animController),
        child: child,
      );
    }

    return child;
  }
}
