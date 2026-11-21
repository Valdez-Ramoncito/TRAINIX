import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists and broadcasts ThemeMode. Default is Dark.
class ThemeController extends ChangeNotifier {
  static const _prefsKey = 'settings_theme_mode';

  ThemeMode _mode = ThemeMode.dark;

  ThemeMode get mode => _mode;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    switch (raw) {
      case 'light':
        _mode = ThemeMode.light;
        break;
      case 'system':
        _mode = ThemeMode.system;
        break;
      case 'dark':
      default:
        _mode = ThemeMode.dark;
        break;
    }
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
      ThemeMode.dark => 'dark',
    };
    await prefs.setString(_prefsKey, value);
  }
}
