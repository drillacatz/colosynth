import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

class AccountSyncService {
  AccountSyncService._();
  static final AccountSyncService instance = AccountSyncService._();

  static const Duration _kWriteCooldown = Duration(seconds: 300);

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? _uid;

  bool _isDirty = false;
  DateTime? _lastWriteTime;

  Timer? _cooldownTimer;

  final Map<String, dynamic> _pending = {};
  final Map<String, dynamic> _lastSyncedValues = {};
  Future<void>? _activeWrite;

  void bindUser(String uid) {
    if (_uid != uid) {
      _lastSyncedValues.clear();
    }
    _uid = uid;
    _cancelTimers();
    if (_pending.isNotEmpty) {
      _isDirty = true;
      flushMilestone();
    }
  }

  Future<void> unbindUser() async {
    _cancelTimers();
    await flushNow();
    _uid = null;
    _isDirty = false;
    _lastSyncedValues.clear();
  }

  void push(Map<String, dynamic> fields, {bool immediate = false}) {
    bool hasNewChanges = false;
    for (final entry in fields.entries) {
      final key = entry.key;
      final val = entry.value;
      if (!_isEqualValue(_lastSyncedValues[key], val)) {
        _pending[key] = val;
        hasNewChanges = true;
      }
    }

    if (!hasNewChanges && _pending.isEmpty) {
      return;
    }

    _isDirty = true;
    if (immediate) {
      unawaited(flushNow());
    } else {
      unawaited(flushMilestone());
    }
  }

  bool _isEqualValue(dynamic a, dynamic b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return a == b;
    if (a is Map && b is Map) {
      return const MapEquality().equals(a, b);
    }
    if (a is List && b is List) {
      return const ListEquality().equals(a, b);
    }
    if (a is Set && b is Set) {
      return const SetEquality().equals(a, b);
    }
    return a == b;
  }

  /// Flushes pending changes to Firestore immediately, bypassing any write cooldown.
  /// Used for critical transitions like app backgrounding or user logging out.
  Future<void> flushNow() async {
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
    await _flush();
  }

  /// Flushes pending changes if marked dirty, respecting the minimum write cooldown.
  /// If called during a cooldown, schedules a deferred write for when the cooldown expires.
  Future<void> flushMilestone() async {
    if (_uid == null || _uid == 'local_guest_offline' || !_isDirty || _pending.isEmpty) return;

    final now = DateTime.now();
    final lastWrite = _lastWriteTime;
    if (lastWrite != null) {
      final elapsed = now.difference(lastWrite);
      if (elapsed < _kWriteCooldown) {
        final remaining = _kWriteCooldown - elapsed;
        if (_cooldownTimer == null) {
          debugPrint('AccountSyncService: Cooldown active. Deferring milestone flush by ${remaining.inSeconds} seconds.');
          _cooldownTimer = Timer(remaining, () {
            _cooldownTimer = null;
            if (_isDirty) {
              _flush();
            }
          });
        }
        return;
      }
    }

    await _flush();
  }

  void _cancelTimers() {
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
  }

  void dispose() {
    _cancelTimers();
  }

  Future<void> _flush() async {
    if (_uid == null || _uid == 'local_guest_offline' || _pending.isEmpty) return;

    if (_activeWrite != null) {
      await _activeWrite;
      if (_pending.isNotEmpty) {
        return _flush();
      }
      return;
    }

    final completer = Completer<void>();
    _activeWrite = completer.future;

    try {
      while (_pending.isNotEmpty) {
        final payload = Map<String, dynamic>.from(_pending);
        _pending.clear();

        try {
          debugPrint('AccountSyncService: Syncing ${payload.keys.length} changed fields to users/$_uid...');
          await _db.collection('users').doc(_uid).set({
            ...payload,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          _lastSyncedValues.addAll(payload);
          _isDirty = false;
          _lastWriteTime = DateTime.now();
        } catch (e) {
          debugPrint('AccountSyncService: Cloud sync failed: $e');
          _pending.addAll(payload);
          break;
        }
      }
    } finally {
      _activeWrite = null;
      completer.complete();
    }
  }
}

