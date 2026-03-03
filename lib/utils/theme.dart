import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors (Emerald)
  static const Color primary = Color(0xFF15803D); // Emerald 700
  static const Color primaryDark = Color(0xFF14532D); // Emerald 900
  static const Color primaryLight = Color(0xFF22C55E); // Emerald 500

  // Light Mode Palette (Slate)
  static const Color lBackground = Color(0xFFF8FAFC); // Slate 50
  static const Color lSurface = Color(0xFFFFFFFF);
  static const Color lDivider = Color(0xFFE2E8F0); // Slate 200
  static const Color lTextPrimary = Color(0xFF0F172A); // Slate 900
  static const Color lTextSecondary = Color(0xFF64748B); // Slate 500

  // Dark Mode Palette (Slate)
  static const Color dBackground = Color(0xFF0F172A); // Slate 900
  static const Color dSurface = Color(0xFF1E293B); // Slate 800
  static const Color dDivider = Color(0xFF334155); // Slate 700
  static const Color dTextPrimary = Color(0xFFF1F5F9); // Slate 100
  static const Color dTextSecondary = Color(0xFF94A3B8); // Slate 400

  // Status Colors
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color success = Color(0xFF22C55E); // Emerald 500

  static const double borderRadius = 12.0;
  static const double buttonHeight = 42.0;

  // ─── LIGHT THEME ─────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lBackground,
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: primary,
        surface: lSurface,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: lTextPrimary,
        outline: lDivider,
      ),
      fontFamily: 'Outfit',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: lTextPrimary, size: 20),
        titleTextStyle: TextStyle(
          color: lTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: lDivider,
        thickness: 1,
        space: 1,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: lTextPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
        ),
        bodyLarge: TextStyle(
          color: lTextPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        bodySmall: TextStyle(
          color: lTextSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      cardTheme: CardThemeData(
        color: lSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: const BorderSide(color: lDivider, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style:
            ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size.fromHeight(buttonHeight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ).copyWith(
              overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
                if (states.contains(WidgetState.pressed)) {
                  return primaryDark.withValues(alpha: 0.1);
                }
                return null;
              }),
            ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lTextPrimary,
          side: const BorderSide(color: lDivider),
          minimumSize: const Size.fromHeight(buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: lDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: lDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: primary, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: error),
        ),
        labelStyle: const TextStyle(color: lTextSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: lTextSecondary, fontSize: 14),
        prefixIconColor: lTextSecondary,
        suffixIconColor: lTextSecondary,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: TextStyle(
          color: lTextPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: TextStyle(color: lTextSecondary, fontSize: 13),
      ),
    );
  }

  // ─── DARK THEME ──────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: dBackground,
      primaryColor: primaryLight,
      colorScheme: const ColorScheme.dark(
        primary: primaryLight,
        secondary: primaryLight,
        surface: dSurface,
        error: error,
        onPrimary: lTextPrimary,
        onSecondary: lTextPrimary,
        onSurface: dTextPrimary,
        outline: dDivider,
      ),
      fontFamily: 'Outfit',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: dTextPrimary, size: 20),
        titleTextStyle: TextStyle(
          color: dTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: dDivider,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: dSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: const BorderSide(color: dDivider, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: lTextPrimary,
          elevation: 0,
          minimumSize: const Size.fromHeight(buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: dTextPrimary,
          side: const BorderSide(color: dDivider),
          minimumSize: const Size.fromHeight(buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: dDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: dDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: primaryLight, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: error),
        ),
        labelStyle: const TextStyle(color: dTextSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: dTextSecondary, fontSize: 14),
        prefixIconColor: dTextSecondary,
        suffixIconColor: dTextSecondary,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: TextStyle(
          color: dTextPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: TextStyle(color: dTextSecondary, fontSize: 13),
      ),
    );
  }

  // Compatibility members (Aliases to be removed after screen refactor)
  static const Color accent = primaryLight;
  static const Color background = lBackground;
  static const Color surface = lSurface;
  static const Color textSecondary = lTextSecondary;

  static const List<BoxShadow> premiumShadow = [];
}
