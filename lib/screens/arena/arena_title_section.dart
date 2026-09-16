import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:colosynth/screens/theme/tokens.dart';

class ArenaTitleSection extends StatelessWidget {
  const ArenaTitleSection({super.key});

  static const _labelColor = AppColors.sketchGray;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _DividerLine(),
        const SizedBox(height: 16),
        const Text(
          'ARENA OF',
          style: TextStyle(
            color: _labelColor,
            fontSize: 13,
            letterSpacing: 6,
            fontWeight: FontWeight.w400,
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
        const SizedBox(height: 8),
        const _GradientTitle()
            .animate()
            .fadeIn(delay: 100.ms, duration: 500.ms)
            .scale(
              begin: const Offset(0.9, 0.9),
              duration: 600.ms,
              curve: Curves.easeOutBack,
            )
            .shimmer(delay: 1.2.seconds, duration: 1.5.seconds, color: Colors.white24),
        const SizedBox(height: 8),
        const Text(
          'CHAMPIONS',
          style: TextStyle(color: _labelColor, fontSize: 11, letterSpacing: 8),
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: -0.2, end: 0),
        const SizedBox(height: 16),
        const _DividerLine(),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _GradientTitle extends StatelessWidget {
  const _GradientTitle();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.ink, AppColors.darkGray],
        stops: [0.0, 1.0],
      ).createShader(bounds),
      child: const Text(
        'COLOSYNTH',
        style: TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontWeight: FontWeight.w900,
          letterSpacing: 8,
          height: 1.0,
        ),
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: [
          const Expanded(
              child: Divider(color: AppColors.lightGray, thickness: 1.5)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.ink,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Expanded(
              child: Divider(color: AppColors.lightGray, thickness: 1.5)),
        ],
      ),
    );
  }
}
