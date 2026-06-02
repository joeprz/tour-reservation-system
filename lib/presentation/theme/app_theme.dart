// lib/presentation/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // ─── Brand colors ──────────────────────────────────────────────────────────
  static const Color forestGreen = Color(0xFF1B4332);
  static const Color deepForest = Color(0xFF0D2B1F);
  static const Color leafGreen = Color(0xFF40916C);
  static const Color mintGreen = Color(0xFF74C69D);
  static const Color goldenFirefly = Color(0xFFF4D03F);
  static const Color warmAmber = Color(0xFFE9AA24);
  static const Color softCream = Color(0xFFFFFBF0);
  static const Color darkSlate = Color(0xFF1A1A2E);

  // ─── Status colors ─────────────────────────────────────────────────────────
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusConfirmed = Color(0xFF3B82F6);
  static const Color statusCheckedIn = Color(0xFF10B981);
  static const Color statusCancelled = Color(0xFFEF4444);
  static const Color statusNoShow = Color(0xFF6B7280);

  // ─── Light Theme ───────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: forestGreen,
      brightness: Brightness.light,
      primary: forestGreen,
      secondary: goldenFirefly,
      tertiary: leafGreen,
      surface: softCream,
      background: const Color(0xFFF5F7F0),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Nunito',
      scaffoldBackgroundColor: const Color(0xFFF0F4EE),

      appBarTheme: const AppBarTheme(
        backgroundColor: forestGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),

      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: forestGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: forestGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: forestGreen, width: 2),
        ),
        labelStyle: const TextStyle(fontFamily: 'Nunito'),
        hintStyle: const TextStyle(fontFamily: 'Nunito', color: Colors.grey),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      textTheme: _buildTextTheme(Brightness.light),
    );
  }

  // ─── Dark Theme ────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: forestGreen,
      brightness: Brightness.dark,
      primary: mintGreen,
      secondary: goldenFirefly,
      tertiary: leafGreen,
      surface: const Color(0xFF1E2D24),
      background: darkSlate,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Nunito',
      scaffoldBackgroundColor: darkSlate,

      appBarTheme: AppBarTheme(
        backgroundColor: deepForest,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),

      cardTheme: CardThemeData(
        color: const Color(0xFF1E2D24),
        elevation: 2,
        shadowColor: Colors.black45,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: mintGreen,
          foregroundColor: deepForest,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E2D24),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2D4A38)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2D4A38)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: mintGreen, width: 2),
        ),
        labelStyle: const TextStyle(fontFamily: 'Nunito', color: Colors.white70),
        hintStyle: const TextStyle(fontFamily: 'Nunito', color: Colors.white38),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      textTheme: _buildTextTheme(Brightness.dark),
    );
  }

  static TextTheme _buildTextTheme(Brightness brightness) {
    final color = brightness == Brightness.light ? Colors.black87 : Colors.white;
    return TextTheme(
      displayLarge: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800, color: color),
      displayMedium: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800, color: color),
      headlineLarge: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, color: color),
      headlineMedium: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, color: color),
      headlineSmall: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, color: color),
      titleLarge: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, color: color),
      titleMedium: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600, color: color),
      bodyLarge: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w400, color: color),
      bodyMedium: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w400, color: color),
      labelLarge: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, color: color),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  static Color statusColor(String status) {
    switch (status) {
      case 'pending': return statusPending;
      case 'confirmed': return statusConfirmed;
      case 'checked_in': return statusCheckedIn;
      case 'cancelled': return statusCancelled;
      case 'no_show': return statusNoShow;
      default: return Colors.grey;
    }
  }
}
