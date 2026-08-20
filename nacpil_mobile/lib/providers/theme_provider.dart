import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  static final Color _green = Colors.green.shade700;
  static final Color _darkGreen = Colors.green.shade300;

  bool _isDark = false;
  bool get isDark => _isDark;

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }

  ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _green,
      brightness: Brightness.light,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: _green,
        unselectedItemColor: Colors.grey.shade600,
        backgroundColor: colorScheme.surface,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _green,
        foregroundColor: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _green,
        foregroundColor: Colors.white,
      ),
    );
  }

  ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _darkGreen,
      brightness: Brightness.dark,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: _darkGreen,
        unselectedItemColor: Colors.grey.shade400,
        backgroundColor: colorScheme.surface,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _darkGreen,
        foregroundColor: Colors.black,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.green.shade900,
        foregroundColor: Colors.white,
      ),
    );
  }
}
