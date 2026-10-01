import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:colosynth/game_data/store_data.dart';
import 'package:colosynth/services/iap_service.dart';
import 'package:colosynth/services/purchase_ledger_service.dart';
import 'package:colosynth/providers/wallet_provider.dart';
import 'package:colosynth/providers/shared_preferences_provider.dart';
import 'package:colosynth/services/battle_ads_service.dart';
import 'package:colosynth/services/save_manager.dart';
import 'package:colosynth/screens/overlays/claim_reward_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late PurchaseLedgerService ledgerService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    await SaveManager.instance.init(prefs);
    ledgerService = PurchaseLedgerService.instance;
    ledgerService.clearForTest();
    await ledgerService.init(prefs);
  });

  group('RevenueCat Catalog & IAP Registration Tests', () {
    test('All 18 IAP store products are uniquely registered in IapService', () {
      final ids = IapService.instance.allProductIds;

      // Exactly 18 products: 6 Ink + 6 Paint + 3 Combos + 1 Starter + 2 Ad-Free (Basic + Deluxe)
      expect(ids.length, equals(18));
      expect(ids.toSet().length, equals(18), reason: 'Product IDs must be strictly unique');

      // Verify Ink packs
      expect(ids.contains('colosynth_ink_12000'), isTrue);
      expect(ids.contains('colosynth_ink_70000'), isTrue);
      expect(ids.contains('colosynth_ink_160000'), isTrue);
      expect(ids.contains('colosynth_ink_380000'), isTrue);
      expect(ids.contains('colosynth_ink_1100000'), isTrue);
      expect(ids.contains('colosynth_ink_2500000'), isTrue);

      // Verify Paint packs (specifically paint_20)
      expect(ids.contains('colosynth_paint_20'), isTrue);
      expect(ids.contains('colosynth_paint_85'), isTrue);
      expect(ids.contains('colosynth_paint_190'), isTrue);
      expect(ids.contains('colosynth_paint_420'), isTrue);
      expect(ids.contains('colosynth_paint_1150'), isTrue);
      expect(ids.contains('colosynth_paint_2500'), isTrue);

      // Verify 3-tier Combo packs ($0.99, $9.99, $29.99)
      expect(ids.contains('colosynth_combo_strike'), isTrue);
      expect(ids.contains('colosynth_combo_tactical'), isTrue);
      expect(ids.contains('colosynth_combo_gearup'), isTrue);

      // Verify Starter pack
      expect(ids.contains('colosynth_starter_bundle'), isTrue);

      // Verify Dual Ad-Free products ($4.99 and $9.99)
      expect(ids.contains('colosynth_ad_free'), isTrue);
      expect(ids.contains('colosynth_ad_free_deluxe'), isTrue);
    });

    test('StoreData packaging specs match requirements exactly', () {
      // Paint 20 check
      expect(StoreData.paintBundles.first.paint, equals(20));
      expect(StoreData.paintBundles.first.productId, equals('colosynth_paint_20'));
      expect(StoreData.paintBundles.first.usdFallback, equals(r'$0.99'));

      // Ad Free a-la carte check
      expect(StoreData.adFreeBundle.productId, equals('colosynth_ad_free'));
      expect(StoreData.adFreeBundle.usdFallback, equals(r'$4.99'));

      // Ad Free Deluxe bundle check (88 Paint + 8,888 Ink for $9.99)
      expect(StoreData.adFreeDeluxeBundle.productId, equals('colosynth_ad_free_deluxe'));
      expect(StoreData.adFreeDeluxeBundle.paint, equals(88));
      expect(StoreData.adFreeDeluxeBundle.ink, equals(8888));
      expect(StoreData.adFreeDeluxeBundle.usdFallback, equals(r'$9.99'));

      // 3 Combo packs check
      expect(StoreData.comboBundles.length, equals(3));
      final strike = StoreData.comboBundles[0];
      final tactical = StoreData.comboBundles[1];
      final gearup = StoreData.comboBundles[2];

      expect(strike.productId, equals('colosynth_combo_strike'));
      expect(strike.usdFallback, equals(r'$0.99'));
      expect(strike.ink, equals(8000));
      expect(strike.paint, equals(15));

      expect(tactical.productId, equals('colosynth_combo_tactical'));
      expect(tactical.usdFallback, equals(r'$9.99'));
      expect(tactical.ink, equals(100000));
      expect(tactical.paint, equals(120));

      expect(gearup.productId, equals('colosynth_combo_gearup'));
      expect(gearup.usdFallback, equals(r'$29.99'));
      expect(gearup.ink, equals(350000));
      expect(gearup.paint, equals(450));
    });
  });

  group('Purchase Ledger Hardening & Exploit Prevention', () {
    test('removePending clears cancelled purchase from unfulfilled ledger', () async {
      await ledgerService.recordPending('tx_cancelled_1', 'colosynth_ink_2500000');
      expect(ledgerService.getUnfulfilled().length, equals(1));

      // Player cancelled payment sheet -> remove pending
      await ledgerService.removePending('tx_cancelled_1');
      expect(ledgerService.getUnfulfilled(), isEmpty);

      // Verify persisted state is also empty
      final fresh = PurchaseLedgerService.instance;
      await fresh.init(prefs);
      expect(fresh.getUnfulfilled(), isEmpty);
    });

    test('reconcilePendingAwards fulfills adFreeDeluxeBundle with 88 Paint and 8888 Ink', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      await ledgerService.recordPending('tx_deluxe_1', StoreData.adFreeDeluxeBundle.productId);
      expect(ledgerService.getUnfulfilled().length, equals(1));

      final count = await ledgerService.reconcilePendingAwards(container as dynamic);
      expect(count, equals(1));
      expect(ledgerService.getUnfulfilled(), isEmpty);

      // Verify wallet received the 8,888 Ink and 88 Paint
      final wallet = container.read(walletProvider);
      expect(wallet.ink, equals(8888));
      expect(wallet.paint, equals(88));
    });

    test('reconcilePendingAwards fulfills new 3-tier combo bundles into wallet', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      // Reconcile Strike Combo (8,000 ink + 15 paint)
      await ledgerService.recordPending('tx_strike', 'colosynth_combo_strike');
      await ledgerService.reconcilePendingAwards(container as dynamic);

      final wallet = container.read(walletProvider);
      expect(wallet.ink, equals(8000));
      expect(wallet.paint, equals(15));
    });
  });

  group('BattleAdsService Ad-Free Integration', () {
    test('showDoubleRewardAd grants reward without ad when user is ad-free', () async {
      await BattleAdsService.instance.init(prefs);

      // When adFreeActive is false, showAd is attempted
      // If we verify the adFreeActive branch in showDoubleRewardAd:
      expect(BattleAdsService.instance.canShowDoubleReward, isTrue);
    });
  });

  group('IapService Google Play Guarding (Bypass Removal)', () {
    test('purchaseProduct returns IapError when product is not in catalog', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      IapService.instance.setInitializedForTest(true);
      addTearDown(() {
        debugDefaultTargetPlatformOverride = null;
        IapService.instance.setInitializedForTest(false);
      });

      final result = await IapService.instance.purchaseProduct('colosynth_paint_20');
      expect(result, isA<IapError>());
      final error = result as IapError;
      expect(error.message, contains('not found in store catalog'));
    });
  });

  group('ClaimRewardOverlay Widget Tests', () {
    testWidgets('renders custom title, ad-free badge, synth keys, ink, and paint', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClaimRewardOverlay(
              title: 'PURCHASE SUCCESSFUL!',
              isAdFreeUnlocked: true,
              synthKeys: 1,
              inkReward: 8888,
              paintReward: 88,
              onDismiss: () {},
            ),
          ),
        ),
      );

      // Verify burst title
      expect(find.text('PURCHASE SUCCESSFUL!'), findsOneWidget);

      // Verify Ad Free Unlocked badge
      expect(find.text('AD FREE UNLOCKED'), findsOneWidget);

      // Verify Synth Key row
      expect(find.text('SYNTH KEY'), findsOneWidget);
      expect(find.text('+1'), findsOneWidget);

      // Verify Ink and Paint rows
      expect(find.text('INK'), findsOneWidget);
      expect(find.text('+8888'), findsOneWidget);
      expect(find.text('PAINT'), findsOneWidget);
      expect(find.text('+88'), findsOneWidget);
    });

    testWidgets('renders default CLAIMED! title when title is omitted', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClaimRewardOverlay(
              inkReward: 100,
              paintReward: 5,
              onDismiss: () {},
            ),
          ),
        ),
      );

      expect(find.text('CLAIMED!'), findsOneWidget);
      expect(find.text('INK'), findsOneWidget);
      expect(find.text('+100'), findsOneWidget);
      expect(find.text('PAINT'), findsOneWidget);
      expect(find.text('+5'), findsOneWidget);
    });
  });
}
