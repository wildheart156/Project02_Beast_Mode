import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BeastModeThemeController extends ChangeNotifier {
  BeastModeThemeController({SharedPreferences? preferences})
    : _preferences = preferences;

  static const _themeModeKey = 'beast_mode_theme_mode';

  SharedPreferences? _preferences;
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> load() async {
    _preferences ??= await SharedPreferences.getInstance();
    final savedThemeMode = _preferences?.getString(_themeModeKey);
    _themeMode = savedThemeMode == ThemeMode.dark.name
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    _preferences ??= await SharedPreferences.getInstance();
    await _preferences?.setString(_themeModeKey, _themeMode.name);
  }
}

class ThemeControllerScope extends InheritedNotifier<BeastModeThemeController> {
  const ThemeControllerScope({
    super.key,
    required BeastModeThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static BeastModeThemeController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ThemeControllerScope>();
    assert(scope != null, 'No ThemeControllerScope found in context.');
    return scope!.notifier!;
  }
}
