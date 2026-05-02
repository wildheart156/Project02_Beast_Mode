import 'package:flutter/material.dart';

abstract final class BeastModeColors {
  static const graphite = Color(0xFF171C22);
  static const graphiteSoft = Color(0xFF252C34);
  static const graphiteLight = Color(0xFF3A424D);
  static const flame = Color(0xFFFF5A1F);
  static const flameDark = Color(0xFFE24412);
  static const flameSoft = Color(0xFFFFE7DD);
  static const volt = Color(0xFFC8FF2D);
  static const voltSoft = Color(0xFFF1FFD0);
  static const steel = Color(0xFF667085);
  static const steelLight = Color(0xFFD7DCE3);
  static const ash = Color(0xFFF3F5F8);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceWarm = Color(0xFFFFFAF7);
  static const divider = Color(0xFFE4E8EE);
}

abstract final class BeastModeTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: BeastModeColors.ash,
      cardColor: BeastModeColors.surface,
      dividerColor: BeastModeColors.divider,
      colorScheme: ColorScheme.fromSeed(
        seedColor: BeastModeColors.flame,
        brightness: Brightness.light,
        primary: BeastModeColors.flame,
        secondary: BeastModeColors.volt,
        surface: BeastModeColors.surface,
        onPrimary: Colors.white,
        onSecondary: BeastModeColors.graphite,
        onSurface: BeastModeColors.graphite,
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
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
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
      inputDecorationTheme: _inputDecorationTheme(
        fillColor: BeastModeColors.surface,
        hintColor: BeastModeColors.steel,
        borderColor: BeastModeColors.steelLight,
      ),
    );
  }

  static ThemeData dark() {
    const background = Color(0xFF0F1318);
    const surface = Color(0xFF1A2027);
    const surfaceHigh = Color(0xFF242B34);
    const text = Color(0xFFF4F7FB);
    const muted = Color(0xFFAEB7C4);
    const border = Color(0xFF3A424D);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      cardColor: surface,
      dividerColor: border,
      colorScheme: ColorScheme.fromSeed(
        seedColor: BeastModeColors.flame,
        brightness: Brightness.dark,
        primary: BeastModeColors.flame,
        secondary: BeastModeColors.volt,
        surface: surface,
        onPrimary: Colors.white,
        onSecondary: BeastModeColors.graphite,
        onSurface: text,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: text,
        elevation: 0,
      ),
      textTheme: ThemeData.dark().textTheme.apply(
        bodyColor: text,
        displayColor: text,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: BeastModeColors.flame,
        linearTrackColor: BeastModeColors.graphiteLight,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: BeastModeColors.flame,
          foregroundColor: Colors.white,
          disabledBackgroundColor: surfaceHigh,
          disabledForegroundColor: muted,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: BeastModeColors.flame),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: BeastModeColors.surface,
        contentTextStyle: TextStyle(color: BeastModeColors.graphite),
      ),
      inputDecorationTheme: _inputDecorationTheme(
        fillColor: surface,
        hintColor: muted,
        borderColor: border,
      ),
    );
  }

  static InputDecorationTheme _inputDecorationTheme({
    required Color fillColor,
    required Color hintColor,
    required Color borderColor,
  }) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      hintStyle: TextStyle(color: hintColor, fontWeight: FontWeight.w400),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: BeastModeColors.flame, width: 1.7),
      ),
    );
  }
}

extension BeastModeThemeColors on BuildContext {
  Color get beastModeTextColor => Theme.of(this).colorScheme.onSurface;

  Color get beastModeMutedTextColor {
    return Theme.of(this).brightness == Brightness.dark
        ? const Color(0xFFAEB7C4)
        : BeastModeColors.steel;
  }
}
