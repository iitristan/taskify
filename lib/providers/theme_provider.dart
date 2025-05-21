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
      // Handle error silently
    }
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isDarkModeKey, _isDarkMode);
    } catch (e) {
      // Handle error silently
    }
    notifyListeners();
  }

  ThemeData getTheme() {
    return _isDarkMode ? _getDarkTheme() : _getLightTheme();
  }

  // Dark theme colors
  static const _darkPrimaryColor = Color(0xFF5C3DB2);
  static const _darkSecondaryColor = Color(0xFF00B8CC);
  static const _darkTertiaryColor = Color(0xFFD9B846);
  static const _darkBackgroundColor = Color(0xFF121212);
  static const _darkSurfaceColor = Color(0xFF1F1F1F);
  static const _darkErrorColor = Color(0xFFE04646);

  // Light theme colors
  static const _lightPrimaryColor = Color(0xFF4A3387);
  static const _lightSecondaryColor = Color(0xFF00A99E);
  static const _lightTertiaryColor = Color(0xFFD99700);
  static const _lightBackgroundColor = Color(0xFFF8F9FA);
  static const _lightSurfaceColor = Colors.white;
  static const _lightErrorColor = Color(0xFF9C0018);

  // Dark theme configuration
  ThemeData _getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: _darkPrimaryColor,
        secondary: _darkSecondaryColor,
        tertiary: _darkTertiaryColor,
        surface: _darkSurfaceColor,
        background: _darkBackgroundColor,
        error: _darkErrorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Colors.white,
        onBackground: Colors.white,
        onError: Colors.black,
      ),
      scaffoldBackgroundColor: _darkBackgroundColor,
      appBarTheme: _buildDarkAppBarTheme(),
      cardTheme: _buildDarkCardTheme(),
      floatingActionButtonTheme: _buildDarkFabTheme(),
      inputDecorationTheme: _buildDarkInputTheme(),
      elevatedButtonTheme: _buildDarkButtonTheme(),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: _darkSurfaceColor,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: _darkPrimaryColor,
        dayStyle: const TextStyle(color: Colors.white),
        todayBorder: BorderSide(color: _darkPrimaryColor, width: 1),
      ),
    );
  }

  // Light theme configuration
  ThemeData _getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: _lightPrimaryColor,
        secondary: _lightSecondaryColor,
        tertiary: _lightTertiaryColor,
        surface: _lightSurfaceColor,
        background: _lightBackgroundColor,
        error: _lightErrorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Colors.black,
        onBackground: Colors.black,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: _lightBackgroundColor,
      appBarTheme: _buildLightAppBarTheme(),
      cardTheme: _buildLightCardTheme(),
      floatingActionButtonTheme: _buildLightFabTheme(),
      inputDecorationTheme: _buildLightInputTheme(),
      elevatedButtonTheme: _buildLightButtonTheme(),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: _lightSurfaceColor,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: _lightPrimaryColor,
        headerForegroundColor: Colors.white,
        todayBorder: BorderSide(color: _lightPrimaryColor, width: 1),
      ),
    );
  }

  // Dark theme component styles
  AppBarTheme _buildDarkAppBarTheme() {
    return const AppBarTheme(
      backgroundColor: _darkSurfaceColor,
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
      color: _darkSurfaceColor,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  FloatingActionButtonThemeData _buildDarkFabTheme() {
    return const FloatingActionButtonThemeData(
      backgroundColor: _darkPrimaryColor,
      foregroundColor: Colors.white,
      elevation: 8,
    );
  }

  InputDecorationTheme _buildDarkInputTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      floatingLabelStyle: TextStyle(
        color: _darkPrimaryColor.withOpacity(0.9),
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
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
        borderSide: const BorderSide(color: _darkPrimaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Color(0xFFE0A2A2), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Color(0xFFE0A2A2), width: 1.5),
      ),
      errorStyle: TextStyle(
        color: Color(0xFFE0A2A2),
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 0.8,
      ),
      labelStyle: const TextStyle(color: Colors.white70),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );
  }

  ElevatedButtonThemeData _buildDarkButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _darkPrimaryColor,
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
      backgroundColor: _lightPrimaryColor,
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
      color: _lightSurfaceColor,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  FloatingActionButtonThemeData _buildLightFabTheme() {
    return const FloatingActionButtonThemeData(
      backgroundColor: _lightPrimaryColor,
      foregroundColor: Colors.white,
      elevation: 6,
    );
  }

  InputDecorationTheme _buildLightInputTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      floatingLabelStyle: TextStyle(
        color: _lightPrimaryColor,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
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
        borderSide: const BorderSide(color: _lightPrimaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: _lightErrorColor.withOpacity(0.8),
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _lightErrorColor, width: 1.5),
      ),
      errorStyle: TextStyle(
        color: _lightErrorColor.withOpacity(0.9),
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 0.8,
      ),
      labelStyle: const TextStyle(color: Colors.black54),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );
  }

  ElevatedButtonThemeData _buildLightButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _lightPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}
