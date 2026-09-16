import 'dart:async';
import 'package:colosynth/services/remote_config_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colosynth/screens/theme/tokens.dart';
import 'package:colosynth/providers/save_provider.dart';
import 'package:colosynth/screens/upgrade/upgrade_notifier.dart';
import 'package:colosynth/screens/upgrade/upgrade_screen_logic.dart';
import 'package:colosynth/growth/equipment/equipment_progression.dart';




class StatChip extends StatelessWidget {
  const StatChip({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.70),
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              fontFamily: 'Bangers',
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}




class SlotCard extends StatelessWidget {
  const SlotCard({
    super.key,
    required this.slot,
    required this.itemId,
    required this.level,
    required this.isSelected,
    required this.isMaxed,
    required this.onTap,
  });

  final EquipmentSlotInfo slot;
  final String itemId;
  final int level;
  final bool isSelected;
  final bool isMaxed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? const Color(0xFF1A1A1A)
        : isMaxed
            ? const Color(0xFF00E5FF)
            : const Color(0xFFCCCCCC);

    final bgColor = isSelected
        ? const Color(0xFF1A1A1A).withValues(alpha: 0.06)
        : isMaxed
            ? const Color(0xFF00E5FF).withValues(alpha: 0.06)
            : const Color(0xFFFDFDFB);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2.0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF1A1A1A).withValues(alpha: 0.10)
                  : const Color(0xFFD0C8C0),
              offset: const Offset(2, 2),
              blurRadius: isSelected ? 4 : 0,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              slot.icon,
              size: 22,
              color:
                  isMaxed ? const Color(0xFF00E5FF) : const Color(0xFF555555),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: isMaxed
                    ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                    : const Color(0xFFF0EDE8),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                isMaxed ? 'MAX' : 'LV.$level',
                style: TextStyle(
                  color: isMaxed
                      ? const Color(0xFF00E5FF)
                      : const Color(0xFF666666),
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Bangers',
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}




class ItemDetailPanel extends StatelessWidget {
  final EquipmentSlotInfo slot;
  final String itemId;
  final int level;
  final String currentStatLabel;
  final String currentStatValue;
  final String nextStatValue;
  final int cost;
  final bool canUpgrade;
  final bool canBreakthrough;
  final bool isMaxed;
  final int ink;
  final int paint;
  final VoidCallback? onUpgrade;
  final VoidCallback? onBreakthrough;
  final String? requiredItem;
  final double xpProgress;

  const ItemDetailPanel({
    super.key,
    required this.slot,
    required this.itemId,
    required this.level,
    required this.currentStatLabel,
    required this.currentStatValue,
    required this.nextStatValue,
    required this.canUpgrade,
    required this.canBreakthrough,
    required this.isMaxed,
    required this.cost,
    required this.ink,
    required this.paint,
    required this.onUpgrade,
    required this.onBreakthrough,
    this.requiredItem,
    this.xpProgress = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFB),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF1A1A1A), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFD0C8C0),
            offset: Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isMaxed
                      ? const Color(0xFF00E5FF).withValues(alpha: 0.12)
                      : const Color(0xFFF0EDE8),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isMaxed
                        ? const Color(0xFF00E5FF)
                        : const Color(0xFFDDDDDD),
                  ),
                ),
                child: Icon(
                  slot.icon,
                  size: 20,
                  color: isMaxed
                      ? const Color(0xFF00E5FF)
                      : const Color(0xFF555555),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      margin: const EdgeInsets.only(bottom: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0EDE8),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: const Color(0xFFD0CCC7),
                        ),
                      ),
                      child: Text(
                        slot.label,
                        style: const TextStyle(
                          color: Color(0xFF888888),
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Bangers',
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    Text(
                      labelFromItemId(itemId),
                      style: const TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Bangers',
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      slot.description,
                      style: const TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 10,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (!isMaxed) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: xpProgress,
                backgroundColor: const Color(0xFFEEEEEE),
                 valueColor: AlwaysStoppedAnimation<Color>(
                    (requiredItem?.startsWith('exp_hammer') ?? false)
                        ? const Color(0xFF607D8B)
                        : (requiredItem?.startsWith('exp_note') ?? false)
                          ? const Color(0xFF00E5FF)
                            : const Color(0xFF00E5FF)),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              StatChip(
                label: 'CURRENT $currentStatLabel',
                value: currentStatValue,
                color: const Color(0xFF555555),
              ),
              if (!isMaxed) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 14,
                    color: Color(0xFF888888),
                  ),
                ),
                StatChip(
                  label: 'AFTER UPGRADE',
                  value: nextStatValue,
                  color: const Color(0xFF34C759),
                ),
              ],
              const Spacer(),
              if (!isMaxed && !canBreakthrough)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (requiredItem != null) ...[
                      Icon(
                        requiredItem!.startsWith('exp_hammer')
                            ? Icons.gavel
                            : requiredItem!.startsWith('exp_note')
                                ? Icons.note
                                : Icons.book,
                        size: 10,
                        color: const Color(0xFF1A1A1A),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '1×',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Icon(
                      Icons.water_drop,
                      size: 10,
                      color: ink >= cost
                          ? const Color(0xFF007AFF)
                          : const Color(0xFFFF3B30),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      formatResourceCost(cost),
                      style: TextStyle(
                        color: ink >= cost
                            ? const Color(0xFF007AFF)
                            : const Color(0xFFFF3B30),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Bangers',
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'INK',
                      style: TextStyle(
                        color: ink >= cost
                            ? const Color(0xFF007AFF).withValues(alpha: 0.60)
                            : const Color(0xFFFF3B30).withValues(alpha: 0.60),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              if (canBreakthrough)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.brush,
                      size: 10,
                      color: Color(0xFFE91E63),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${EquipmentProgression.breakthroughCost(slot.breakthroughCount)}',
                      style: TextStyle(
                        color: paint >= EquipmentProgression.breakthroughCost(slot.breakthroughCount)
                            ? const Color(0xFFE91E63)
                            : const Color(0xFFFF3B30),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Bangers',
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'PAINT',
                      style: TextStyle(
                        color: paint >= EquipmentProgression.breakthroughCost(slot.breakthroughCount)
                            ? const Color(0xFFE91E63).withValues(alpha: 0.60)
                            : const Color(0xFFFF3B30).withValues(alpha: 0.60),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: isMaxed
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.40),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'ULTIMATE LEVEL REACHED',
                        style: TextStyle(
                          color: Color(0xFF00E5FF),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Bangers',
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  )
                : canBreakthrough
                    ? GestureDetector(
                        onTap: onBreakthrough,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: paint >= EquipmentProgression.breakthroughCost(slot.breakthroughCount)
                                ? const Color(0xFFE91E63)
                                : const Color(0xFFE0DDD8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bolt,
                                size: 14,
                                color:
                                    paint >= EquipmentProgression.breakthroughCost(slot.breakthroughCount)
                                        ? Colors.white
                                        : const Color(0xFFAAAAAA),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                paint >= EquipmentProgression.breakthroughCost(slot.breakthroughCount)
                                    ? 'BREAKTHROUGH'
                                    : 'NOT ENOUGH PAINT',
                                style: TextStyle(
                                  color:
                                      paint >= EquipmentProgression.breakthroughCost(slot.breakthroughCount)
                                          ? Colors.white
                                          : const Color(0xFFAAAAAA),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Bangers',
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : GestureDetector(
                        onTap: onUpgrade,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: canUpgrade
                                ? const Color(0xFF1A1A1A)
                                : const Color(0xFFE0DDD8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_upward,
                                size: 14,
                                color: canUpgrade
                                    ? Colors.white
                                    : const Color(0xFFAAAAAA),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                canUpgrade
                                    ? 'UPGRADE TO LV.${level + 1}'
                                    : 'NOT ENOUGH INK',
                                style: TextStyle(
                                  color: canUpgrade
                                      ? Colors.white
                                      : const Color(0xFFAAAAAA),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Bangers',
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}




class ResetDialog extends StatelessWidget {
  const ResetDialog({
    super.key,
    required this.currentPaint,
    required this.resetCost,
    required this.onConfirm,
    required this.onCancel,
  });

  final int currentPaint;
  final int resetCost;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final canAfford = currentPaint >= resetCost;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFFDFDFB),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF1A1A1A), width: 2),
            boxShadow: const [
              BoxShadow(color: Color(0x55000000), offset: Offset(4, 4)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'RESET SKILL TREE?',
                style: TextStyle(
                  fontFamily: 'Bangers',
                  fontSize: 20,
                  letterSpacing: 2,
                  color: Color(0xFFFF3B30),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                canAfford
                    ? 'This will refund no ink.\nCosts $resetCost Paint.'
                    : 'Not enough Paint.\nYou have $currentPaint / $resetCost Paint.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: canAfford
                      ? const Color(0xFF666666)
                      : const Color(0xFFFF3B30),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ComicButton(
                      label: 'CANCEL',
                      style: PBStyle.dark,
                      onTap: onCancel,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ComicButton(
                      label: 'RESET',
                      style: PBStyle.white,
                      onTap: canAfford ? onConfirm : null,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}




class SkillTreeFooter extends ConsumerWidget {
  const SkillTreeFooter({super.key, required this.unlockedCount});

  final int unlockedCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paint = ref.watch(paintProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F2EE),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFCCCCCC)),
            ),
            child: Text(
              '$unlockedCount / ${kAllSkillNodes.length} NODES',
              style: const TextStyle(
                color: Color(0xFF666666),
                fontSize: 10,
                fontFamily: 'Bangers',
                letterSpacing: 1,
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () async {
              unawaited(HapticFeedback.mediumImpact());
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => ResetDialog(
                  currentPaint: paint,
                  resetCost: RemoteConfigService.instance.skillTreeResetPaint,
                  onConfirm: () => Navigator.pop(ctx, true),
                  onCancel: () => Navigator.pop(ctx, false),
                ),
              );
              if (confirm == true && context.mounted) {
                try {
                  await ref
                      .read(upgradeNotifierProvider.notifier)
                      .resetSkillTree();
                } catch (_) {}
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: paint >= RemoteConfigService.instance.skillTreeResetPaint
                    ? const Color(0xFFFFEEEE)
                    : const Color(0xFFF5F2EE),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color:
                      paint >= RemoteConfigService.instance.skillTreeResetPaint
                          ? const Color(0xFFFF3B30).withValues(alpha: 0.40)
                          : const Color(0xFFCCCCCC),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.refresh,
                    size: 12,
                    color: paint >= 20
                        ? const Color(0xFFFF3B30)
                        : const Color(0xFFAAAAAA),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'RESET  ${RemoteConfigService.instance.skillTreeResetPaint}P',
                    style: TextStyle(
                      color: paint >=
                              RemoteConfigService.instance.skillTreeResetPaint
                          ? const Color(0xFFFF3B30)
                          : const Color(0xFFAAAAAA),
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
      ),
    );
  }
}
