import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:colosynth/providers/save_provider.dart';

final expItemsProvider =
    NotifierProvider<ExpItemsNotifier, Map<String, int>>(ExpItemsNotifier.new);

class ExpItemsNotifier extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() =>
      ref.watch(gameplaySaveNotifierProvider.select((s) => s.expItems));
      
  int quantityOf(String id) => state[id] ?? 0;
  
  Future<bool> consume(String id) =>
      ref.read(gameplaySaveNotifierProvider.notifier).consumeExpItem(id);

  Future<void> grant(String id, int count) =>
      ref.read(gameplaySaveNotifierProvider.notifier).addExpItem(id, count);
}
