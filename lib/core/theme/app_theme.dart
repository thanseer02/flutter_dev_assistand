import 'package:flutter/material.dart';

class AppTheme {
  // Modern VS Code-like colors
  static const Color primaryColor = Color(0xFF007ACC); // VS Code Blue
  static const Color darkBackground = Color(0xFF1E1E1E);
  static const Color darkSurface = Color(0xFF252526);
  static const Color darkSidebar = Color(0xFF333333);
  static const Color darkDivider = Color(0xFF454545);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        surface: darkSurface,
        background: darkBackground,
      ),
      dividerColor: darkDivider,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: darkSurface,
      ),
      iconTheme: const IconThemeData(
        color: Color(0xFFCCCCCC),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Color(0xFFCCCCCC)),
        bodySmall: TextStyle(color: Color(0xFF999999)),
      ),
      // Set default rounding for modern look
      cardTheme: CardTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: darkDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: darkDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: primaryColor),
        ),
        filled: true,
        fillColor: darkBackground,
      ),
    );
  }
}
