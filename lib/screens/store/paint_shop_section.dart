import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:colosynth/game_data/store_data.dart';
import 'package:colosynth/providers/store_provider.dart';
import 'package:colosynth/services/iap_service.dart';
import 'package:colosynth/screens/theme/tokens.dart';
import 'package:colosynth/screens/overlays/locked_feature_overlay.dart';
import 'package:colosynth/screens/store/shop_card.dart';

class PaintShopSection extends StatefulWidget {
  const PaintShopSection({super.key, required this.prices});

  final Map<String, String> prices;

  @override
  State<PaintShopSection> createState() => _PaintShopSectionState();
}

class _PaintShopSectionState extends State<PaintShopSection> {
  bool _starterPurchased = false;

  @override
  void initState() {
    super.initState();
    _checkStarterStatus();
  }

  Future<void> _checkStarterStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _starterPurchased = prefs.getBool('colosynth_starter_bundle_purchased') ?? false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bundles = StoreData.paintBundles;
    final combos = StoreData.comboBundles;
    final starter = StoreData.starterBundle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_starterPurchased) ...[
          const _SectionTitle(title: 'SPECIAL OFFER (1-TIME LIMIT)'),
          const SizedBox(height: 8),
          _StarterBundleCard(
            bundle: starter,
            priceString: widget.prices[starter.productId] ?? starter.usdFallback,
            onPurchased: () => setState(() => _starterPurchased = true),
          ),
          const SizedBox(height: 16),
        ],
        const _SectionTitle(title: 'PAINT PACKS'),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.88,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: bundles.asMap().entries.map((entry) {
            final i = entry.key;
            final b = entry.value;
            return PaintBundleGridCard(
              bundle: b,
              priceString: widget.prices[b.productId] ?? b.usdFallback,
            )
                .animate(delay: (i * 40).ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.1, end: 0);
          }).toList(),
        ),
        const SizedBox(height: 16),
        const _SectionTitle(title: 'COMBO PACKS (INK + PAINT)'),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.4,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: combos.asMap().entries.map((entry) {
            final i = entry.key;
            final c = entry.value;
            return _ComboBundleGridCard(
              bundle: c,
              priceString: widget.prices[c.productId] ?? c.usdFallback,
            )
                .animate(delay: (i * 40).ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.1, end: 0);
          }).toList(),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Bangers',
        fontSize: 14,
        letterSpacing: 2,
        color: Color(0xFFE91E63),
      ),
    );
  }
}

class PaintBundleGridCard extends ConsumerWidget {
  const PaintBundleGridCard({
    super.key,
    required this.bundle,
    required this.priceString,
  });

  final PaintBundle bundle;
  final String priceString;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ShopCard(
      icon: Icons.brush,
      mainLabel: bundle.label,
      subLabel: priceString,
      highlighted: bundle.paint >= 500,
      accentColor: const Color(0xFFF50057),
      onTap: () => _purchase(context, ref),
    );
  }

  void _purchase(BuildContext context, WidgetRef ref) async {
    ComicButton.playButtonSfx();
    unawaited(HapticFeedback.mediumImpact());
    final result = await ref.read(storeControllerProvider).buyBundle(bundle.productId);
    if (!context.mounted) return;
    if (result is IapError) {
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

class _ComboBundleGridCard extends ConsumerWidget {
  const _ComboBundleGridCard({
    required this.bundle,
    required this.priceString,
  });

  final ComboBundle bundle;
  final String priceString;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ShopCard(
      icon: Icons.auto_awesome,
      mainLabel: bundle.label,
      subLabel: '${bundle.ink} INK + ${bundle.paint}P\n$priceString',
      highlighted: true,
      accentColor: const Color(0xFFFF9800),
      onTap: () => _purchase(context, ref),
    );
  }

  void _purchase(BuildContext context, WidgetRef ref) async {
    ComicButton.playButtonSfx();
    unawaited(HapticFeedback.mediumImpact());
    final result = await ref.read(storeControllerProvider).buyBundle(bundle.productId);
    if (!context.mounted) return;
    if (result is IapError) {
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

class _StarterBundleCard extends ConsumerWidget {
  const _StarterBundleCard({
    required this.bundle,
    required this.priceString,
    required this.onPurchased,
  });

  final StarterBundle bundle;
  final String priceString;
  final VoidCallback onPurchased;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E102A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF00E5FF), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.star, color: Color(0xFF00E5FF), size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bundle.label,
                  style: const TextStyle(
                    fontFamily: 'Bangers',
                    fontSize: 16,
                    letterSpacing: 2,
                    color: Color(0xFF00E5FF),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${bundle.paint} Paint + ${bundle.ink} Ink',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _purchase(context, ref),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: Text(
              priceString,
              style: const TextStyle(
                fontFamily: 'Bangers',
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _purchase(BuildContext context, WidgetRef ref) async {
    ComicButton.playButtonSfx();
    unawaited(HapticFeedback.mediumImpact());
    final result = await ref.read(storeControllerProvider).buyBundle(bundle.productId);
    if (!context.mounted) return;
    if (result is IapSuccess) {
      onPurchased();
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
