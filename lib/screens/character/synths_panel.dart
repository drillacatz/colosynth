import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';

import 'package:colosynth/game/logic/direction.dart';
import 'package:colosynth/game_data/character_type.dart';
import 'package:colosynth/providers/save_provider.dart';
import 'package:colosynth/providers/tournament_provider.dart';
import 'package:colosynth/screens/theme/tokens.dart';
import 'package:colosynth/screens/character/character_misc.dart';
import 'package:colosynth/screens/overlays/locked_feature_overlay.dart';
import 'package:colosynth/database/synth/synth_definition.dart';
import 'package:colosynth/database/synth/synth_instance.dart';

class CharacterSynthsPanel extends ConsumerWidget {
  const CharacterSynthsPanel({super.key, required this.character});
  final CharacterData character;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final synthSlots = ref.watch(equippedCharSynthSlotsProvider);
    final synthLevels = ref.watch(synthSlotLevelsProvider);
    final unlockState = ref.watch(synthSlotUnlockStateProvider);
    final ownedSynths = ref.watch(ownedSynthInstancesProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const PopArtLabel(label: 'EQUIPPED SYNTHS', accent: AppColors.ink),
          const SizedBox(height: 8),
          ...List.generate(4, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _VerticalSynthCard(
                slotIndex: i,
                isUnlocked: unlockState.isUnlocked(i),
                instanceId: i < synthSlots.length ? synthSlots[i] : null,
                level: synthLevels[i] ?? 1,
                characterId: character.id,
                ownedSynths: ownedSynths,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _VerticalSynthCard extends ConsumerWidget {
  const _VerticalSynthCard({
    required this.slotIndex,
    required this.isUnlocked,
    required this.instanceId,
    required this.level,
    required this.characterId,
    required this.ownedSynths,
  });

  final int slotIndex;
  final bool isUnlocked;
  final String? instanceId;
  final int level;
  final String characterId;
  final Map<String, SynthInstance> ownedSynths;

  Future<void> _handleLockedTap(BuildContext context, WidgetRef ref) async {
    unawaited(HapticFeedback.lightImpact());
    if (slotIndex == 2) {
      final tournamentProgress = ref.read(tournamentProgressProvider);
      final isTier1Cleared =
          tournamentProgress.containsKey('tier_1_cleared');
      if (!isTier1Cleared) {
        unawaited(LockedFeatureOverlay.show(
          context,
          customTitle: 'Slot Locked',
          customDescription:
              'Clear Tier 1 of the tournament to enable purchasing Slot 3.',
          customConditionText: 'Clear Tier 1',
          customEmoji: '🔒',
        ));
        return;
      }
      final paint = ref.read(paintProvider);
      if (paint < 199) {
        unawaited(LockedFeatureOverlay.show(
          context,
          customTitle: 'Insufficient Paint',
          customDescription:
              'Unlocking this slot requires 199 Paint. You currently have $paint Paint.',
          customConditionText: 'Need 199 Paint',
          customEmoji: '🎨',
        ));
        return;
      }

      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.paperWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.ink, width: 2),
          ),
          title: const Text(
            'UNLOCK SYNTH SLOT 3',
            style: TextStyle(fontFamily: 'Bangers', letterSpacing: 1.5),
          ),
          content: const Text(
            'Spend 199 Paint to unlock the third Synth slot?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('CANCEL',
                  style: TextStyle(
                      fontFamily: 'Bangers', color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('UNLOCK',
                  style: TextStyle(
                      fontFamily: 'Bangers', color: AppColors.comicBlue)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        final success = await ref
            .read(gameplaySaveNotifierProvider.notifier)
            .unlockSynthSlot3();
        if (context.mounted) {
          unawaited(LockedFeatureOverlay.show(
            context,
            customTitle: success ? 'Slot Unlocked' : 'Unlock Failed',
            customDescription: success
                ? 'Synth Slot 3 is now fully unlocked and ready to use!'
                : 'There was an issue unlocking the slot.',
            customConditionText: success ? 'Unlocked!' : 'Error',
            customEmoji: success ? '✓' : '❌',
          ));
        }
      }
    } else {
      if (slotIndex == 1) {
        unawaited(LockedFeatureOverlay.show(
          context,
          customTitle: 'Slot Locked',
          customDescription:
              'Clear Tier 1 of the tournament to unlock the second Synth slot.',
          customConditionText: 'Clear Tier 1',
          customEmoji: '🔒',
        ));
      } else if (slotIndex == 3) {
        unawaited(LockedFeatureOverlay.show(
          context,
          customTitle: 'Slot Locked',
          customDescription:
              'Reach Character Level 50 to unlock the fourth Synth slot.',
          customConditionText: 'Reach Lv. 50',
          customEmoji: '🔒',
        ));
      } else {
        unawaited(LockedFeatureOverlay.show(
          context,
          customTitle: 'Slot Locked',
          customDescription: 'This slot is currently locked.',
          customConditionText: 'Locked',
          customEmoji: '🔒',
        ));
      }
    }
  }

  void _showSynthSelectionSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.paperWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return _SynthSelectionSheet(
          slotIndex: slotIndex,
          characterId: characterId,
          instanceId: instanceId,
          ownedSynths: ownedSynths,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isUnlocked) {
      String lockCondition = '';
      if (slotIndex == 1) lockCondition = 'CLEAR TIER 1';
      if (slotIndex == 2) lockCondition = '199 PAINT';
      if (slotIndex == 3) lockCondition = 'REACH LV.50';

      return GestureDetector(
        onTap: () => _handleLockedTap(context, ref),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.sketchGray.withValues(alpha: 0.12),
            border: Border.all(
              color: AppColors.ink.withValues(alpha: 0.2),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.ink.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: AppColors.sketchGray,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SLOT ${slotIndex + 1} — LOCKED',
                      style: const TextStyle(
                        color: AppColors.sketchGray,
                        fontFamily: 'Bangers',
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                    if (lockCondition.isNotEmpty)
                      Text(
                        'REQ: $lockCondition',
                        style: TextStyle(
                          color: AppColors.ink.withValues(alpha: 0.45),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.ink.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppColors.ink.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: const Text(
                  'LOCKED',
                  style: TextStyle(
                    fontFamily: 'Bangers',
                    fontSize: 9,
                    color: AppColors.sketchGray,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final instance = instanceId != null ? ownedSynths[instanceId] : null;
    final definition = instance != null
        ? globalSynthDefinitions
            .firstWhereOrNull((d) => d.id == instance.definitionId)
        : null;

    if (definition == null) {
      return GestureDetector(
        onTap: () {
          ComicButton.playButtonSfx();
          HapticFeedback.selectionClick();
          _showSynthSelectionSheet(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.paperWhite,
            border: Border.all(
              color: AppColors.ink.withValues(alpha: 0.25),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.ink.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  color: AppColors.ink,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'SLOT ${slotIndex + 1} — EMPTY',
                  style: const TextStyle(
                    color: AppColors.sketchGray,
                    fontFamily: 'Bangers',
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.comicBlue,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.ink, width: 1.2),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.ink,
                      offset: Offset(1.5, 1.5),
                    ),
                  ],
                ),
                child: const Text(
                  'EQUIP',
                  style: TextStyle(
                    fontFamily: 'Bangers',
                    fontSize: 10,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        ComicButton.playButtonSfx();
        HapticFeedback.selectionClick();
        _showSynthSelectionSheet(context);
      },
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: AppColors.paperWhite,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.ink, width: 1.8),
          boxShadow: const [
            BoxShadow(
              color: AppColors.ink,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C4DFF).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.hub,
                    color: Color(0xFF7C4DFF),
                    size: 15,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        'SLOT ${slotIndex + 1}: ',
                        style: const TextStyle(
                          color: AppColors.sketchGray,
                          fontFamily: 'Bangers',
                          fontSize: 11,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          definition.name.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontFamily: 'Bangers',
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C4DFF),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    '+$level',
                    style: const TextStyle(
                      color: AppColors.paperWhite,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Bangers',
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.swap_horiz,
                  size: 16,
                  color: AppColors.ink,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                // Direction sequence displayed horizontally
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final dir in definition.effectiveSequence) ...[
                      _DirectionBadge(direction: dir),
                      const SizedBox(width: 3),
                    ],
                  ],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'STM: ${definition.counterStaminaDamage} | ×${definition.bonusDamageMult.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontFamily: 'Bangers',
                      fontSize: 10,
                      color: AppColors.ink.withValues(alpha: 0.65),
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
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

class _DirectionBadge extends StatelessWidget {
  const _DirectionBadge({required this.direction});
  final AttackDirection direction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: AppColors.paperWhite,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: AppColors.ink, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.ink,
            offset: Offset(1, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          direction.arrow,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

class _SynthSelectionSheet extends ConsumerWidget {
  const _SynthSelectionSheet({
    required this.slotIndex,
    required this.characterId,
    required this.instanceId,
    required this.ownedSynths,
  });

  final int slotIndex;
  final String characterId;
  final String? instanceId;
  final Map<String, SynthInstance> ownedSynths;

  String? _equippedChar(String instId, Map<String, List<String?>> charSynths) {
    for (final e in charSynths.entries) {
      if (e.value.contains(instId)) return e.key;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allOwned = ownedSynths.values.toList();
    final saveState = ref.watch(gameplaySaveNotifierProvider);
    final charSynths = saveState.characterSynths;

    allOwned.sort((a, b) {
      final aEquippedChar = _equippedChar(a.instanceId, charSynths);
      final bEquippedChar = _equippedChar(b.instanceId, charSynths);

      if (aEquippedChar == characterId && bEquippedChar != characterId) {
        return -1;
      }
      if (bEquippedChar == characterId && aEquippedChar != characterId) {
        return 1;
      }

      if (aEquippedChar == null && bEquippedChar != null) return -1;
      if (bEquippedChar == null && aEquippedChar != null) return 1;

      return a.definitionId.compareTo(b.definitionId);
    });

    final currentEquipped =
        charSynths[characterId] ?? List<String?>.filled(4, null);
    final currentEquippedCount =
        currentEquipped.where((id) => id != null).length;
    final canUnequip = currentEquippedCount > 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paperWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: AppColors.ink, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SELECT SYNTH — SLOT ${slotIndex + 1}',
                style: const TextStyle(
                  fontFamily: 'Bangers',
                  fontSize: 18,
                  letterSpacing: 1.5,
                  color: AppColors.ink,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(color: AppColors.ink, thickness: 1.5),
          const SizedBox(height: 8),
          Expanded(
            child: allOwned.isEmpty
                ? const Center(
                    child: Text(
                      'NO SYNTHS OWNED\nOPEN CRATES IN THE STORE!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: 'Bangers',
                          fontSize: 14,
                          color: AppColors.sketchGray),
                    ),
                  )
                : ListView.builder(
                    itemCount: allOwned.length,
                    itemBuilder: (context, idx) {
                      final inst = allOwned[idx];
                      final def = globalSynthDefinitions
                          .firstWhereOrNull((d) => d.id == inst.definitionId);
                      if (def == null) return const SizedBox.shrink();

                      final eqChar = _equippedChar(inst.instanceId, charSynths);
                      final isCurrentSlot = inst.instanceId == instanceId;

                      String statusText = 'FREE';
                      Color statusColor = AppColors.sketchGray;
                      if (eqChar == characterId) {
                        final sIdx =
                            charSynths[characterId]!.indexOf(inst.instanceId);
                        statusText = 'EQUIPPED (SLOT ${sIdx + 1})';
                        statusColor = AppColors.comicBlue;
                      } else if (eqChar != null) {
                        statusText = 'EQUIPPED (${eqChar.toUpperCase()})';
                        statusColor = const Color(0xFFFF9800);
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isCurrentSlot
                              ? const Color(0xFFE8EAF6)
                              : AppColors.paperWhite,
                          border: Border.all(
                            color: isCurrentSlot
                                ? const Color(0xFF7C4DFF)
                                : AppColors.ink.withValues(alpha: 0.15),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF7C4DFF)
                                    .withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.hub,
                                  color: Color(0xFF7C4DFF), size: 16),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    def.name.toUpperCase(),
                                    style: const TextStyle(
                                      fontFamily: 'Bangers',
                                      fontSize: 12,
                                      letterSpacing: 1,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  // Horizontal direction sequence in selection sheet
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      for (final dir in def.effectiveSequence) ...[
                                        _DirectionBadge(direction: dir),
                                        const SizedBox(width: 2),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'STAMINA DMG: ${def.counterStaminaDamage} | MULT: ${def.bonusDamageMult}x',
                                    style: const TextStyle(
                                        fontSize: 9,
                                        color: AppColors.sketchGray),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    statusText,
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                      color: statusColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (isCurrentSlot)
                              GestureDetector(
                                onTap: () async {
                                  if (!canUnequip) {
                                    unawaited(LockedFeatureOverlay.show(
                                      context,
                                      customTitle: 'Cannot Unequip',
                                      customDescription:
                                          'Characters must have at least 1 Synth equipped at all times!',
                                      customConditionText:
                                          'At least 1 Synth required',
                                      customEmoji: '⚠️',
                                    ));
                                    return;
                                  }
                                  ComicButton.playButtonSfx();
                                  unawaited(HapticFeedback.mediumImpact());
                                  await ref
                                      .read(
                                          gameplaySaveNotifierProvider.notifier)
                                      .unequipSynth(
                                        characterId: characterId,
                                        slotIndex: slotIndex,
                                      );
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF8A80),
                                    border: Border.all(
                                        color: AppColors.ink, width: 1.5),
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: const [
                                      BoxShadow(
                                          color: AppColors.ink,
                                          offset: Offset(1.5, 1.5)),
                                    ],
                                  ),
                                  child: const Text(
                                    'UNEQUIP',
                                    style: TextStyle(
                                      fontFamily: 'Bangers',
                                      fontSize: 10,
                                      color: Colors.white,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              )
                            else
                              GestureDetector(
                                onTap: () async {
                                  ComicButton.playButtonSfx();
                                  unawaited(HapticFeedback.mediumImpact());
                                  await ref
                                      .read(
                                          gameplaySaveNotifierProvider.notifier)
                                      .equipSynth(
                                        characterId: characterId,
                                        instanceId: inst.instanceId,
                                        slotIndex: slotIndex,
                                      );
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.comicBlue,
                                    border: Border.all(
                                        color: AppColors.ink, width: 1.5),
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: const [
                                      BoxShadow(
                                          color: AppColors.ink,
                                          offset: Offset(1.5, 1.5)),
                                    ],
                                  ),
                                  child: const Text(
                                    'EQUIP',
                                    style: TextStyle(
                                      fontFamily: 'Bangers',
                                      fontSize: 10,
                                      color: Colors.white,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
