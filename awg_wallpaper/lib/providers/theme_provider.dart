import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

/// ThemeProvider manages the app's theme state (light/dark mode).
/// Dark mode is a Pro-only feature - free users see the feature locked.
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  late Box _box;
  bool _isInitialized = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isInitialized => _isInitialized;

  ThemeProvider() {
    _initBox();
  }

  Future<void> _initBox() async {
    _box = Hive.box('settings');
    _loadThemePreference();
    _isInitialized = true;
    notifyListeners();
  }

  void _loadThemePreference() {
    final savedTheme = _box.get('themeMode', defaultValue: 'light') as String;
    _themeMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.dark;
  }

  Future<void> _saveThemePreference() async {
    await _box.put(
        'themeMode', _themeMode == ThemeMode.dark ? 'dark' : 'light');
  }

  /// Toggle dark mode.
  /// Returns true if the toggle was successful.
  Future<bool> toggleDarkMode() async {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await _saveThemePreference();
    notifyListeners();
    return true;
  }

  /// Set dark mode explicitly.
  Future<bool> setDarkMode(bool enabled) async {
    _themeMode = enabled ? ThemeMode.dark : ThemeMode.light;
    await _saveThemePreference();
    notifyListeners();
    return true;
  }

  /// Force light mode (used when user's Pro subscription expires)
  Future<void> forceToLightMode() async {
    _themeMode = ThemeMode.dark;
    await _saveThemePreference();
    notifyListeners();
  }
}
