import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colosynth/game_data/character_type.dart';
import 'package:colosynth/providers/battle_provider.dart';
import 'package:colosynth/providers/save_provider.dart';
import 'package:colosynth/screens/theme/tokens.dart';
import 'package:colosynth/screens/character/character_misc.dart';
import 'package:colosynth/database/character/character_equipment_slot.dart';
import 'package:colosynth/growth/equipment/equipment_progression.dart';

export 'package:colosynth/screens/character/synths_panel.dart';

class CharacterEquipmentPanel extends ConsumerWidget {
  const CharacterEquipmentPanel({super.key, required this.character});
  final CharacterData character;

  static const List<_SlotDef> _slots = [
    _SlotDef(key: 'weapon', icon: Icons.military_tech),
    _SlotDef(key: 'shield', icon: Icons.shield_outlined),
    _SlotDef(key: 'armor', icon: Icons.accessibility_new),
    _SlotDef(key: 'helmet', icon: Icons.face),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(battleStatsProvider);
    final stats = statsAsync.value;
    if (stats == null) return const Center(child: CircularProgressIndicator());

    final charEquip = ref.watch(charEquipmentProvider(character.id));
    final ink = ref.watch(inkProvider);
    final paint = ref.watch(paintProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const PopArtLabel(label: 'EQUIPMENT', accent: AppColors.ink),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: _slots.map((slotDef) {
              final slotData = charEquip[slotDef.key] ??
                  const CharacterEquipmentSlot(
                      level: 1, xp: 0, breakthroughCount: 0);
              final level = slotData.level;
              final bt = slotData.breakthroughCount;

              final cap = EquipmentProgression.levelCapForBreakthrough(bt);
              final canUpgrade = level < cap;
              final canBreakthrough = level >= cap && bt < 2;

              final upgradeCost = EquipmentProgression.upgradeCost(level);
              final btCost =
                  EquipmentProgression.breakthroughPaintCost(bt + 1);

              final mult =
                  EquipmentProgression.calculateMultiplier(bt, level);

              final bool hasEnoughInk = ink >= upgradeCost;
              final bool hasEnoughPaint = paint >= btCost;

              return Padding(
                padding:
                    EdgeInsets.only(right: slotDef != _slots.last ? 10 : 0),
                child: _EquipmentSlot(
                  slotKey: slotDef.key,
                  fallbackIcon: slotDef.icon,
                  level: level,
                  multiplier: mult,
                  canUpgrade: canUpgrade,
                  canBreakthrough: canBreakthrough,
                  upgradeCost: upgradeCost,
                  breakthroughCost: btCost,
                  hasEnoughInk: hasEnoughInk,
                  hasEnoughPaint: hasEnoughPaint,
                  accentColor: AppColors.ink,
                  onUpgrade: canUpgrade
                      ? () {
                          if (hasEnoughInk) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              ref
                                  .read(equipmentLevelsProvider.notifier)
                                  .upgrade(character.id, slotDef.key);
                            });
                          }
                        }
                      : (canBreakthrough
                          ? () {
                              if (hasEnoughPaint) {
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  ref
                                      .read(equipmentLevelsProvider.notifier)
                                      .breakthrough(character.id, slotDef.key);
                                });
                              }
                            }
                          : null),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SlotDef {
  const _SlotDef({required this.key, required this.icon});
  final String key;
  final IconData icon;
}

class _EquipmentSlot extends StatefulWidget {
  const _EquipmentSlot({
    required this.slotKey,
    required this.fallbackIcon,
    required this.level,
    required this.multiplier,
    required this.canUpgrade,
    required this.canBreakthrough,
    required this.upgradeCost,
    required this.breakthroughCost,
    required this.hasEnoughInk,
    required this.hasEnoughPaint,
    required this.accentColor,
    required this.onUpgrade,
  });

  final String slotKey;
  final IconData fallbackIcon;
  final int level;
  final double multiplier;
  final bool canUpgrade;
  final bool canBreakthrough;
  final int upgradeCost;
  final int breakthroughCost;
  final bool hasEnoughInk;
  final bool hasEnoughPaint;
  final Color accentColor;
  final VoidCallback? onUpgrade;

  @override
  State<_EquipmentSlot> createState() => _EquipmentSlotState();
}

class _EquipmentSlotState extends State<_EquipmentSlot> {
  OverlayEntry? _tooltipEntry;
  Timer? _tooltipTimer;

  @override
  void dispose() {
    _removeTooltip();
    super.dispose();
  }

  void _removeTooltip() {
    _tooltipTimer?.cancel();
    _tooltipTimer = null;
    if (_tooltipEntry != null) {
      try {
        _tooltipEntry!.remove();
      } catch (_) {}
      _tooltipEntry = null;
    }
  }

  void _showUpgradeTooltip(BuildContext context) {
    _removeTooltip();

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final position = renderBox.localToGlobal(Offset.zero);

    String tooltipText = '';
    bool isAvailable = false;
    if (widget.canUpgrade) {
      tooltipText = widget.hasEnoughInk
          ? 'TAP TO UPGRADE  ${widget.upgradeCost}I'
          : 'NEED ${widget.upgradeCost}I';
      isAvailable = widget.hasEnoughInk;
    } else if (widget.canBreakthrough) {
      tooltipText = widget.hasEnoughPaint
          ? 'TAP BREAKTHROUGH  ${widget.breakthroughCost}P'
          : 'NEED ${widget.breakthroughCost}P';
      isAvailable = widget.hasEnoughPaint;
    } else {
      tooltipText = 'MAX LEVEL';
    }

    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: position.dx - 28,
        top: position.dy - 52,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.paperWhite,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                  color: widget.accentColor.withValues(alpha: 0.50), width: 1),
            ),
            child: Text(
              tooltipText,
              style: TextStyle(
                color: isAvailable
                    ? AppColors.ink
                    : AppColors.ink.withValues(alpha: 0.4),
                fontSize: 9,
                fontFamily: 'Bangers',
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ),
    );

    _tooltipEntry = entry;
    overlay.insert(entry);

    _tooltipTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        _removeTooltip();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool showActionIndicator =
        widget.canUpgrade || widget.canBreakthrough;
    final bool hasEnoughResource = widget.canUpgrade
        ? widget.hasEnoughInk
        : (widget.canBreakthrough ? widget.hasEnoughPaint : false);

    return GestureDetector(
      onTap: widget.onUpgrade,
      onLongPress: () => _showUpgradeTooltip(context),
      child: SizedBox(
        width: 44,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.paperWhite.withValues(alpha: 0.8),
                    border: Border.all(
                      color: widget.accentColor.withValues(alpha: 0.45),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Center(
                    child: Icon(widget.fallbackIcon,
                        color: widget.accentColor, size: 22),
                  ),
                ),
                if (widget.level > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: widget.accentColor,
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: widget.accentColor.withValues(alpha: 0.50),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        '+${widget.level}',
                        style: const TextStyle(
                          color: AppColors.paperWhite,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Bangers',
                        ),
                      ),
                    ),
                  ),
                if (showActionIndicator && widget.onUpgrade != null)
                  Positioned(
                    left: -4,
                    bottom: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 3, vertical: 1),
                      decoration: BoxDecoration(
                        color: hasEnoughResource
                            ? (widget.canBreakthrough
                                ? const Color(0xFFFF9800)
                                : widget.accentColor.withValues(alpha: 0.90))
                            : Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Icon(
                        widget.canBreakthrough
                            ? Icons.star
                            : Icons.arrow_upward,
                        size: 8,
                        color: hasEnoughResource
                            ? AppColors.paperWhite
                            : AppColors.ink.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              '×${widget.multiplier.toStringAsFixed(1)}',
              style: TextStyle(
                color: widget.accentColor.withValues(alpha: 0.55),
                fontSize: 8,
                fontFamily: 'Bangers',
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
