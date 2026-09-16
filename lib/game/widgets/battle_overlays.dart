import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:colosynth/game/app_shell/battle_screen.dart' show BattleResult;
import 'package:colosynth/screens/theme/tokens.dart';


class VictoryOverlay extends StatefulWidget {
  const VictoryOverlay({
    super.key,
    required this.result,
    required this.onContinue,
  });

  final BattleResult result;
  final VoidCallback onContinue;

  @override
  State<VictoryOverlay> createState() => _VictoryOverlayState();
}

class _VictoryOverlayState extends State<VictoryOverlay> {
  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.85),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'VICTORY',
                style: TextStyle(
                  fontFamily: 'Bangers',
                  color: AppColors.pureWhite,
                  fontSize: 72,
                  letterSpacing: 8,
                  shadows: [
                    Shadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 2),
                  ],
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut).shimmer(delay: 800.ms, duration: 1.5.seconds),
              
              const SizedBox(height: 32),
              
              _RewardRow(
                label: 'INK EARNED',
                value: '+${widget.result.inkEarned}',
                icon: Icons.water_drop,
                color: Colors.cyanAccent,
              ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.2),
              
              _RewardRow(
                label: 'PAINT EARNED',
                value: '+${widget.result.paintEarned}',
                icon: Icons.palette,
                color: Colors.orangeAccent,
              ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.2),
              
              _RewardRow(
                label: 'XP GAINED',
                value: '+${widget.result.xpEarned}',
                icon: Icons.trending_up,
                color: Colors.greenAccent,
              ).animate().fadeIn(delay: 800.ms).slideX(begin: -0.2),
              
              const SizedBox(height: 48),
              
              ComicButton(
                label: 'CONTINUE',
                style: PBStyle.white,
                fontSize: 20,
                padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 16),
                onTap: widget.onContinue,
              ).animate().fadeIn(delay: 1200.ms).scale(begin: const Offset(0.8, 0.8)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Bangers',
                color: Colors.white70,
                fontSize: 18,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Bangers',
              color: color,
              fontSize: 22,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}


class DefeatOverlay extends StatefulWidget {
  const DefeatOverlay({
    super.key,
    required this.reviveAvailable,
    required this.onRevive,
    required this.onRestart,
    required this.onQuit,
  });

  final bool reviveAvailable;
  final VoidCallback onRevive;
  final VoidCallback onRestart;
  final VoidCallback onQuit;

  @override
  State<DefeatOverlay> createState() => _DefeatOverlayState();
}

class _DefeatOverlayState extends State<DefeatOverlay> {
  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xDD1A1A1A),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'DEFEAT',
                style: TextStyle(
                  fontFamily: 'Bangers',
                  color: AppColors.pureWhite,
                  fontSize: 72,
                  letterSpacing: 6,
                  shadows: [
                    Shadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 4),
                  ],
                ),
              ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(1.2, 1.2), curve: Curves.easeOut),
              
              const SizedBox(height: 12),
              
              const SizedBox(height: 60),
              
              if (widget.reviveAvailable) ...[
                ComicButton(
                  label: 'REVIVE (AD)',
                  style: PBStyle.white,
                  fontSize: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
                  onTap: widget.onRevive,
                ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2),
                const SizedBox(height: 20),
              ],
              
              ComicButton(
                label: 'RESTART',
                style: PBStyle.white,
                fontSize: 18,
                padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 14),
                onTap: widget.onRestart,
              ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.2),
              
              const SizedBox(height: 16),
              
              ComicButton(
                label: 'QUIT',
                style: PBStyle.dark,
                fontSize: 18,
                padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 14),
                onTap: widget.onQuit,
              ).animate().fadeIn(delay: 1100.ms).slideY(begin: 0.2),
            ],
          ),
        ),
      ),
    );
  }
}
