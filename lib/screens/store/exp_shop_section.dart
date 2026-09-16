import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colosynth/game_data/store_data.dart';
import 'package:colosynth/providers/save_provider.dart';
import 'package:colosynth/providers/store_provider.dart';
import 'package:colosynth/screens/overlays/claim_reward_overlay.dart';
import 'package:colosynth/screens/overlays/locked_feature_overlay.dart';
import 'package:colosynth/screens/theme/tokens.dart';
import 'package:colosynth/screens/store/shop_card.dart';

class ExpShopSection extends StatelessWidget {
  const ExpShopSection({super.key});

  @override
  Widget build(BuildContext context) {
    final bundles = StoreData.expItemBundles;
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.88,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: bundles.asMap().entries.map((entry) {
        final i = entry.key;
        final b = entry.value;
        return ExpBundleGridCard(bundle: b)
            .animate(delay: (i * 30).ms)
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.1, end: 0);
      }).toList(),
    );
  }
}

class ExpBundleGridCard extends ConsumerWidget {
  const ExpBundleGridCard({super.key, required this.bundle});

  final ExpItemBundle bundle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canAfford = bundle.usePaint
        ? ref.watch(paintProvider) >= bundle.cost
        : ref.watch(inkProvider) >= bundle.cost;

    return ShopCard(
      imagePath: bundle.assetPath,
      mainLabel: bundle.name,
      subLabel: '${bundle.cost} ${bundle.usePaint ? 'PAINT' : 'INK'}',
      highlighted: false,
      compact: true,
      dimmed: !canAfford,
      accentColor: bundle.usePaint ? const Color(0xFFFF4081) : const Color(0xFF00E5FF),
      onTap: () => _purchase(context, ref),
    );
  }

  void _purchase(BuildContext context, WidgetRef ref) async {
    ComicButton.playButtonSfx();
    unawaited(HapticFeedback.mediumImpact());

    final success = await ref.read(storeControllerProvider).buyExpItem(bundle);

    if (!context.mounted) return;

    if (success) {
      await ClaimRewardOverlay.show(
        context,
        inkReward: 0,
        paintReward: 0,
      );
      if (!context.mounted) return;
      unawaited(LockedFeatureOverlay.show(
        context,
        customTitle: 'Purchase Success',
        customDescription: 'Successfully purchased ${bundle.quantity}x ${bundle.name}!',
        customConditionText: 'Purchased',
        customEmoji: '🎉',
      ));
    } else {
      unawaited(LockedFeatureOverlay.show(
        context,
        customTitle: 'Insufficient Funds',
        customDescription: 'You do not have enough ${bundle.usePaint ? 'Paint' : 'Ink'} to purchase ${bundle.name}.',
        customConditionText: 'Cost: ${bundle.cost} ${bundle.usePaint ? 'Paint' : 'Ink'}',
        customEmoji: '❌',
      ));
    }
  }
}

