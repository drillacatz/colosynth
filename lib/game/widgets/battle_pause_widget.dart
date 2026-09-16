import 'package:flutter/material.dart';
import 'package:colosynth/game/app_shell/battle_screen.dart';
import 'package:colosynth/screens/theme/tokens.dart';

class BattlePauseWidget extends StatelessWidget {
  const BattlePauseWidget({
    super.key,
    required this.game,
    this.onResume,
    this.onRestart,
  });

  final BattleFlameGame game;
  final VoidCallback? onResume;
  final VoidCallback? onRestart;

  @override
  Widget build(BuildContext context) {
    return _BattlePauseOverlay(
      onResume: () {
        if (onResume != null) {
          onResume!();
        } else {
          game.game.resumeEngine();
          game.overlays.remove('pause');
        }
      },
      onRestart: () {
        if (onRestart != null) {
          onRestart!();
        } else {
          game.game.resumeEngine();
          game.game.resetBattle();
          game.overlays.remove('pause');
        }
      },
      onQuit: () {
        Navigator.of(context, rootNavigator: true)
            .pop(BattleResult.empty(BattleOutcome.quit));
      },
    );
  }
}

class _BattlePauseOverlay extends StatelessWidget {
  const _BattlePauseOverlay({
    required this.onResume,
    required this.onRestart,
    required this.onQuit,
  });

  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.82),
            Colors.black.withValues(alpha: 0.92),
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'PAUSED',
                style: TextStyle(
                  fontFamily: 'Bangers',
                  color: Colors.red,
                  fontSize: 52,
                  letterSpacing: 8,
                  shadows: [Shadow(color: Colors.red, blurRadius: 16)],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 160,
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.red.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 36),
              ComicButton(
                label: 'RESUME',
                style: PBStyle.white,
                fontSize: 18,
                padding:
                    const EdgeInsets.symmetric(horizontal: 44, vertical: 14),
                onTap: onResume,
              ),
              const SizedBox(height: 14),
              ComicButton(
                label: 'RESTART',
                style: PBStyle.white,
                fontSize: 16,
                padding:
                    const EdgeInsets.symmetric(horizontal: 44, vertical: 13),
                onTap: onRestart,
              ),
              const SizedBox(height: 14),
              ComicButton(
                label: 'QUIT',
                style: PBStyle.dark,
                fontSize: 16,
                padding:
                    const EdgeInsets.symmetric(horizontal: 44, vertical: 13),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    barrierColor: Colors.black54,
                    builder: (_) => const QuitDialog(),
                  );
                  if (confirmed == true) {
                    onQuit();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuitDialog extends StatelessWidget {
  const QuitDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Colors.white24, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'QUIT BATTLE?',
              style: TextStyle(
                fontFamily: 'Bangers',
                fontSize: 24,
                letterSpacing: 3,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Progress will be lost',
              style: TextStyle(fontSize: 12, color: Colors.white54),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Center(
                        child: Text(
                          'STAY',
                          style: TextStyle(
                            fontFamily: 'Bangers',
                            fontSize: 14,
                            letterSpacing: 2,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Center(
                        child: Text(
                          'QUIT',
                          style: TextStyle(
                            fontFamily: 'Bangers',
                            fontSize: 14,
                            letterSpacing: 2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
