import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:colosynth/game_data/character_type.dart';
import 'package:colosynth/screens/theme/tokens.dart';
import 'package:colosynth/providers/save_provider.dart';

String _fmtNum(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return n.toString();
}

class CharacterDetailsColumn extends StatelessWidget {
  const CharacterDetailsColumn({
    super.key,
    required this.character,
    required this.level,
    required this.hp,
    required this.atk,
  });

  final CharacterData character;
  final int level;
  final int hp;
  final int atk;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          character.name.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            height: 1.0,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            fontFamily: 'Bangers',
          ),
        ),
        Text(
          'Lv $level',
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 24),
        _StatCard(
            label: 'HP', value: _fmtNum(hp), color: const Color(0xFF4CAF50)),
        const SizedBox(height: 12),
        _StatCard(
            label: 'ATK', value: _fmtNum(atk), color: const Color(0xFFE53935)),
        const SizedBox(height: 32),
        _SkillRow(
            skill: character.activeSkill,
            isPassive: false,
            color: AppColors.ink),
        const SizedBox(height: 16),
        _SkillRow(
            skill: character.passiveSkill,
            isPassive: true,
            color: AppColors.ink),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              fontFamily: 'Bangers',
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillRow extends StatelessWidget {
  const _SkillRow(
      {required this.skill, required this.isPassive, required this.color});
  final CharacterSkill skill;
  final bool isPassive;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.5), width: 1.2),
          ),
          child: Icon(skill.icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    skill.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      isPassive ? 'PASSIVE' : 'ACTIVE',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                skill.description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 10,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class EquipmentDetailsSection extends ConsumerWidget {
  const EquipmentDetailsSection({super.key});

  static const _gold = AppColors.ink;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final equipLevels = ref.watch(equipmentLevelsProvider);
    final weaponLvl = equipLevels['weapon']?.level ?? 1;
    final shieldLvl = equipLevels['shield']?.level ?? 1;
    final armorLvl = equipLevels['armor']?.level ?? 1;
    final helmetLvl = equipLevels['helmet']?.level ?? 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.inventory_2, color: _gold, size: 18),
            const SizedBox(width: 8),
            Text(
              'EQUIPMENT',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _EquipSlot(
            label: 'WEAPON',
            name: 'Starter Sword',
            level: weaponLvl,
            icon: Icons.military_tech),
        _EquipSlot(
            label: 'SHIELD',
            name: 'Wooden Buckler',
            level: shieldLvl,
            icon: Icons.shield_outlined),
        _EquipSlot(
            label: 'ARMOR',
            name: 'Linen Wrap',
            level: armorLvl,
            icon: Icons.accessibility_new),
        _EquipSlot(
            label: 'HELMET',
            name: 'Iron Cap',
            level: helmetLvl,
            icon: Icons.face),
      ],
    );
  }
}

class _EquipSlot extends StatelessWidget {
  const _EquipSlot({required this.label, required this.name, required this.level, required this.icon});
  final String label;
  final String name;
  final int level;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: Colors.white70, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  '$name +$level',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class ReadyQuadrantClipper extends CustomClipper<Path> {
  ReadyQuadrantClipper({
    required this.quadrant,
    required this.yDivisor,
    required this.xTopBase,
    required this.xBottomBase,
    required this.slantedWidth,
  });

  final int quadrant;
  final double yDivisor;
  final double xTopBase;
  final double xBottomBase;
  final double slantedWidth;

  @override
  Path getClip(Size size) {
    final path = Path();
    if (quadrant == 1) {
      path.lineTo(xTopBase + slantedWidth, 0);
      path.lineTo(xTopBase, yDivisor);
      path.lineTo(0, yDivisor);
    } else if (quadrant == 2) {
      path.moveTo(xTopBase + slantedWidth, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, yDivisor);
      path.lineTo(xTopBase, yDivisor);
    } else if (quadrant == 3) {
      path.moveTo(0, yDivisor);
      path.lineTo(xBottomBase + slantedWidth, yDivisor);
      path.lineTo(xBottomBase, size.height);
      path.lineTo(0, size.height);
    } else if (quadrant == 4) {
      path.moveTo(xBottomBase + slantedWidth, yDivisor);
      path.lineTo(size.width, yDivisor);
      path.lineTo(size.width, size.height);
      path.lineTo(xBottomBase, size.height);
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

class ReadyBackButton extends StatelessWidget {
  const ReadyBackButton({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.50),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.20),
            width: 1.5,
          ),
        ),
        child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
      ),
    );
  }
}

class EnemyBadge extends StatelessWidget {
  const EnemyBadge({
    super.key,
    required this.enemyName,
    required this.isBoss,
    required this.isExtreme,
    required this.tier,
  });
  final String enemyName;
  final bool isBoss;
  final bool isExtreme;
  final int tier;

  @override
  Widget build(BuildContext context) {
    final accent = isExtreme
        ? const Color(0xFFFF4444)
        : isBoss
            ? const Color(0xFFFFAA00)
            : Colors.white;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isExtreme
                  ? 'EXTREME BOSS'
                  : isBoss
                      ? 'BOSS · T$tier'
                      : 'OPPONENT · T$tier',
              style: TextStyle(
                fontFamily: 'Bangers',
                fontSize: 9,
                letterSpacing: 3,
                color: accent.withValues(alpha: 0.70),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              enemyName.toUpperCase(),
              style: TextStyle(
                fontFamily: 'Bangers',
                fontSize: 16,
                letterSpacing: 2,
                color: Colors.white.withValues(alpha: 0.88),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class EnterBattleButton extends StatelessWidget {
  const EnterBattleButton({
    super.key,
    required this.isBoss,
    required this.isExtreme,
    required this.onTap,
  });

  final bool isBoss;
  final bool isExtreme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String label = isExtreme
        ? 'FACE THE EXTREME'
        : isBoss
            ? 'FIGHT BOSS'
            : 'ENTER BATTLE';

    return ComicButton(
      label: label,
      style: PBStyle.white,
      onTap: onTap,
      fontSize: 16,
      padding: const EdgeInsets.symmetric(vertical: 18),
    );
  }
}
