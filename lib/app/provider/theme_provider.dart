import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get getThemeMode => _themeMode;

  void setThemeModeTo(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}