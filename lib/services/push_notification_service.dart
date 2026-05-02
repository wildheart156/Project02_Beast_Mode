import 'dart:async';

import 'package:beast_mode_fitness/app/app_navigation.dart';
import 'package:beast_mode_fitness/firebase_options.dart';
import 'package:beast_mode_fitness/screens/notifications_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _initialized = false;
  String? _activeUserId;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleMessageOpenedApp(initialMessage);
      });
    }

    _initialized = true;
  }

  Future<void> activateForUser(String userId) async {
    await initialize();
    _activeUserId = userId;

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    final permissionGranted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
    if (!permissionGranted) {
      return;
    }

    final token = await _messaging.getToken();
    if (token != null) {
      debugPrint('FCM token: $token');
      await _saveToken(userId, token);
    } else {
      debugPrint('FCM token was null.');
    }

    _tokenRefreshSubscription ??= _messaging.onTokenRefresh.listen((token) {
      final activeUserId = _activeUserId;
      if (activeUserId == null) {
        return;
      }

      debugPrint('FCM token refreshed: $token');
      unawaited(_saveToken(activeUserId, token));
    });
  }

  void clearActiveUser() {
    _activeUserId = null;
  }

  Future<void> _saveToken(String userId, String token) async {
    await _firestore
        .collection('Users')
        .doc(userId)
        .collection('FcmTokens')
        .doc(token)
        .set({
          'token': token,
          'platform': defaultTargetPlatform.name,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final title = notification?.title ?? 'New notification';
    final body =
        notification?.body ??
        (message.data['message'] as String?) ??
        'Open Alerts to view the latest update.';

    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger == null) {
      return;
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$title\n$body'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: _openNotificationsScreen,
          ),
        ),
      );
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    _openNotificationsScreen();
  }

  void _openNotificationsScreen() {
    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    final route = MaterialPageRoute<void>(
      builder: (context) => const NotificationsScreen(
        title: 'Notifications',
        description: 'Alerts, reminders, and feedback updates will appear here.',
        icon: Icons.notifications_none_rounded,
      ),
    );

    navigator.push(route);
  }
}
