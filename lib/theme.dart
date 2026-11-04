import 'package:flutter/material.dart';

/// App theme — keeps the original brand blue (#0066CC) on a clean
/// Material 3 surface.
class AppTheme {
  static const Color primary = Color(0xFF0066CC);
  static const Color secondary = Color(0xFF3384D6);
  static const Color background = Color(0xFFF5F5F7);
  static const Color error = Color(0xFFFF3B30);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      surface: Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'OpenSans',
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: Color(0xFF1D1D1F),
        elevation: 0,
        centerTitle: false,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      chipTheme: ChipThemeData(
        selectedColor: primary,
        labelStyle: const TextStyle(fontSize: 13),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }
}
