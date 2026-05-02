import 'package:beast_mode_fitness/app/beast_mode_app.dart';
import 'package:beast_mode_fitness/app/firebase_bootstrap.dart';
import 'package:beast_mode_fitness/services/push_notification_service.dart';
import 'package:beast_mode_fitness/theme/theme_controller.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  // Register the top-level FCM handler before the app starts so background messages can wake the isolate safely
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  final themeController = BeastModeThemeController();
  await themeController.load();
  runApp(BeastModeApp(themeController: themeController));
}
