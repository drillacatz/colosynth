class PlayerAccount {
  final String uid;
  final int ink;
  final int paint;
  final int accountLevel;
  final int accountXp;
  final List<String> unlockedCharIds;
  final String equippedCharId;
  final Map<String, int> inventory;
  final Map<String, int> expItems;
  final Map<String, String> tournamentProgress;

  const PlayerAccount({
    required this.uid,
    required this.ink,
    required this.paint,
    required this.accountLevel,
    required this.accountXp,
    required this.unlockedCharIds,
    required this.equippedCharId,
    required this.inventory,
    required this.expItems,
    required this.tournamentProgress,
  });

  PlayerAccount copyWith({
    String? uid,
    int? ink,
    int? paint,
    int? accountLevel,
    int? accountXp,
    List<String>? unlockedCharIds,
    String? equippedCharId,
    Map<String, int>? inventory,
    Map<String, int>? expItems,
    Map<String, String>? tournamentProgress,
  }) {
    return PlayerAccount(
      uid: uid ?? this.uid,
      ink: ink ?? this.ink,
      paint: paint ?? this.paint,
      accountLevel: accountLevel ?? this.accountLevel,
      accountXp: accountXp ?? this.accountXp,
      unlockedCharIds: unlockedCharIds ?? this.unlockedCharIds,
      equippedCharId: equippedCharId ?? this.equippedCharId,
      inventory: inventory ?? this.inventory,
      expItems: expItems ?? this.expItems,
      tournamentProgress: tournamentProgress ?? this.tournamentProgress,
    );
  }

  Map<String, dynamic> toImmediateSyncFields() {
    return {
      'ink': ink,
      'paint': paint,
      'accountLevel': accountLevel,
      'accountXp': accountXp,
      'unlockedCharacters': unlockedCharIds,
      'equippedCharacter': equippedCharId,
      'tournamentProgress': tournamentProgress,
    };
  }

  factory PlayerAccount.fromFirestore(Map<String, dynamic> doc) {
    return PlayerAccount(
      uid: doc['uid'] as String? ?? '',
      ink: (doc['ink'] as num?)?.toInt() ?? 0,
      paint: (doc['paint'] as num?)?.toInt() ?? 0,
      accountLevel: (doc['accountLevel'] as num?)?.toInt() ?? 1,
      accountXp: (doc['accountXp'] as num?)?.toInt() ?? 0,
      unlockedCharIds: List<String>.from(doc['unlockedCharacters'] ?? []),
      equippedCharId: doc['equippedCharacter'] as String? ?? '',
      inventory: Map<String, int>.from(doc['inventory'] ?? {}),
      expItems: Map<String, int>.from(doc['expItems'] ?? {}),
      tournamentProgress: Map<String, String>.from(doc['tournamentProgress'] ?? {}),
    );
  }
}
