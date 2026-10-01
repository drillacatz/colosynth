import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:colosynth/screens/store/ink_shop_section.dart';
import 'package:colosynth/screens/store/shop_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Store Screen Layout & Overflow Tests', () {
    testWidgets(
        'AdFreeShopCard renders in compact mode without RenderFlex overflow in 84dp height',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 84,
                child: AdFreeShopCard(prices: {}, compact: true),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(AdFreeShopCard), findsOneWidget);
    });

    testWidgets(
        'ShopCard Column has FittedBox scaleDown protection preventing overflow even in tight bounds',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 70,
              width: 200,
              child: ShopCard(
                icon: Icons.stars_rounded,
                mainLabel: 'NO ADS FOREVER AND MORE',
                subLabel: '\$2.99',
                highlighted: true,
                compact: false,
                onTap: null,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(ShopCard), findsOneWidget);
    });
  });
}
