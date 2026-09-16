import 'dart:math' as math;
import 'package:colosynth/providers/exp_items_provider.dart';
import 'package:colosynth/providers/save_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colosynth/database/synth/synth_definition.dart';
import 'package:colosynth/providers/inventory_provider.dart';
import 'package:colosynth/screens/upgrade/upgrade_notifier.dart';

class InventoryView extends ConsumerWidget {
  const InventoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex =
        ref.watch(upgradeNotifierProvider.select((s) => s.selectedSlotIndex));
    final inventory = ref.watch(inventoryProvider);

    final upgradeItems = inventory.upgradeItems;

    final effectiveIndex = upgradeItems.isNotEmpty
        ? selectedIndex.clamp(0, upgradeItems.length - 1)
        : 0;
    final selectedItem =
        upgradeItems.isNotEmpty ? upgradeItems[effectiveIndex] : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Icon(Icons.inventory_2_outlined,
                  size: 16, color: Color(0xFF1A1A1A)),
              SizedBox(width: 8),
              Text(
                'INVENTORY (SYNTHS & ITEMS)',
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                  fontFamily: 'Bangers',
                ),
              ),
              SizedBox(width: 10),
              Expanded(child: Divider(color: Color(0xFFD0D0D0))),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                childAspectRatio: 0.85,
              ),
              itemCount: math.max(30, ((upgradeItems.length + 5) ~/ 6) * 6),
              itemBuilder: (context, i) {
                if (i < upgradeItems.length) {
                  final item = upgradeItems[i];
                  return _InventorySlot(
                    item: item,
                    isSelected: i == effectiveIndex,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref.read(upgradeNotifierProvider.notifier).selectSlot(i);
                    },
                  );
                }
                return _EmptySlot(index: i);
              },
            ),
          ),
        ),
        _DynamicDetailPanel(item: selectedItem),
      ],
    );
  }
}

class _InventorySlot extends ConsumerWidget {
  const _InventorySlot({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final InventoryItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String label = '';
    IconData icon = Icons.extension;
    Color color = const Color(0xFF00E5FF);
    int badgeCount = 0;

    switch (item.type) {
      case InventoryItemType.synth:
        final inst = item.synthInstance;
        final def = globalSynthDefinitions.firstWhere(
          (d) => d.id == inst?.definitionId,
          orElse: () => globalSynthDefinitions.first,
        );
        label = def.name.toUpperCase();
        icon = Icons.auto_awesome;
        color = const Color(0xFF00E5FF);
        badgeCount = inst?.level ?? 1;
        break;

      case InventoryItemType.key:
        label = 'KEY';
        icon = Icons.vpn_key_rounded;
        color = const Color(0xFF00E5FF);
        badgeCount = item.stackCount;
        break;

      case InventoryItemType.expItem:
        final parts = item.id.split('_');
        String baseName = 'EXP';
        String rarityTag = '';
        if (item.id.startsWith('exp_hammer')) {
          baseName = 'HAMMER';
          icon = Icons.gavel;
          color = const Color(0xFFFF8F00);
          if (parts.length > 2) rarityTag = ' (${parts[2].toUpperCase()})';
        } else if (item.id.startsWith('exp_note')) {
          baseName = 'NOTE';
          icon = Icons.note;
          color = const Color(0xFF00E5FF);
          if (parts.length > 2) rarityTag = ' (${parts[2].toUpperCase()})';
        } else if (item.id.startsWith('exp_book')) {
          baseName = 'BOOK';
          icon = Icons.book;
          color = const Color(0xFF8E24AA);
          if (parts.length > 2) rarityTag = ' (${parts[2].toUpperCase()})';
        } else {
          baseName = parts.isNotEmpty ? parts.last.toUpperCase() : 'ITEM';
          icon = Icons.inventory_2;
          color = const Color(0xFF00E5FF);
        }
        label = '$baseName$rarityTag';
        badgeCount = item.stackCount;
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.20)
              : const Color(0xFFF8F6F0),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFD8D4CF),
            width: isSelected ? 2.5 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 6,
                  ),
                ]
              : [],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22, color: isSelected ? color : Colors.black87),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Bangers',
                    fontSize: 8.5,
                    color: isSelected ? Colors.black : Colors.black54,
                  ),
                ),
              ],
            ),
            if (badgeCount > 0)
              Positioned(
                top: 3,
                right: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.type == InventoryItemType.synth
                        ? 'LV.$badgeCount'
                        : 'x$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 7.5,
                      fontWeight: FontWeight.bold,
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

class _DynamicDetailPanel extends ConsumerWidget {
  const _DynamicDetailPanel({required this.item});

  final InventoryItem? item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = this.item;
    if (item == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCCCCCC), width: 1.5),
        ),
        child: const Row(
          children: [
            Icon(Icons.inventory_2_outlined, size: 28, color: Colors.black38),
            SizedBox(width: 14),
            Text(
              'INVENTORY IS EMPTY',
              style: TextStyle(
                fontFamily: 'Bangers',
                fontSize: 16,
                color: Colors.black45,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      );
    }

    if (item.type == InventoryItemType.synth) {
      final inst = item.synthInstance;
      final def = globalSynthDefinitions.firstWhere(
        (d) => d.id == inst?.definitionId,
        orElse: () => globalSynthDefinitions.first,
      );

      final charSynths = ref.watch(
        gameplaySaveNotifierProvider.select((s) => s.characterSynths),
      );
      String? equippedChar;
      if (inst != null) {
        for (final entry in charSynths.entries) {
          if (entry.value.contains(inst.instanceId)) {
            equippedChar = entry.key;
            break;
          }
        }
      }
      final isEquipped = equippedChar != null;
      final charName = equippedChar?.toUpperCase() ?? 'NONE';

      return Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF00E5FF), width: 1.8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF00E5FF)),
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 32,
                color: Color(0xFF00E5FF),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        def.name.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Bangers',
                          fontSize: 18,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'LV.${inst?.level ?? 1}',
                          style: const TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Counter Stamina DMG: +${def.counterStaminaDamage}  •  DMG Mult: ${(def.bonusDamageMult * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        isEquipped ? Icons.check_circle : Icons.person_outline,
                        size: 12,
                        color: isEquipped
                            ? const Color(0xFF4CAF50)
                            : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isEquipped
                            ? 'EQUIPPED BY $charName'
                            : 'UNASSIGNED (AVAILABLE IN CHARACTER PANEL)',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: isEquipped
                              ? const Color(0xFF4CAF50)
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (item.type == InventoryItemType.key) {
      final keys = ref.watch(synthKeysProvider);

      return Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF00E5FF), width: 1.8),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF00E5FF)),
              ),
              child: const Icon(
                Icons.vpn_key_rounded,
                size: 30,
                color: Color(0xFFFF8F00),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'SYNTH CRATE KEY',
                    style: TextStyle(
                      fontFamily: 'Bangers',
                      fontSize: 18,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const Text(
                    'Used in the Store to unlock new Synth modules and abilities.',
                    style: TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'OWNED: $keys',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color(0xFFFF8F00),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      final qty = ref.watch(expItemsProvider)[item.id] ?? 0;
      final parts = item.id.split('_');
      String title = item.id.replaceAll('_', ' ').toUpperCase();
      String desc = 'Collectible progression resource.';
      IconData icon = Icons.inventory_2;
      Color color = const Color(0xFF00E5FF);

      final rarityTag = parts.length > 2 ? ' (${parts[2].toUpperCase()})' : '';

      if (item.id.startsWith('exp_hammer')) {
        title = 'EXP HAMMER$rarityTag';
        desc = 'Used for equipment upgrades in Character Equipment Panel.';
        icon = Icons.gavel;
        color = const Color(0xFFFF8F00);
      } else if (item.id.startsWith('exp_note')) {
        title = 'EXP NOTE$rarityTag';
        desc = 'Used for Synth leveling and upgrades.';
        icon = Icons.note;
        color = const Color(0xFF00E5FF);
      } else if (item.id.startsWith('exp_book')) {
        title = 'EXP BOOK$rarityTag';
        desc = 'Used for character level progression and breakthroughs.';
        icon = Icons.book;
        color = const Color(0xFF8E24AA);
      }

      return Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color),
              ),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Bangers',
                      fontSize: 18,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(desc, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text(
                    'OWNED: $qty',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0EDE8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD8D4CF), width: 1.2),
      ),
      child: const Center(
        child: Icon(Icons.lock_outline, size: 14, color: Color(0xFFCCCCCC)),
      ),
    );
  }
}
