import 'package:flutter/material.dart';
import 'package:colosynth/game_data/level_data.dart';
import 'package:colosynth/services/sprite_repository.dart';
import 'package:colosynth/widgets/common/animated_tap_button.dart';

class ArenaCard extends StatelessWidget {
  const ArenaCard({
    super.key,
    required this.tournament,
    required this.style,
    required this.progress,
    required this.unlocked,
    this.onTap,
  });

  final TournamentData tournament;
  final ArenaStyle style;
  final Map<String, String> progress;
  final bool unlocked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedTapButton(
      onTap: onTap,
      scaleDown: 0.95,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            unlocked
                ? Image.asset(
                    SpriteRepository.tournamentTier(tournament.tier),
                    fit: BoxFit.cover,
                  )
                : ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                        Colors.grey, BlendMode.saturation),
                    child: Image.asset(
                      SpriteRepository.tournamentTier(tournament.tier),
                      fit: BoxFit.cover,
                    ),
                  ),
            if (!unlocked)
              Container(
                color: Colors.black.withValues(alpha: 0.50),
                child: const Center(
                  child: Icon(
                    Icons.lock_outline,
                    color: Colors.white54,
                    size: 32,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ExtremeArenaCard extends StatelessWidget {
  const ExtremeArenaCard({
    super.key,
    required this.slot,
    required this.progress,
    required this.unlocked,
    this.onTap,
  });

  final TSlot slot;
  final Map<String, String> progress;
  final bool unlocked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedTapButton(
      onTap: onTap,
      scaleDown: 0.95,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            unlocked
                ? Image.asset(
                    SpriteRepository.extremeTournament,
                    fit: BoxFit.cover,
                  )
                : ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                        Colors.grey, BlendMode.saturation),
                    child: Image.asset(
                      SpriteRepository.extremeTournament,
                      fit: BoxFit.cover,
                    ),
                  ),
            if (!unlocked)
              Container(
                color: Colors.black.withValues(alpha: 0.50),
                child: const Center(
                  child: Icon(
                    Icons.lock_outline,
                    color: Colors.white54,
                    size: 32,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


class TutorialCard extends StatelessWidget {
  const TutorialCard({
    super.key,
    required this.done,
    this.onTap,
  });

  final bool done;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedTapButton(
      onTap: onTap,
      scaleDown: 0.95,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/battle_ready.png',
              fit: BoxFit.cover,
            ),
            Container(
              color: Colors.black.withValues(alpha: 0.25),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    done ? Icons.school : Icons.menu_book_outlined,
                    color: Colors.white.withValues(alpha: 0.95),
                    size: 36,
                    shadows: const [
                      Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 4),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'TUTORIAL',
                    style: TextStyle(
                      fontFamily: 'Bangers',
                      fontSize: 16,
                      letterSpacing: 3,
                      color: Colors.white.withValues(alpha: 0.95),
                      shadows: const [
                        Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (done)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'DONE',
                    style: TextStyle(
                      fontFamily: 'Bangers',
                      fontSize: 9,
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
