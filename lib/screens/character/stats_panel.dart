import 'package:colosynth/providers/exp_items_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:colosynth/game_data/character_type.dart';
import 'package:colosynth/providers/battle_provider.dart';
import 'package:colosynth/providers/save_provider.dart';
import 'package:colosynth/screens/theme/shared_painters.dart';
import 'package:colosynth/screens/theme/tokens.dart';
import 'package:colosynth/screens/character/character_misc.dart';

class CharacterStatsPanel extends ConsumerWidget {
  const CharacterStatsPanel({super.key, required this.character});
  final CharacterData character;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          CharacterLevelStats(character: character),
          const SizedBox(height: 24),
          CharacterSkills(character: character),
        ],
      ),
    );
  }
}

class CharacterLevelStats extends ConsumerWidget {
  const CharacterLevelStats({super.key, required this.character});
  final CharacterData character;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelData = ref.watch(charLevelProvider);
    final statsAsync = ref.watch(battleStatsProvider);
    final stats = statsAsync.value;

    if (stats == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const PopArtLabel(
          label: 'LEVEL STATS',
          accent: AppColors.ink,
        ),
        const SizedBox(height: 8),
        StatBar(
          stat: CharacterStat(
            label: 'HP',
            value: stats.hp,
          ),
          max: 100000,
        ),
        const SizedBox(height: 6),
        StatBar(
          stat: CharacterStat(
            label: 'ATK',
            value: stats.atk,
          ),
          max: 10000,
        ),
        const SizedBox(height: 6),
        StatBar(
          stat: CharacterStat(
            label: 'DMG RED',
            value: (stats.damageReduction * 100).round(),
            displayValue: '${(stats.damageReduction * 100).toStringAsFixed(1)}%',
          ),
          max: 100,
        ),
        const SizedBox(height: 6),
        StatBar(
          stat: CharacterStat(label: 'SHIELD', value: stats.shield),
          max: 5000,
        ),
        const SizedBox(height: 8),
        _XpBar(
          xp: levelData.xp,
          level: levelData.level,
        ),
      ],
    );
  }
}

class CharacterSkills extends StatelessWidget {
  const CharacterSkills({super.key, required this.character});
  final CharacterData character;

  static const Color _kActiveTag = Color(0xFFFF3B30);
  static const Color _kPassiveTag = Color(0xFF34C759);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const PopArtLabel(
          label: 'CHARACTER SKILLS',
          accent: AppColors.ink,
        ),
        const SizedBox(height: 12),
        SkillCard(
          skill: character.activeSkill,
          tag: 'ACTIVE',
          tagColor: _kActiveTag,
        ),
        const SizedBox(height: 12),
        SkillCard(
          skill: character.passiveSkill,
          tag: 'PASSIVE',
          tagColor: _kPassiveTag,
        ),
      ],
    );
  }
}

class CharacterStatsHorizontal extends ConsumerWidget {
  const CharacterStatsHorizontal({super.key, required this.character});
  final CharacterData character;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(battleStatsProvider);
    final stats = statsAsync.value;

    if (stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        StatBar(
          stat: CharacterStat(
            label: 'HP',
            value: stats.hp,
          ),
          isHorizontal: true,
        ),
        const SizedBox(width: 8),
        StatBar(
          stat: CharacterStat(
            label: 'ATK',
            value: stats.atk,
          ),
          isHorizontal: true,
        ),
        const SizedBox(width: 8),
        StatBar(
          stat: CharacterStat(
            label: 'DMG RED',
            value: (stats.damageReduction * 100).round(),
            displayValue: '${(stats.damageReduction * 100).toStringAsFixed(1)}%',
          ),
          isHorizontal: true,
        ),
      ],
    );
  }
}

class _XpBar extends StatelessWidget {
  const _XpBar({
    required this.xp,
    required this.level,
  });

  final int xp;
  final int level;

  @override
  Widget build(BuildContext context) {
    if (level >= 90) return const SizedBox.shrink();
    const xpPerLevel = 1685;
    final nextLevelXp = level * xpPerLevel;
    final currentLevelBaseXp = (level - 1) * xpPerLevel;
    final progress = ((xp - currentLevelBaseXp) / xpPerLevel).clamp(0.0, 1.0);

    return Consumer(
      builder: (context, ref, _) {
        final expBooks = ref.watch(
          expItemsProvider.select((items) => items['exp_book'] ?? 0),
        );
        final ink = ref.watch(inkProvider);
        final cost = (level + 1) * 200;
        final canUpgrade = expBooks > 0 && ink >= cost;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'XP',
                  style: TextStyle(
                    color: AppColors.sketchGray,
                    fontSize: 10,
                    fontFamily: 'Bangers',
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  '$xp / $nextLevelXp',
                  style: TextStyle(
                    color: AppColors.ink.withValues(alpha: 0.55),
                    fontSize: 10,
                    fontFamily: 'Bangers',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Stack(
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.ink.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.ink.withValues(alpha: 0.20),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: canUpgrade
                  ? () async {
                      final characterId = ref.read(equippedCharacterIdProvider);
                      await ref
                          .read(characterLevelFamily(characterId).notifier)
                          .upgrade();
                    }
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  color: canUpgrade
                      ? AppColors.ink
                      : AppColors.ink.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: canUpgrade
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_upward,
                      size: 12,
                      color: canUpgrade
                          ? AppColors.paperWhite
                          : AppColors.ink.withValues(alpha: 0.2),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      canUpgrade
                          ? 'UPGRADE (1 BOOK)'
                          : expBooks <= 0
                              ? 'NO EXP BOOKS'
                              : 'NOT ENOUGH INK',
                      style: TextStyle(
                        color: canUpgrade
                            ? AppColors.paperWhite
                            : AppColors.ink.withValues(alpha: 0.2),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Bangers',
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class StatBar extends StatelessWidget {
  const StatBar({
    super.key,
    required this.stat,
    this.isHorizontal = false,
    this.max = 100,
  });
  final CharacterStat stat;
  final bool isHorizontal;
  final double max;

  @override
  Widget build(BuildContext context) {
    if (isHorizontal) {
      return CustomPaint(
          painter: NotebookCardPainter(
            seed: stat.label.hashCode,
            faceColor: AppColors.paperWhite.withValues(alpha: 0.8),
            borderColor: AppColors.ink.withValues(alpha: 0.1),
            borderWidth: 1.0,
            cornerRadius: 4.0,
          ),
          child: Container(
            width: 80,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  stat.label,
                  style: const TextStyle(
                    color: AppColors.sketchGray,
                    fontSize: 9,
                    letterSpacing: 1,
                    fontFamily: 'Bangers',
                  ),
                ),
                Text(
                  stat.displayValue ?? '${stat.value}',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Bangers',
                  ),
                ),
              ],
            ),
          ));
    }
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            stat.label,
            style: const TextStyle(
              color: AppColors.sketchGray,
              fontSize: 11,
              letterSpacing: 1,
              fontFamily: 'Bangers',
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 7,
                decoration: BoxDecoration(
                  color: AppColors.ink.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(1),
                  border: Border.all(
                    color: AppColors.ink.withValues(alpha: 0.07),
                    width: 0.5,
                  ),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (stat.value / max).clamp(0.0, 1.0),
                child: Container(
                  height: 7,
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(1),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.ink.withValues(alpha: 0.2),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 38,
          child: Text(
            stat.displayValue ?? '${stat.value}',
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              fontFamily: 'Bangers',
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class SkillCard extends StatelessWidget {
  const SkillCard({
    super.key,
    required this.skill,
    required this.tag,
    required this.tagColor,
  });

  final CharacterSkill skill;
  final String tag;
  final Color tagColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
        painter: NotebookCardPainter(
          seed: skill.name.hashCode,
          faceColor: AppColors.paperWhite.withValues(alpha: 0.95),
          borderColor: AppColors.ink.withValues(alpha: 0.15),
          borderWidth: 1.5,
          cornerRadius: 4.0,
          showShadow: true,
        ),
        child: Container(
          padding: const EdgeInsets.all(11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.ink.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.ink.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(skill.icon, color: AppColors.ink, size: 14),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      skill.name.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Bangers',
                        letterSpacing: 1,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: tagColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                        color: tagColor.withValues(alpha: 0.4),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        color: tagColor,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                skill.description,
                style: const TextStyle(
                  color: AppColors.sketchGray,
                  fontSize: 10,
                  height: 1.35,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ));
  }
}
