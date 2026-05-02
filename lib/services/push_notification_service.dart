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
  // Background FCM handlers run in their own isolate and need Firebase set up.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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

    // iOS/macOS need presentation options for notifications while foregrounded.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // If a notification launched the app from a terminated state, route after the navigator exists
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

    // Permission is requested only once the app knows which user owns the token
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
      // Tokens are stored per user so Cloud Functions can fan out pushes
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
      // Refreshes can happen anytime; write against the latest signed-in user
      unawaited(_saveToken(activeUserId, token));
    });
  }

  void clearActiveUser() {
    _activeUserId = null;
  }

  Future<void> _saveToken(String userId, String token) async {
    // Use the token as the document id to make duplicate registration idempotent
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

    // Foreground pushes become an in-app snackbar with the same destination
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
    // All current push types land in the notification center
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
        description:
            'Alerts, reminders, and feedback updates will appear here.',
        icon: Icons.notifications_none_rounded,
      ),
    );

    navigator.push(route);
  }
}
