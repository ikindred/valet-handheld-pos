import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kDarkModeKey = 'spid_dark_mode';

/// Holds the app-wide [ThemeMode] and persists the user's preference.
class ThemeNotifier extends ChangeNotifier {
  ThemeNotifier._(this._isDark);

  bool _isDark;

  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  /// Load the persisted preference (defaults to light).
  static Future<ThemeNotifier> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ThemeNotifier._(prefs.getBool(_kDarkModeKey) ?? false);
  }

  Future<void> setDark(bool value) async {
    if (_isDark == value) return;
    _isDark = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDarkModeKey, value);
  }
}
