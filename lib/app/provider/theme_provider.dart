import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get getThemeMode => _themeMode;

  /// Load saved theme from SharedPreferences
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedThemeIndex = prefs.getInt(_themeModeKey);

    if (savedThemeIndex != null) {
      _themeMode = ThemeMode.values[savedThemeIndex];
      notifyListeners();
    }
  }

  /// Set theme mode and save to SharedPreferences
  Future<void> setThemeModeTo(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
  }
}
