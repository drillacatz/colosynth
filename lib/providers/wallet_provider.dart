import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:colosynth/providers/save_provider.dart';

enum Currency { ink, paint }

class WalletState {
  final int ink;
  final int paint;

  const WalletState({required this.ink, required this.paint});

  bool canAfford(Currency type, int amount) {
    if (type == Currency.ink) return ink >= amount;
    return paint >= amount;
  }

  int amountOf(Currency type) => type == Currency.ink ? ink : paint;
}



final walletProvider = NotifierProvider<WalletNotifier, WalletState>(WalletNotifier.new);

class WalletNotifier extends Notifier<WalletState> {
  @override
  WalletState build() {
    final ink = ref.watch(accountSaveNotifierProvider.select((s) => s.ink));
    final paint = ref.watch(accountSaveNotifierProvider.select((s) => s.paint));
    return WalletState(ink: ink, paint: paint);
  }

  bool canAfford(Currency type, int amount) => state.canAfford(type, amount);

  Future<void> award(Currency type, int amount, {String source = 'unknown'}) async {
    if (type == Currency.ink) {
      await ref.read(accountSaveNotifierProvider.notifier).awardInk(amount, source: source);
    } else {
      await ref.read(accountSaveNotifierProvider.notifier).awardPaint(amount, source: source);
    }
  }

  Future<void> spend(Currency type, int amount, {String reason = 'unknown'}) async {
    if (type == Currency.ink) {
      await ref.read(accountSaveNotifierProvider.notifier).spendInk(amount, reason: reason);
    } else {
      await ref.read(accountSaveNotifierProvider.notifier).spendPaint(amount, reason: reason);
    }
  }

  Future<void> awardMultiple({int ink = 0, int paint = 0, String source = 'unknown'}) async {
    if (ink > 0) await award(Currency.ink, ink, source: source);
    if (paint > 0) await award(Currency.paint, paint, source: source);
  }
}

final inkProvider = Provider<int>((ref) => ref.watch(walletProvider.select((s) => s.ink)));
final paintProvider = Provider<int>((ref) => ref.watch(walletProvider.select((s) => s.paint)));
