import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:colosynth/game_data/store_data.dart';
import 'package:colosynth/providers/wallet_provider.dart';
import 'package:colosynth/providers/store_provider.dart';
import 'package:colosynth/utils/app_logger.dart';

class PurchaseLedgerEntry {
  final String txId;
  final String productId;
  final int timestamp;
  final bool fulfilled;

  const PurchaseLedgerEntry({
    required this.txId,
    required this.productId,
    required this.timestamp,
    required this.fulfilled,
  });

  Map<String, dynamic> toJson() => {
        'txId': txId,
        'productId': productId,
        'timestamp': timestamp,
        'fulfilled': fulfilled,
      };

  factory PurchaseLedgerEntry.fromJson(Map<String, dynamic> json) =>
      PurchaseLedgerEntry(
        txId: json['txId'] as String,
        productId: json['productId'] as String,
        timestamp: json['timestamp'] as int,
        fulfilled: json['fulfilled'] as bool? ?? false,
      );
}

class PurchaseLedgerService {
  PurchaseLedgerService._();
  static final PurchaseLedgerService instance = PurchaseLedgerService._();

  static const String _kLedgerKey = 'colosynth_purchase_ledger_v1';
  SharedPreferences? _prefs;
  final Map<String, PurchaseLedgerEntry> _entries = {};

  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    _entries.clear();
    _loadEntries();
  }

  void clearForTest() {
    _entries.clear();
  }

  void _loadEntries() {
    final raw = _prefs?.getString(_kLedgerKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          final entry = PurchaseLedgerEntry.fromJson(item);
          _entries[entry.txId] = entry;
        }
      }
    } catch (e) {
      AppLogger.w('PurchaseLedgerService', 'Error decoding ledger: $e');
    }
  }

  Future<void> _persist() async {
    final p = _prefs;
    if (p == null) return;
    final list = _entries.values.map((e) => e.toJson()).toList();
    await p.setString(_kLedgerKey, jsonEncode(list));
  }

  Future<void> recordPending(String txId, String productId) async {
    _entries[txId] = PurchaseLedgerEntry(
      txId: txId,
      productId: productId,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      fulfilled: false,
    );
    await _persist();
    AppLogger.d('PurchaseLedgerService', 'Recorded pending purchase: $txId ($productId)');
  }

  Future<void> removePending(String txId) async {
    if (_entries.containsKey(txId)) {
      _entries.remove(txId);
      await _persist();
      AppLogger.d('PurchaseLedgerService', 'Removed pending purchase: $txId');
    }
  }

  Future<void> markFulfilled(String txId) async {
    final existing = _entries[txId];
    if (existing != null) {
      _entries[txId] = PurchaseLedgerEntry(
        txId: existing.txId,
        productId: existing.productId,
        timestamp: existing.timestamp,
        fulfilled: true,
      );
      await _persist();
      AppLogger.d('PurchaseLedgerService', 'Marked purchase fulfilled: $txId');
    }
  }

  List<PurchaseLedgerEntry> getUnfulfilled() {
    return _entries.values.where((e) => !e.fulfilled).toList();
  }

  Future<int> reconcilePendingAwards(dynamic ref) async {
    final unfulfilled = getUnfulfilled();
    if (unfulfilled.isEmpty) return 0;

    int reconciledCount = 0;
    for (final entry in unfulfilled) {
      try {
        final productId = entry.productId;
        if (productId == StoreData.adFreeBundle.productId) {
          await ref.read(adFreeProvider.notifier).refresh();
        } else if (productId == StoreData.adFreeDeluxeBundle.productId) {
          await ref.read(walletProvider.notifier).awardMultiple(
                ink: StoreData.adFreeDeluxeBundle.ink,
                paint: StoreData.adFreeDeluxeBundle.paint,
                source: 'store_purchase',
              );
          await ref.read(adFreeProvider.notifier).refresh();
        } else {
          final inkBundle = StoreData.inkBundles
              .where((b) => b.productId == productId)
              .firstOrNull;
          if (inkBundle != null) {
            await ref.read(walletProvider.notifier).award(
                  Currency.ink,
                  inkBundle.ink,
                  source: 'store_purchase',
                );
          } else {
            final paintBundle = StoreData.paintBundles
                .where((b) => b.productId == productId)
                .firstOrNull;
            if (paintBundle != null) {
              await ref.read(walletProvider.notifier).award(
                    Currency.paint,
                    paintBundle.paint,
                    source: 'store_purchase',
                  );
            } else {
              final comboBundle = StoreData.comboBundles
                  .where((b) => b.productId == productId)
                  .firstOrNull;
              if (comboBundle != null) {
                await ref.read(walletProvider.notifier).awardMultiple(
                      ink: comboBundle.ink,
                      paint: comboBundle.paint,
                      source: 'store_purchase',
                    );
              } else if (productId == StoreData.starterBundle.productId) {
                await ref.read(walletProvider.notifier).awardMultiple(
                      ink: StoreData.starterBundle.ink,
                      paint: StoreData.starterBundle.paint,
                      source: 'store_purchase',
                    );
              }
            }
          }
        }
        await markFulfilled(entry.txId);
        reconciledCount++;
        AppLogger.d('PurchaseLedgerService', 'Successfully reconciled interrupted purchase ${entry.txId} ($productId)');
      } catch (e) {
        AppLogger.e('PurchaseLedgerService', 'Failed to reconcile purchase ${entry.txId}: $e');
      }
    }
    return reconciledCount;
  }
}

final purchaseLedgerServiceProvider =
    Provider<PurchaseLedgerService>((_) => PurchaseLedgerService.instance);
