import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFFF5F5F7);
  static const Color surface = Colors.white;
  static const Color primary = Color(0xFF1C1C1E);
  static const Color textPrimary = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color border = Color(0xFFE5E5EA);

  // Status colours
  static const Color todoColor = Color(0xFF3B82F6);
  static const Color todoBackground = Color(0xFFEFF6FF);
  static const Color doingColor = Color(0xFFF59E0B);
  static const Color doingBackground = Color(0xFFFFFBEB);
  static const Color doneColor = Color(0xFF10B981);
  static const Color doneBackground = Color(0xFFECFDF5);

  // Default category palette (colorValue → Color)
  static const List<int> categoryPalette = [
    0xFFEF4444, // red
    0xFFF97316, // orange
    0xFFEAB308, // yellow
    0xFF22C55E, // green
    0xFF3B82F6, // blue
    0xFF8B5CF6, // purple
    0xFFEC4899, // pink
    0xFF6B7280, // gray
  ];

  static ({String label, Color color, Color bg}) statusStyle(String status) {
    return switch (status) {
      'doing' => (
          label: 'Doing',
          color: doingColor,
          bg: doingBackground,
        ),
      'done' => (
          label: 'Done',
          color: doneColor,
          bg: doneBackground,
        ),
      _ => (
          label: 'To Do',
          color: todoColor,
          bg: todoBackground,
        ),
    };
  }

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        surface: surface,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        indicatorColor: primary.withAlpha(20),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: const TextStyle(color: textSecondary, fontSize: 15),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          elevation: 0,
          textStyle: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
