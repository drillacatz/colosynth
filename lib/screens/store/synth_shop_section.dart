import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colosynth/providers/save_provider.dart';
import 'package:colosynth/database/synth/synth_instance.dart';
import 'package:colosynth/screens/theme/tokens.dart';
import 'package:colosynth/screens/overlays/locked_feature_overlay.dart';


/// Shows the one-time 199P purchase to unlock Synth Slot 3.
/// Visible only when Tier 1 is cleared (Slot 2 unlocked) and Slot 3 is NOT yet purchased.
class SynthSlot3Section extends ConsumerWidget {
  const SynthSlot3Section({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlockState = ref.watch(synthSlotUnlockStateProvider);
    final slot2Unlocked = unlockState.isUnlocked(1);
    final slot3Unlocked = unlockState.isUnlocked(2);
    final paint = ref.watch(paintProvider);

    if (!slot2Unlocked) return const SizedBox.shrink();
    if (slot3Unlocked) {
      return _Slot3OwnedBadge();
    }

    final canAfford = paint >= 199;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SynthShopHeader(
          title: 'SYNTH SLOT 3',
          subtitle: 'Equip a third Synth to your active loadout',
          icon: Icons.add_box_outlined,
          color: Color(0xFF7C4DFF),
        ),
        const SizedBox(height: 12),
        _PurchaseCard(
          label: 'UNLOCK SLOT 3',
          cost: 199,
          costIcon: Icons.brush,
          costColor: const Color(0xFFE91E63),
          canAfford: canAfford,
          currentPaint: paint,
          onPurchase: () => _handleUnlock(context, ref),
        ),
      ],
    );
  }

  Future<void> _handleUnlock(BuildContext context, WidgetRef ref) async {
    final success = await ref
        .read(gameplaySaveNotifierProvider.notifier)
        .unlockSynthSlot3();

    if (!context.mounted) return;
    unawaited(LockedFeatureOverlay.show(
      context,
      customTitle: success ? 'Slot Unlocked' : 'Unlock Failed',
      customDescription: success
          ? 'Synth Slot 3 is now fully unlocked and ready to use!'
          : 'Not enough Paint or Slot 2 is not cleared/unlocked.',
      customConditionText: success ? 'Unlocked!' : 'Error',
      customEmoji: success ? '✓' : '❌',
    ));
  }
}

class _Slot3OwnedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF7C4DFF).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF7C4DFF).withValues(alpha: 0.30)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle, color: Color(0xFF7C4DFF), size: 18),
          SizedBox(width: 10),
          Text(
            'SYNTH SLOT 3 — UNLOCKED',
            style: TextStyle(
              fontFamily: 'Bangers',
              fontSize: 14,
              letterSpacing: 2,
              color: Color(0xFF7C4DFF),
            ),
          ),
        ],
      ),
    );
  }
}


/// Shows the player's Synth Key count and an OPEN button that spends 1 key.
class SynthCrateSection extends ConsumerStatefulWidget {
  const SynthCrateSection({super.key});

  @override
  ConsumerState<SynthCrateSection> createState() => _SynthCrateSectionState();
}

class _SynthCrateSectionState extends ConsumerState<SynthCrateSection> {
  bool _opening = false;

  Future<void> _openCrate() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final result =
          await ref.read(ownedSynthInstancesProvider.notifier).openCrate();
      if (mounted) {
        setState(() {
          _opening = false;
        });
        if (result == null) {
          unawaited(LockedFeatureOverlay.show(
            context,
            customTitle: 'No Synth Keys',
            customDescription: 'Clear tournament stages to earn keys and unlock powerful Synths!',
            customConditionText: 'Clear Stages',
            customEmoji: '🔑',
          ));
        } else {
          _showResultDialog(result);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _opening = false);
    }
  }

  void _showResultDialog(({SynthInstance instance, bool isDuplicate}) result) {
    showDialog<void>(
      context: context,
      builder: (_) => _CrateResultDialog(result: result),
    );
  }

  Future<void> _buyKeyWithPaint() async {
    final wallet = ref.read(walletProvider);
    if (!wallet.canAfford(Currency.paint, 50)) {
      unawaited(LockedFeatureOverlay.show(
        context,
        customTitle: 'Not Enough Paint',
        customDescription: 'You need 50 Paint to purchase 1 Synth Key.',
        customConditionText: '50 Paint Required',
        customEmoji: '🎨',
      ));
      return;
    }

    await ref
        .read(walletProvider.notifier)
        .spend(Currency.paint, 50, reason: 'synth_key_purchase');

    await ref.read(synthKeysProvider.notifier).award(1);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchased 1 Synth Key!'),
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xFFFF6D00),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final keys = ref.watch(synthKeysProvider);
    final paint = ref.watch(paintProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SynthShopHeader(
          title: 'SYNTH CRATE',
          subtitle: 'Open a crate with 1 Synth Key to receive a random Synth',
          icon: Icons.all_inbox_outlined,
          color: Color(0xFFFF6D00),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFFCC02).withValues(alpha: 0.40)),
          ),
          child: Row(
            children: [
              const Icon(Icons.vpn_key_outlined,
                  color: Color(0xFFFF8F00), size: 20),
              const SizedBox(width: 10),
              const Text(
                'SYNTH KEYS',
                style: TextStyle(
                  fontFamily: 'Bangers',
                  fontSize: 13,
                  letterSpacing: 2,
                  color: Color(0xFF1A0E00),
                ),
              ),
              const Spacer(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  '$keys',
                  key: ValueKey(keys),
                  style: const TextStyle(
                    fontFamily: 'Bangers',
                    fontSize: 22,
                    color: Color(0xFFFF8F00),
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: keys > 0 && !_opening ? _openCrate : null,
          child: AnimatedOpacity(
            opacity: keys > 0 && !_opening ? 1.0 : 0.38,
            duration: const Duration(milliseconds: 200),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6D00),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6D00).withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: _opening
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'OPEN CRATE  (×1 KEY)',
                        style: TextStyle(
                          fontFamily: 'Bangers',
                          fontSize: 16,
                          letterSpacing: 3,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ).animate(target: keys > 0 && !_opening ? 1 : 0).shimmer(
              duration: 1800.ms,
              delay: 600.ms,
              color: Colors.white24,
            ),
        const SizedBox(height: 12),
        _PaintToKeyCard(
          price: 50,
          currentPaint: paint,
          onBuy: _buyKeyWithPaint,
        ),
        const SizedBox(height: 8),
        Text(
          'Earn 1 key per stage first-clear or exchange 50 Paint. ${keys == 0 ? "Clear more stages!" : ""}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: const Color(0xFF888888).withValues(alpha: 0.70),
          ),
        ),
      ],
    );
  }
}

class _PaintToKeyCard extends StatelessWidget {
  const _PaintToKeyCard({
    required this.price,
    required this.currentPaint,
    required this.onBuy,
  });

  final int price;
  final int currentPaint;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final canAfford = currentPaint >= price;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1B0E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: canAfford
              ? const Color(0xFFFF6D00).withValues(alpha: 0.5)
              : Colors.white12,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.brush, color: Color(0xFFE91E63), size: 18),
          const SizedBox(width: 8),
          Text(
            'BUY 1 KEY  ($price PAINT)',
            style: const TextStyle(
              fontFamily: 'Bangers',
              fontSize: 13,
              letterSpacing: 1.5,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: canAfford ? onBuy : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6D00),
              disabledBackgroundColor: Colors.grey.shade800,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(60, 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text(
              'EXCHANGE',
              style: TextStyle(
                fontFamily: 'Bangers',
                fontSize: 12,
                letterSpacing: 1,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _SynthShopHeader extends StatelessWidget {
  const _SynthShopHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Bangers',
                  fontSize: 16,
                  letterSpacing: 2,
                  color: color,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: const Color(0xFF888888).withValues(alpha: 0.80),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PurchaseCard extends StatelessWidget {
  const _PurchaseCard({
    required this.label,
    required this.cost,
    required this.costIcon,
    required this.costColor,
    required this.canAfford,
    required this.currentPaint,
    required this.onPurchase,
  });

  final String label;
  final int cost;
  final IconData costIcon;
  final Color costColor;
  final bool canAfford;
  final int currentPaint;
  final VoidCallback onPurchase;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canAfford
          ? () {
              ComicButton.playButtonSfx();
              onPurchase();
            }
          : null,
      child: AnimatedOpacity(
        opacity: canAfford ? 1.0 : 0.55,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: canAfford
                ? const Color(0xFF7C4DFF).withValues(alpha: 0.08)
                : const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: canAfford
                  ? const Color(0xFF7C4DFF).withValues(alpha: 0.35)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Bangers',
                  fontSize: 15,
                  letterSpacing: 1.5,
                  color: Color(0xFF1A0E00),
                ),
              ),
              const Spacer(),
              Icon(costIcon, color: costColor, size: 14),
              const SizedBox(width: 4),
              Text(
                '$cost P',
                style: TextStyle(
                  fontFamily: 'Bangers',
                  fontSize: 16,
                  color: canAfford ? costColor : Colors.grey,
                  letterSpacing: 1,
                ),
              ),
              if (!canAfford) ...[
                const SizedBox(width: 8),
                Text(
                  '($currentPaint/$cost)',
                  style: const TextStyle(fontSize: 9, color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


class _CrateResultDialog extends StatelessWidget {
  const _CrateResultDialog({required this.result});
  final ({SynthInstance instance, bool isDuplicate}) result;

  @override
  Widget build(BuildContext context) {
    final isDupe = result.isDuplicate;
    return Dialog(
      backgroundColor: const Color(0xFF1A0E00),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isDupe ? Icons.autorenew : Icons.auto_awesome,
              color: isDupe ? const Color(0xFF00E5FF) : const Color(0xFFFF6D00),
              size: 48,
            )
                .animate()
                .scale(
                  begin: const Offset(0, 0),
                  duration: 400.ms,
                  curve: Curves.elasticOut,
                )
                .fadeIn(duration: 200.ms),
            const SizedBox(height: 16),
            Text(
              isDupe ? 'DUPLICATE!' : 'NEW SYNTH!',
              style: TextStyle(
                fontFamily: 'Bangers',
                fontSize: 24,
                letterSpacing: 4,
                color: isDupe
                    ? const Color(0xFF00E5FF)
                    : const Color(0xFFFF6D00),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isDupe
                  ? 'Converted to\n1× exp_note_legendary'
                  : 'Added to your Synth collection!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.70),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'CLOSE',
                style: TextStyle(
                  fontFamily: 'Bangers',
                  color: Colors.white54,
                  fontSize: 14,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
