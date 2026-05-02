import 'package:beast_mode_fitness/app/beast_mode_app.dart';
import 'package:beast_mode_fitness/app/firebase_bootstrap.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  runApp(const BeastModeApp());
}
