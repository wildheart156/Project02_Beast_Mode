import 'package:beast_mode_fitness/app/auth_gate.dart';
import 'package:beast_mode_fitness/app/app_navigation.dart';
import 'package:beast_mode_fitness/theme/beast_mode_theme.dart';
import 'package:beast_mode_fitness/theme/theme_controller.dart';
import 'package:flutter/material.dart';

class BeastModeApp extends StatefulWidget {
  const BeastModeApp({super.key, required this.themeController});

  final BeastModeThemeController themeController;

  @override
  State<BeastModeApp> createState() => _BeastModeAppState();
}

class _BeastModeAppState extends State<BeastModeApp> {
  @override
  void initState() {
    super.initState();
    widget.themeController.addListener(_handleThemeChanged);
  }

  @override
  void didUpdateWidget(covariant BeastModeApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.themeController != widget.themeController) {
      oldWidget.themeController.removeListener(_handleThemeChanged);
      widget.themeController.addListener(_handleThemeChanged);
    }
  }

  @override
  void dispose() {
    widget.themeController.removeListener(_handleThemeChanged);
    super.dispose();
  }

  void _handleThemeChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return ThemeControllerScope(
      controller: widget.themeController,
      child: MaterialApp(
        title: 'Beast Mode',
        debugShowCheckedModeBanner: false,
        navigatorKey: rootNavigatorKey,
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        theme: BeastModeTheme.light(),
        darkTheme: BeastModeTheme.dark(),
        themeMode: widget.themeController.themeMode,
        home: const AuthGate(),
      ),
    );
  }
}
