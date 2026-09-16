import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  debugPrint('FCM background: ${message.messageId}');
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _local = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _tapSub;

  static const _channelId = 'colosynth_main';
  static const _channelName = 'Colosynth';

  Future<void> init() async {
    if (_initialized) return;
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    try {
      FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);
      await _setupLocalNotifications();
      _listenForeground();
      _listenTaps();

      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleMessage(initialMessage, 'initial');
      }

      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService.init error: $e');
    }
  }

  Future<void> _setupLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/app_icon');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _local.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Local notification tapped: ${response.payload}');
      },
    );
    if (Platform.isAndroid) {
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelId,
              _channelName,
              importance: Importance.high,
              description: 'Main channel for Colosynth notifications',
            ),
          );
    }
  }

  void _listenForeground() {
    _foregroundSub = FirebaseMessaging.onMessage.listen((message) {
      _handleMessage(message, 'foreground');
    });
  }

  void _listenTaps() {
    _tapSub = FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleMessage(message, 'tap');
    });
  }

  void _handleMessage(RemoteMessage message, String source) {
    final n = message.notification;
    if (n == null) return;

    if (source == 'foreground') {
      _local.show(
        id: n.hashCode,
        title: n.title,
        body: n.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'Colosynth notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    }
  }

  bool get isInitialized => _initialized;

  void dispose() {
    _foregroundSub?.cancel();
    _tapSub?.cancel();
  }
}

final notificationServiceProvider =
    Provider<NotificationService>((_) => NotificationService.instance);
