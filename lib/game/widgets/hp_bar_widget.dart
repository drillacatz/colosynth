import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:colosynth/screens/theme/tokens.dart';

class HpBar extends StatelessWidget {
  const HpBar({
    super.key,
    required this.current,
    required this.max,
    this.label = 'HP',
    this.height = 22,
  });

  final int current;
  final int max;
  final String label;
  final double height;

  Color get _barColor {
    final safeMax = max < 1 ? 1 : max;
    final r = current / safeMax;
    if (r > .5) return AppColors.ink;
    if (r > .25) return AppColors.darkGray;
    return AppColors.sketchGray;
  }

  @override
  Widget build(BuildContext context) {
    final safeMax = max < 1 ? 1 : max;
    final ratio = (current / safeMax).clamp(0.0, 1.0);
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Bangers',
            fontSize: 14,
            color: Colors.white70,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: height,
            child: CustomPaint(
              painter: _HpPainter(
                ratio: ratio,
                color: _barColor,
                ht: PBTokens.halftone[PBStyle.white]!,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$current/$max',
          style: TextStyle(
            fontFamily: 'Bangers',
            fontSize: 13,
            color: _barColor,
          ),
        ),
      ],
    );
  }
}

class _HpPainter extends CustomPainter {
  const _HpPainter({
    required this.ratio,
    required this.color,
    required this.ht,
  });

  final double ratio;
  final Color color;
  final HalftoneVariant ht;

  static const _b = 3.0;
  static const _nw = PBTokens.hpNotchW;
  static const _nh = PBTokens.hpNotchH;

  Path _notchedPath(Rect r) => Path()
    ..moveTo(r.left, r.top)
    ..lineTo(r.right - _nw, r.top)
    ..lineTo(r.right, r.top + _nh)
    ..lineTo(r.right, r.bottom)
    ..lineTo(r.left + _nw, r.bottom)
    ..lineTo(r.left, r.bottom - _nh)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    final full = Offset.zero & size;
    final inner = full.deflate(_b);

    canvas.drawPath(
        _notchedPath(full), Paint()..color = const Color(0xFF111111));
    canvas.drawPath(
        _notchedPath(inner), Paint()..color = const Color(0xFF0A0A0A));

    if (ratio > 0) {
      final fillRect = Rect.fromLTWH(
        inner.left,
        inner.top,
        inner.width * ratio,
        inner.height,
      );
      canvas.save();
      canvas.clipPath(_notchedPath(inner));
      canvas.drawRect(fillRect, Paint()..color = color);
      _paintHalftone(canvas, fillRect);
      canvas.drawRect(
        Rect.fromLTWH(inner.left + 4, inner.top + 3, fillRect.width - 8, 4),
        Paint()..color = Colors.white.withValues(alpha: .22),
      );
      canvas.restore();
    }

    for (final pct in [.25, .50, .75]) {
      final x = full.left + full.width * pct;
      canvas.drawLine(
        Offset(x, full.top),
        Offset(x, full.bottom),
        Paint()
          ..color = const Color(0xFF111111)
          ..strokeWidth = 3,
      );
    }

    canvas.drawPath(
      _notchedPath(full),
      Paint()
        ..color = const Color(0xFF111111)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _b,
    );
  }

  void _paintHalftone(Canvas canvas, Rect fillRect) {
    canvas.save();
    canvas.translate(fillRect.center.dx, fillRect.center.dy);
    canvas.rotate(math.pi / 4);
    canvas.translate(-fillRect.center.dx, -fillRect.center.dy);

    final s = ht.spacing, r = ht.dotR, pad = fillRect.width;
    final dotColor = ht.white ? Colors.white : Colors.black;
    final fadeStart = fillRect.left + fillRect.width * .4;

    for (double x = fillRect.left - pad; x < fillRect.right + pad; x += s) {
      final alpha =
          ((x - fadeStart) / (fillRect.right - fadeStart)).clamp(0.0, 1.0);
      if (alpha <= 0) continue;
      final paint = Paint()..color = dotColor.withValues(alpha: ht.opacity * alpha);
      for (double y = fillRect.top - pad; y < fillRect.bottom + pad; y += s) {
        canvas.drawCircle(Offset(x, y), r, paint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HpPainter o) => o.ratio != ratio || o.color != color;
}
