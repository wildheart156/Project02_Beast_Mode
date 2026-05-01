import 'package:beast_mode_fitness/app/auth_gate.dart';
import 'package:beast_mode_fitness/theme/beast_mode_theme.dart';
import 'package:flutter/material.dart';

class BeastModeApp extends StatelessWidget {
  const BeastModeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beast Mode',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: BeastModeColors.ash,
        colorScheme: ColorScheme.fromSeed(
          seedColor: BeastModeColors.flame,
          primary: BeastModeColors.flame,
          secondary: BeastModeColors.volt,
          surface: BeastModeColors.surface,
          onPrimary: Colors.white,
          onSecondary: BeastModeColors.graphite,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: BeastModeColors.graphite,
          elevation: 0,
        ),
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: BeastModeColors.graphite,
          displayColor: BeastModeColors.graphite,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: BeastModeColors.flame,
          linearTrackColor: BeastModeColors.flameSoft,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: BeastModeColors.flame,
            foregroundColor: Colors.white,
            disabledBackgroundColor: BeastModeColors.steelLight,
            disabledForegroundColor: BeastModeColors.steel,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: BeastModeColors.graphite,
            side: const BorderSide(color: BeastModeColors.steelLight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: BeastModeColors.flame),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: BeastModeColors.graphite,
          contentTextStyle: TextStyle(color: Colors.white),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: BeastModeColors.surface,
          hintStyle: const TextStyle(
            color: BeastModeColors.steel,
            fontWeight: FontWeight.w400,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 13,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: BeastModeColors.steelLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: BeastModeColors.steelLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: BeastModeColors.flame,
              width: 1.7,
            ),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}
