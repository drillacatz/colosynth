import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

class FcmService {
  FcmService._();
  static final instance = FcmService._();

  final _messaging = FirebaseMessaging.instance;
  StreamSubscription<String>? _tokenRefreshSub;
  String? _boundUid;

  Future<void> bindUser(String uid) async {
    if (_boundUid == uid) return;

    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    _boundUid = uid;

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    final token = await _messaging.getToken();
    if (token != null) {
      await _writeToken(uid, token);
    }

    _tokenRefreshSub = _messaging.onTokenRefresh.listen((newToken) {
      _writeToken(uid, newToken);
    });
  }

  Future<void> unbindUser(String uid) async {
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    _boundUid = null;

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fcmToken': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FcmService ▸ unbindUser error: $e');
    }
  }

  String? _lastWrittenToken;

  Future<void> _writeToken(String uid, String token) async {
    if (_lastWrittenToken == token) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _lastWrittenToken = token;
    } catch (e) {
      debugPrint('FcmService ▸ _writeToken error: $e');
    }
  }
}

final fcmServiceProvider = Provider<FcmService>((_) => FcmService.instance);
