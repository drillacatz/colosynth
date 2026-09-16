import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:colosynth/services/save_manager.dart';
import 'package:colosynth/providers/auth_provider.dart';
import 'package:colosynth/providers/save_provider.dart';

import 'package:collection/collection.dart';

class AccountSaveState {
  final int ink;
  final int paint;
  final int accountLevel;
  final int accountXp;
  final List<String> unlockedCharacters;
  final List<String> inventory;
  final List<String> unlockedItems;
  final Map<String, String> tournamentProgress;

  AccountSaveState({
    required this.ink,
    required this.paint,
    required this.accountLevel,
    required this.accountXp,
    required this.unlockedCharacters,
    required this.inventory,
    required this.unlockedItems,
    required this.tournamentProgress,
  });

  AccountSaveState copyWith({
    int? ink,
    int? paint,
    int? accountLevel,
    int? accountXp,
    List<String>? unlockedCharacters,
    List<String>? inventory,
    List<String>? unlockedItems,
    Map<String, String>? tournamentProgress,
  }) {
    return AccountSaveState(
      ink: ink ?? this.ink,
      paint: paint ?? this.paint,
      accountLevel: accountLevel ?? this.accountLevel,
      accountXp: accountXp ?? this.accountXp,
      unlockedCharacters: unlockedCharacters ?? this.unlockedCharacters,
      inventory: inventory ?? this.inventory,
      unlockedItems: unlockedItems ?? this.unlockedItems,
      tournamentProgress: tournamentProgress ?? this.tournamentProgress,
    );
  }

  static const _listEq = ListEquality();
  static const _mapEq = MapEquality();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AccountSaveState &&
        other.ink == ink &&
        other.paint == paint &&
        other.accountLevel == accountLevel &&
        other.accountXp == accountXp &&
        _listEq.equals(other.unlockedCharacters, unlockedCharacters) &&
        _listEq.equals(other.inventory, inventory) &&
        _listEq.equals(other.unlockedItems, unlockedItems) &&
        _mapEq.equals(other.tournamentProgress, tournamentProgress);
  }

  @override
  int get hashCode => Object.hash(
        ink,
        paint,
        accountLevel,
        accountXp,
        _listEq.hash(unlockedCharacters),
        _listEq.hash(inventory),
        _listEq.hash(unlockedItems),
        _mapEq.hash(tournamentProgress),
      );
}

final accountSaveNotifierProvider =
    NotifierProvider<AccountSaveNotifier, AccountSaveState>(
        AccountSaveNotifier.new);

class AccountSaveNotifier extends Notifier<AccountSaveState> {
  @override
  AccountSaveState build() {
    ref.watch(authStateProvider);
    ref.watch(saveSyncReadyProvider);

    final saveManager = ref.watch(saveManagerProvider);
    if (!saveManager.isInitialized) {
      return AccountSaveState(
        ink: 0,
        paint: 0,
        accountLevel: 1,
        accountXp: 0,
        unlockedCharacters: const ['arthur'],
        inventory: const [],
        unlockedItems: const [],
        tournamentProgress: const {},
      );
    }

    final sm = ref.read(accountSaveProvider);
    return AccountSaveState(
      ink: sm.loadInk(),
      paint: sm.loadPaint(),
      accountLevel: sm.loadAccountLevel(),
      accountXp: sm.loadAccountXp(),
      unlockedCharacters: sm.loadUnlockedCharacters(),
      inventory: sm.loadInventory(),
      unlockedItems: sm.loadUnlockedItems(),
      tournamentProgress: sm.loadTournamentProgress(),
    );
  }

  Future<void> awardInk(int amount, {String source = 'unknown'}) async {
    var finalAmount = amount;

    if (source != 'store_iap' && source != 'store_purchase' && finalAmount > 30000) {
      finalAmount = 30000;
    }
    await ref.read(accountSaveProvider).awardInk(finalAmount, source: source);
    state = state.copyWith(ink: ref.read(accountSaveProvider).loadInk());
  }

  Future<void> spendInk(int amount, {String reason = 'unknown'}) async {
    if (state.ink < amount) {
      throw InsufficientFundsException('ink');
    }
    await ref.read(accountSaveProvider).spendInk(amount, reason: reason);
    state = state.copyWith(ink: ref.read(accountSaveProvider).loadInk());
  }

  Future<void> awardPaint(int amount, {String source = 'unknown'}) async {
    await ref.read(accountSaveProvider).awardPaint(amount, source: source);
    state = state.copyWith(paint: ref.read(accountSaveProvider).loadPaint());
  }

  Future<void> spendPaint(int amount, {String reason = 'unknown'}) async {
    if (state.paint < amount) {
      throw InsufficientFundsException('paint');
    }
    await ref.read(accountSaveProvider).spendPaint(amount, reason: reason);
    state = state.copyWith(paint: ref.read(accountSaveProvider).loadPaint());
  }

  Future<void> addAccountXp(int xp) async {
    final sm = ref.read(accountSaveProvider);
    await sm.addAccountXp(xp);
    state = state.copyWith(
      accountLevel: sm.loadAccountLevel(),
      accountXp: sm.loadAccountXp(),
    );
  }

  Future<void> unlockCharacter(String characterId) async {
    await ref.read(accountSaveProvider).unlockCharacter(characterId);
    if (!state.unlockedCharacters.contains(characterId)) {
      state = state.copyWith(
        unlockedCharacters: [...state.unlockedCharacters, characterId],
      );
    }
  }

  Future<void> saveInventory(List<String> items) async {
    await ref.read(accountSaveProvider).saveInventory(items);
    state = state.copyWith(inventory: items);
  }
}

final accountLevelProvider =
    NotifierProvider<AccountLevelNotifier, ({int accountLevel, int accountXp})>(
        AccountLevelNotifier.new);

class AccountLevelNotifier
    extends Notifier<({int accountLevel, int accountXp})> {
  @override
  ({int accountLevel, int accountXp}) build() {
    final acc = ref.watch(accountSaveNotifierProvider);
    return (accountLevel: acc.accountLevel, accountXp: acc.accountXp);
  }

  Future<void> addXp(int xp) =>
      ref.read(accountSaveNotifierProvider.notifier).addAccountXp(xp);
}

final unlockedCharactersProvider =
    NotifierProvider<UnlockedCharactersNotifier, List<String>>(
        UnlockedCharactersNotifier.new);

class UnlockedCharactersNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => ref
      .watch(accountSaveNotifierProvider.select((s) => s.unlockedCharacters));
  Future<void> unlock(String id) =>
      ref.read(accountSaveNotifierProvider.notifier).unlockCharacter(id);
}

final equippedCharacterIdProvider =
    NotifierProvider<EquippedCharacterNotifier, String>(
        EquippedCharacterNotifier.new);

class EquippedCharacterNotifier extends Notifier<String> {
  @override
  String build() {
    ref.watch(saveSyncReadyProvider);
    final sm = ref.read(accountSaveProvider);
    return sm.loadEquippedCharacter() ?? 'arthur';
  }

  Future<void> setEquippedCharacter(String characterId) async {
    await ref.read(accountSaveProvider).saveEquippedCharacter(characterId);
    state = characterId;
  }
}
