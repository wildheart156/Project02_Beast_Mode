import 'package:beast_mode_fitness/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defaults to light mode when no preference exists', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final controller = BeastModeThemeController(preferences: preferences);

    await controller.load();

    expect(controller.themeMode, ThemeMode.light);
    expect(controller.isDarkMode, isFalse);
  });

  test('loads saved dark mode', () async {
    SharedPreferences.setMockInitialValues({
      'beast_mode_theme_mode': ThemeMode.dark.name,
    });
    final preferences = await SharedPreferences.getInstance();
    final controller = BeastModeThemeController(preferences: preferences);

    await controller.load();

    expect(controller.themeMode, ThemeMode.dark);
    expect(controller.isDarkMode, isTrue);
  });

  test('toggle changes mode and persists it', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final controller = BeastModeThemeController(preferences: preferences);
    await controller.load();

    await controller.toggleTheme();

    expect(controller.themeMode, ThemeMode.dark);
    expect(preferences.getString('beast_mode_theme_mode'), ThemeMode.dark.name);

    await controller.toggleTheme();

    expect(controller.themeMode, ThemeMode.light);
    expect(
      preferences.getString('beast_mode_theme_mode'),
      ThemeMode.light.name,
    );
  });
}
