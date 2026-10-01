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

  static String get _apiKey {
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AppConfig.revenueCatAppleApiKey.isNotEmpty
          ? AppConfig.revenueCatAppleApiKey
          : AppConfig.revenueCatGoogleApiKey;
    }
    return AppConfig.revenueCatGoogleApiKey;
  }

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

  bool get isPlatformSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  List<String> get _allProductIds => [
        ...StoreData.inkBundles.map((b) => b.productId),
        ...StoreData.paintBundles.map((b) => b.productId),
        ...StoreData.comboBundles.map((b) => b.productId),
        StoreData.starterBundle.productId,
        StoreData.adFreeBundle.productId,
        StoreData.adFreeDeluxeBundle.productId,
      ];

  List<String> get allProductIds => List.unmodifiable(_allProductIds);

  Future<void> init() {
    if (_initialized) return Future.value();
    return _initFuture ??= _doInit().whenComplete(() {
      _initFuture = null;
    });
  }

  Future<void> _doInit() async {
    if (!isPlatformSupported) {
      _log('RevenueCat native purchases not supported on $defaultTargetPlatform — running in fallback mode.');
      return;
    }

    final key = _apiKey;
    if (key.isEmpty || key.startsWith('YOUR_')) {
      _log('RevenueCat API key not set or placeholder — skipping.');
      return;
    }
    try {
      await Purchases.setLogLevel(
        kDebugMode ? LogLevel.debug : LogLevel.error,
      );
      await Purchases.configure(PurchasesConfiguration(key));

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
    if (!isPlatformSupported || !_initialized) return;
    try {
      try {
        final offerings = await Purchases.getOfferings();
        final current = offerings.current;
        if (current != null) {
          for (final pkg in current.availablePackages) {
            _products[pkg.storeProduct.identifier] = pkg.storeProduct;
          }
        }
      } catch (e) {
        _log('getOfferings notice (direct products will still load): $e');
      }

      final ids = _allProductIds;
      final fetched = await Purchases.getProducts(
        ids,
        productCategory: ProductCategory.nonSubscription,
      );
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
    if (!isPlatformSupported || !_initialized) return;
    try {
      final info = await Purchases.getCustomerInfo();
      _syncAdFreeStatusWithInfo(info);
    } catch (_) {}
  }

  Future<void> logIn(String uid) async {
    if (!isPlatformSupported) return;
    try {
      await init();
      if (!_initialized) return;
      await Purchases.logIn(uid);
      await _syncAdFreeStatus();
    } catch (e) {
      _log('logIn error: $e');
    }
  }

  Future<void> logOut() async {
    if (!isPlatformSupported) return;
    try {
      await init();
      if (!_initialized) return;
      await Purchases.logOut();
      _adFreeActive = false;
    } catch (e) {
      _log('logOut error: $e');
    }
  }

  Future<IapResult> purchaseProduct(String productId) async {
    if (!isPlatformSupported) {
      return const IapError('In-app purchases are only available on mobile devices.');
    }

    if (!_initialized) return const IapError('Store not ready. Try again.');

    if (_purchaseInProgress) {
      return const IapError('A purchase is already in progress.');
    }

    _purchaseInProgress = true;

    try {
      if (!_products.containsKey(productId)) await _loadProducts();
      var product = _products[productId];

      if (product == null) {
        try {
          final direct = await Purchases.getProducts(
            [productId],
            productCategory: ProductCategory.nonSubscription,
          );
          if (direct.isNotEmpty) {
            _products[productId] = direct.first;
            product = direct.first;
          }
        } catch (_) {}
      }

      if (product == null) {
        final isDevOrTest = !AppConfig.isProduction ||
            kDebugMode ||
            _apiKey.startsWith('test_');
        if (isDevOrTest && _allProductIds.contains(productId)) {
          _log('Simulating purchase for $productId in development/test store mode.');
          if (productId == StoreData.adFreeBundle.productId ||
              productId == StoreData.adFreeDeluxeBundle.productId) {
            _adFreeActive = true;
          }
          return const IapSuccess();
        }

        return IapError('Product "$productId" not found in store catalog.');
      }

      await Purchases.purchase(PurchaseParams.storeProduct(product));

      await _syncAdFreeStatus();
      return const IapSuccess();
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return const IapCancelled();
      } else if (code == PurchasesErrorCode.paymentPendingError) {
        return const IapError('Payment is pending approval. You will receive items once confirmed.');
      } else if (code == PurchasesErrorCode.productAlreadyPurchasedError) {
        await _syncAdFreeStatus();
        return const IapError('Product already purchased. Please restore purchases if needed.');
      } else if (code == PurchasesErrorCode.networkError) {
        return const IapError('Network error. Please check your internet connection.');
      }
      return IapError(e.message ?? 'Purchase failed.');
    } catch (e) {
      return IapError(e.toString());
    } finally {
      _purchaseInProgress = false;
    }
  }

  Future<void> restorePurchases() async {
    if (!isPlatformSupported) return;
    if (!_initialized) await init();
    if (!_initialized) return;
    try {
      final info = await Purchases.restorePurchases();
      _syncAdFreeStatusWithInfo(info);
      if (!_customerInfoStreamController.isClosed) {
        _customerInfoStreamController.add(info);
      }
    } catch (e) {
      _log('restorePurchases error: $e');
      final isDevOrTest = !AppConfig.isProduction ||
          kDebugMode ||
          _apiKey.startsWith('test_');
      if (!isDevOrTest) rethrow;
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
