class AccountSyncState {
  final Map<String, bool> dirtyFlags;
  final DateTime lastSyncDate;

  const AccountSyncState({
    this.dirtyFlags = const {},
    required this.lastSyncDate,
  });

  AccountSyncState copyWith({
    Map<String, bool>? dirtyFlags,
    DateTime? lastSyncDate,
  }) {
    return AccountSyncState(
      dirtyFlags: dirtyFlags ?? this.dirtyFlags,
      lastSyncDate: lastSyncDate ?? this.lastSyncDate,
    );
  }

  bool get isDirtyToday {
    final now = DateTime.now();
    return lastSyncDate.year != now.year ||
        lastSyncDate.month != now.month ||
        lastSyncDate.day != now.day;
  }
}
