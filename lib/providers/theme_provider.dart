import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _isDarkModeKey = 'is_dark_mode';
  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_isDarkModeKey) ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme preference: $e');
    }
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isDarkModeKey, _isDarkMode);
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
    notifyListeners();
  }

  ThemeData getTheme() {
    return _isDarkMode ? _getDarkTheme() : _getLightTheme();
  }

  // Dark theme configuration
  ThemeData _getDarkTheme() {
    const primaryColor = Color(0xFF7C4DFF);
    const secondaryColor = Color(0xFF00E5FF);
    const tertiaryColor = Color(0xFFFFD54F);
    const backgroundColor = Color(0xFF121212);
    const surfaceColor = Color(0xFF1F1F1F);
    const errorColor = Color(0xFFFF5252);

    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: tertiaryColor,
        surface: surfaceColor,
        background: backgroundColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Colors.white,
        onBackground: Colors.white,
        onError: Colors.black,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: _buildDarkAppBarTheme(),
      cardTheme: _buildDarkCardTheme(),
      floatingActionButtonTheme: _buildDarkFabTheme(),
      inputDecorationTheme: _buildDarkInputTheme(),
      elevatedButtonTheme: _buildDarkButtonTheme(),
    );
  }

  // Light theme configuration
  ThemeData _getLightTheme() {
    const primaryColor = Color(0xFF6200EE);
    const secondaryColor = Color(0xFF03DAC6);
    const tertiaryColor = Color(0xFFFFB400);
    const backgroundColor = Color(0xFFF5F5F5);
    const surfaceColor = Colors.white;
    const errorColor = Color(0xFFB00020);

    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: tertiaryColor,
        surface: surfaceColor,
        background: backgroundColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Colors.black,
        onBackground: Colors.black,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: _buildLightAppBarTheme(),
      cardTheme: _buildLightCardTheme(),
      floatingActionButtonTheme: _buildLightFabTheme(),
      inputDecorationTheme: _buildLightInputTheme(),
      elevatedButtonTheme: _buildLightButtonTheme(),
    );
  }

  // Dark theme component styles
  AppBarTheme _buildDarkAppBarTheme() {
    return const AppBarTheme(
      backgroundColor: Color(0xFF1F1F1F),
      elevation: 0,
      centerTitle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  CardTheme _buildDarkCardTheme() {
    return CardTheme(
      color: const Color(0xFF1F1F1F),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  FloatingActionButtonThemeData _buildDarkFabTheme() {
    return const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF7C4DFF),
      foregroundColor: Colors.white,
      elevation: 8,
    );
  }

  InputDecorationTheme _buildDarkInputTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF7C4DFF), width: 2),
      ),
      labelStyle: const TextStyle(color: Colors.white70),
    );
  }

  ElevatedButtonThemeData _buildDarkButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF7C4DFF),
        foregroundColor: Colors.white,
        elevation: 4,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  // Light theme component styles
  AppBarTheme _buildLightAppBarTheme() {
    return const AppBarTheme(
      backgroundColor: Color(0xFF6200EE),
      elevation: 0,
      centerTitle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  CardTheme _buildLightCardTheme() {
    return CardTheme(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  FloatingActionButtonThemeData _buildLightFabTheme() {
    return const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF6200EE),
      foregroundColor: Colors.white,
      elevation: 6,
    );
  }

  InputDecorationTheme _buildLightInputTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6200EE), width: 2),
      ),
      labelStyle: const TextStyle(color: Colors.black54),
    );
  }

  ElevatedButtonThemeData _buildLightButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6200EE),
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}
