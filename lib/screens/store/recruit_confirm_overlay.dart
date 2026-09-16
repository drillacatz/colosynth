import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:colosynth/game_data/character_type.dart';
import 'package:colosynth/screens/theme/tokens.dart';

class RecruitConfirmOverlay extends StatelessWidget {
  const RecruitConfirmOverlay({
    super.key,
    required this.character,
    required this.onConfirm,
    required this.onCancel,
    required this.canAfford,
  });

  final CharacterData character;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool canAfford;

  static Future<void> show(
    BuildContext context, {
    required CharacterData character,
    required VoidCallback onConfirm,
    required bool canAfford,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (ctx) => RecruitConfirmOverlay(
        character: character,
        onConfirm: () {
          Navigator.of(ctx).pop();
          onConfirm();
        },
        onCancel: () => Navigator.of(ctx).pop(),
        canAfford: canAfford,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
          decoration: BoxDecoration(
            color: const Color(0xFFFDFDFB),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF1A1A1A), width: 2.0),
            boxShadow: const [
              BoxShadow(color: Color(0x66000000), offset: Offset(6, 6)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'RECRUIT?',
                style: TextStyle(
                  fontFamily: 'Bangers',
                  fontSize: 32,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black12),
                ),
                child: Icon(
                  character.icon,
                  size: 48,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Confirm recruitment of ${character.name}?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF444444),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.brush, color: Color(0xFF1A1A1A), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${character.paintCost}',
                    style: TextStyle(
                      fontFamily: 'Bangers',
                      fontSize: 24,
                      color:
                          canAfford ? const Color(0xFF1A1A1A) : const Color(0xFF888888),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              if (!canAfford) ...[
                const SizedBox(height: 8),
                const Text(
                  'INSUFFICIENT PAINT',
                  style: TextStyle(
                    color: Color(0xFF555555),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ComicButton(
                      label: 'CANCEL',
                      style: PBStyle.dark,
                      onTap: onCancel,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ComicButton(
                      label: 'CONFIRM',
                      style: PBStyle.white,
                      onTap: canAfford ? onConfirm : null,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
            .animate()
            .scale(
              begin: const Offset(0.82, 0.82),
              duration: 380.ms,
              curve: Curves.elasticOut,
            )
            .fadeIn(
              duration: 200.ms,
              curve: Curves.easeOut,
            ),
      ),
    );
  }
}
