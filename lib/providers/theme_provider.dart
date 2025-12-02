import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadTheme();  // Load on startup
  }

  void toggleTheme() async {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    _saveTheme();  // Save after toggle
  }

  // Save theme to SharedPreferences
  void _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', isDarkMode);
  }

  // Load theme from SharedPreferences
  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIsDark = prefs.getBool('isDarkMode');

    if (savedIsDark != null) {
      _themeMode = savedIsDark ? ThemeMode.dark : ThemeMode.light;
      notifyListeners();
    }
  }
}
