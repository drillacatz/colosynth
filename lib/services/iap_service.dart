import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:colosynth/game_data/store_data.dart';
import 'package:colosynth/utils/app_logger.dart';
import 'package:colosynth/utils/app_config.dart';

sealed class IapResult {
  const IapResult();
}

class IapSuccess extends IapResult {
  const IapSuccess();
}

class IapCancelled extends IapResult {
  const IapCancelled();
}

class IapError extends IapResult {
  const IapError(this.message);
  final String message;
}

class IapService {
  IapService._();
  static final IapService instance = IapService._();

  static final _apiKey = AppConfig.revenueCatGoogleApiKey;
  static const _entitlementAdFree = 'ad_free';

  final Map<String, StoreProduct> _products = {};
  bool _initialized = false;
  bool _adFreeActive = false;
  bool _purchaseInProgress = false;

  Future<void>? _initFuture;
  Future<void>? _loadProductsFuture;

  final _customerInfoStreamController = StreamController<CustomerInfo>.broadcast();
  Stream<CustomerInfo> get customerInfoStream => _customerInfoStreamController.stream;

  bool get adFreeActive => _adFreeActive;

  List<String> get _allProductIds => [
        ...StoreData.inkBundles.map((b) => b.productId),
        ...StoreData.paintBundles.map((b) => b.productId),
        StoreData.adFreeBundle.productId,
      ];

  Future<void> init() {
    if (_initialized) return Future.value();
    return _initFuture ??= _doInit().whenComplete(() {
      _initFuture = null;
    });
  }

  Future<void> _doInit() async {
    if (_apiKey.isEmpty) {
      _log('REVENUECAT_GOOGLE_API_KEY not set — skipping.');
      return;
    }
    try {
      await Purchases.setLogLevel(
        kDebugMode ? LogLevel.debug : LogLevel.error,
      );
      await Purchases.configure(PurchasesConfiguration(_apiKey));


      _initialized = true;


      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        _syncAdFreeStatusWithInfo(customerInfo);
        if (!_customerInfoStreamController.isClosed) {
          _customerInfoStreamController.add(customerInfo);
        }
      });

      await Future.wait([_loadProducts(), _syncAdFreeStatus()]);
    } catch (e) {
      _initialized = false;
      _log('init error: $e');
    }
  }

  Future<void> _loadProducts() {
    return _loadProductsFuture ??= _doLoadProducts().whenComplete(() {
      _loadProductsFuture = null;
    });
  }

  Future<void> _doLoadProducts() async {
    try {
      final ids = _allProductIds;
      final fetched = await Purchases.getProducts(ids);
      for (final p in fetched) {
        _products[p.identifier] = p;
      }
      final missing =
          ids.where((id) => !_products.containsKey(id)).toList();
      if (missing.isNotEmpty) {
        _log('products not found — $missing');
      }
    } catch (e) {
      _log('_loadProducts error: $e');
    }
  }

  void _syncAdFreeStatusWithInfo(CustomerInfo info) {
    final active = info.entitlements.active.containsKey(_entitlementAdFree);
    if (_adFreeActive != active) {
      _adFreeActive = active;
    }
  }

  Future<void> _syncAdFreeStatus() async {
    try {
      final info = await Purchases.getCustomerInfo();
      _syncAdFreeStatusWithInfo(info);
    } catch (_) {}
  }

  Future<void> logIn(String uid) async {
    try {
      await init();
      await Purchases.logIn(uid);
      await _syncAdFreeStatus();
    } catch (e) {
      _log('logIn error: $e');
    }
  }

  Future<void> logOut() async {
    try {
      await init();
      await Purchases.logOut();
      _adFreeActive = false;
    } catch (e) {
      _log('logOut error: $e');
    }
  }

  Future<IapResult> purchaseProduct(String productId) async {
    if (!_initialized) return const IapError('Store not ready. Try again.');

    if (_purchaseInProgress) {
      return const IapError('A purchase is already in progress.');
    }

    _purchaseInProgress = true;

    try {
      if (!_products.containsKey(productId)) await _loadProducts();

      final product = _products[productId];
      if (product == null) {
        return IapError('Product "$productId" not found.');
      }

      await Purchases.purchase(PurchaseParams.storeProduct(product));

      await _syncAdFreeStatus();
      return const IapSuccess();
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return const IapCancelled();
      }
      return IapError(e.message ?? 'Purchase failed.');
    } catch (e) {
      return IapError(e.toString());
    } finally {
      _purchaseInProgress = false;
    }
  }

  Future<void> restorePurchases() async {
    try {
      await Purchases.restorePurchases();
      await _syncAdFreeStatus();
    } catch (e) {
      _log('restorePurchases error: $e');
      rethrow;
    }
  }

  String? priceOf(String productId) => _products[productId]?.priceString;

  Map<String, String> get priceMap => {
        for (final e in _products.entries) e.key: e.value.priceString,
      };

  Future<Map<String, String>> getPrices() async {
    if (!_initialized) await init();
    if (_products.isEmpty) await _loadProducts();
    return priceMap;
  }

  void _log(String message) {
    AppLogger.d('IapService', message);
  }



  void dispose() {
    _customerInfoStreamController.close();
  }
}

final iapPricesProvider = FutureProvider<Map<String, String>>((ref) async {
  return IapService.instance.getPrices();
});

final iapServiceProvider = Provider<IapService>((_) => IapService.instance);
