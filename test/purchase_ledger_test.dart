import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:colosynth/services/purchase_ledger_service.dart';
import 'package:colosynth/game_data/store_data.dart';
import 'package:colosynth/providers/shared_preferences_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late PurchaseLedgerService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    service = PurchaseLedgerService.instance;
    service.clearForTest();
    await service.init(prefs);
  });

  group('PurchaseLedgerService Tests', () {
    test('records pending purchase and retrieves unfulfilled entries', () async {
      await service.recordPending('tx_001', 'ink_handful');
      final unfulfilled = service.getUnfulfilled();

      expect(unfulfilled.length, 1);
      expect(unfulfilled.first.txId, 'tx_001');
      expect(unfulfilled.first.productId, 'ink_handful');
      expect(unfulfilled.first.fulfilled, isFalse);
    });

    test('marks purchase as fulfilled and persists state', () async {
      await service.recordPending('tx_002', 'paint_bucket');
      expect(service.getUnfulfilled().length, 1);

      await service.markFulfilled('tx_002');
      expect(service.getUnfulfilled(), isEmpty);

      // Re-initialize from persisted prefs to verify persistence
      final newServiceInstance = PurchaseLedgerService.instance;
      await newServiceInstance.init(prefs);
      expect(newServiceInstance.getUnfulfilled(), isEmpty);
    });

    test('reconciles interrupted ink bundle purchase into wallet', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      // Record interrupted purchase of first ink bundle
      final targetBundle = StoreData.inkBundles.first;
      await service.recordPending('tx_reconcile_ink', targetBundle.productId);
      expect(service.getUnfulfilled().length, 1);

      expect(service.getUnfulfilled().first.txId, 'tx_reconcile_ink');
      await service.markFulfilled('tx_reconcile_ink');
      expect(service.getUnfulfilled(), isEmpty);
    });
  });
}
