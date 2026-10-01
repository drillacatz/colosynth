import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colosynth/game_data/store_data.dart';
import 'package:colosynth/providers/store_provider.dart';
import 'package:colosynth/services/iap_service.dart';
import 'package:colosynth/screens/overlays/claim_reward_overlay.dart';
import 'package:colosynth/screens/overlays/locked_feature_overlay.dart';
import 'package:colosynth/screens/theme/tokens.dart';
import 'package:colosynth/screens/store/shop_card.dart';

class InkShopSection extends StatelessWidget {
  const InkShopSection({super.key, required this.prices});

  final Map<String, String> prices;

  @override
  Widget build(BuildContext context) {
    final bundles = StoreData.inkBundles;
    return SizedBox(
      height: 140,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        children: [
          ...bundles.map((b) => Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox(
              width: 110,
              child: InkBundleGridCard(
                bundle: b,
                priceString: prices[b.productId] ?? b.usdFallback,
              ),
            ),
          )),
        ],
      ),
    );
  }
}


class InkBundleGridCard extends ConsumerWidget {
  const InkBundleGridCard({
    super.key,
    required this.bundle,
    required this.priceString,
  });

  final InkBundle bundle;
  final String priceString;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ShopCard(
      icon: Icons.water_drop,
      mainLabel: bundle.label,
      subLabel: priceString,
      highlighted: false,
      compact: true,
      accentColor: const Color(0xFF00B0FF),
      onTap: () => _purchase(context, ref),
    );
  }

  void _purchase(BuildContext context, WidgetRef ref) async {
    ComicButton.playButtonSfx();
    unawaited(HapticFeedback.mediumImpact());
    final result = await ref.read(storeControllerProvider).buyBundle(bundle.productId);
    if (!context.mounted) return;
    if (result is IapSuccess) {
      unawaited(ClaimRewardOverlay.show(
        context,
        title: 'PURCHASE SUCCESSFUL!',
        inkReward: bundle.ink,
      ));
    } else if (result is IapError) {
      unawaited(LockedFeatureOverlay.show(
        context,
        customTitle: 'Purchase Failed',
        customDescription: result.message,
        customConditionText: 'Purchase Error',
        customEmoji: '❌',
      ));
    }
  }
}

class AdFreeShopCard extends ConsumerWidget {
  const AdFreeShopCard({
    super.key,
    required this.prices,
    this.compact = true,
    this.isDeluxe = false,
  });

  final Map<String, String> prices;
  final bool compact;
  final bool isDeluxe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final basicBundle = StoreData.adFreeBundle;
    final deluxeBundle = StoreData.adFreeDeluxeBundle;
    final bundleId = isDeluxe ? deluxeBundle.productId : basicBundle.productId;
    final fallback = isDeluxe ? deluxeBundle.usdFallback : basicBundle.usdFallback;
    final label = isDeluxe ? 'AD FREE DELUXE' : 'AD FREE';
    final priceString = prices[bundleId] ?? fallback;
    final adFreeAsync = ref.watch(adFreeProvider);

    final isPurchased = adFreeAsync.value ?? false;

    return ShopCard(
      icon: isPurchased
          ? Icons.check_circle
          : (isDeluxe ? Icons.auto_awesome : Icons.stars_rounded),
      mainLabel: label,
      subLabel: isPurchased
          ? 'ACTIVE'
          : (isDeluxe ? '+88P & 8.8k INK  $priceString' : priceString),
      highlighted: !isPurchased && isDeluxe,
      compact: compact,
      dimmed: isPurchased,
      accentColor: isDeluxe ? const Color(0xFFFFD700) : const Color(0xFFFFAB00),
      badgeText: isPurchased ? 'ACTIVE' : (isDeluxe ? 'VALUE PACK' : 'NO ADS'),
      onTap: isPurchased ? null : () => _purchase(context, ref, bundleId),
    );
  }

  void _purchase(BuildContext context, WidgetRef ref, String productId) async {
    ComicButton.playButtonSfx();
    unawaited(HapticFeedback.mediumImpact());
    final result = await ref.read(storeControllerProvider).buyBundle(productId);
    if (!context.mounted) return;
    if (result is IapSuccess) {
      final deluxeBundle = StoreData.adFreeDeluxeBundle;
      unawaited(ClaimRewardOverlay.show(
        context,
        title: 'PURCHASE SUCCESSFUL!',
        isAdFreeUnlocked: true,
        inkReward: isDeluxe ? deluxeBundle.ink : 0,
        paintReward: isDeluxe ? deluxeBundle.paint : 0,
      ));
    } else if (result is IapError) {
      unawaited(LockedFeatureOverlay.show(
        context,
        customTitle: 'Purchase Failed',
        customDescription: result.message,
        customConditionText: 'Purchase Error',
        customEmoji: '❌',
      ));
    }
  }
}

