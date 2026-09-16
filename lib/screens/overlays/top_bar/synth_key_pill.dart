import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:colosynth/screens/theme/tokens.dart';

class SynthKeyPill extends StatefulWidget {
  const SynthKeyPill({
    super.key,
    required this.keys,
    this.onTap,
  });

  final int keys;
  final VoidCallback? onTap;

  @override
  State<SynthKeyPill> createState() => _SynthKeyPillState();
}

class _SynthKeyPillState extends State<SynthKeyPill> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        ComicButton.playButtonSfx();
        unawaited(HapticFeedback.lightImpact());
        widget.onTap?.call();
      },
      child: AnimatedContainer(
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.vpn_key_rounded,
              color: Color(0xFFFF8F00),
              size: 14,
            ),
            const SizedBox(width: 3),
            Text(
              '${widget.keys}',
              style: const TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 13,
                fontFamily: 'Bangers',
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
