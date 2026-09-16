import 'package:flutter/material.dart';
import 'package:colosynth/screens/theme/tokens.dart';
import 'package:colosynth/services/sprite_repository.dart';

class CharacterPortraitSection extends StatelessWidget {
  const CharacterPortraitSection({
    super.key,
    required this.id,
    required this.icon,
    required this.name,
    required this.title,
    required this.rarityLabel,
    required this.rarityColor,
    required this.isLimited,
    required this.hoursLeft,
    required this.isOwned,
  });

  final String id;
  final IconData icon;
  final String name;
  final String title;
  final String rarityLabel;
  final Color rarityColor;
  final bool isLimited;
  final int hoursLeft;
  final bool isOwned;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Hero(
            tag: 'char_$id',
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isOwned
                      ? const Color(0xFF00E5FF).withValues(alpha: 0.60)
                      : AppColors.ink.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.25),
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  SpriteRepository.characterPortrait(id),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.paperWhite,
                    child: Center(
                      child: Icon(icon, color: AppColors.ink, size: 80),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: rarityColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                    color: rarityColor.withValues(alpha: 0.50), width: 1),
              ),
              child: Text(
                rarityLabel,
                style: TextStyle(
                  color: rarityColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
            if (isLimited && hoursLeft > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4400).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  '${hoursLeft}h LEFT',
                  style: const TextStyle(
                    color: Color(0xFFFF6622),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
            if (isOwned) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text(
                  'OWNED',
                  style: TextStyle(
                    color: Color(0xFF00E5FF),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 5,
          ),
        ),
      ],
    );
  }
}
