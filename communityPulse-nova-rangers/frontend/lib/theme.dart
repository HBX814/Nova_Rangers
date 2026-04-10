import 'package:flutter/material.dart';

/// CommunityPulse Material 3 theme definition.
///
/// Usage:
///   theme: AppTheme.light
abstract final class AppTheme {
  AppTheme._();

  static const _seedColor = Color(0xFF1565C0);
  static const _white = Colors.white;

  // ── Shared component themes ───────────────────────────────────────────────

  static final _cardTheme = CardThemeData(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    clipBehavior: Clip.antiAlias,
  );

  static final _appBarTheme = AppBarTheme(
    backgroundColor: _seedColor,
    foregroundColor: _white,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: const TextStyle(
      fontFamily: 'NotoSans',
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: _white,
    ),
  );

  static final _filledButtonTheme = FilledButtonThemeData(
    style: FilledButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );

  static final _inputDecorationTheme = InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _seedColor, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFC62828), width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  static const _textTheme = TextTheme(
    displayLarge:  TextStyle(fontFamily: 'NotoSans', fontWeight: FontWeight.w400),
    displayMedium: TextStyle(fontFamily: 'NotoSans', fontWeight: FontWeight.w400),
    displaySmall:  TextStyle(fontFamily: 'NotoSans', fontWeight: FontWeight.w400),
    headlineLarge:  TextStyle(fontFamily: 'NotoSans', fontWeight: FontWeight.w600),
    headlineMedium: TextStyle(fontFamily: 'NotoSans', fontWeight: FontWeight.w600),
    headlineSmall:  TextStyle(fontFamily: 'NotoSans', fontWeight: FontWeight.w600),
    titleLarge:  TextStyle(fontFamily: 'NotoSans', fontWeight: FontWeight.w600),
    titleMedium: TextStyle(fontFamily: 'NotoSans', fontWeight: FontWeight.w500),
    titleSmall:  TextStyle(fontFamily: 'NotoSans', fontWeight: FontWeight.w500),
    bodyLarge:   TextStyle(fontFamily: 'NotoSans', fontWeight: FontWeight.w400),
    bodyMedium:  TextStyle(fontFamily: 'NotoSans', fontWeight: FontWeight.w400),
    bodySmall:   TextStyle(fontFamily: 'NotoSans', fontWeight: FontWeight.w400),
    labelLarge:  TextStyle(fontFamily: 'NotoSans', fontWeight: FontWeight.w500),
    labelMedium: TextStyle(fontFamily: 'NotoSans', fontWeight: FontWeight.w500),
    labelSmall:  TextStyle(fontFamily: 'NotoSans', fontWeight: FontWeight.w400),
  );

  // ── Light theme ───────────────────────────────────────────────────────────

  static final light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    ),
    textTheme: _textTheme,
    cardTheme: _cardTheme,
    appBarTheme: _appBarTheme,
    filledButtonTheme: _filledButtonTheme,
    inputDecorationTheme: _inputDecorationTheme,
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    fontFamily: 'NotoSans',
  );

  // ── Dark theme (optional, provided for completeness) ──────────────────────

  static final dark = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    ),
    textTheme: _textTheme,
    cardTheme: _cardTheme,
    filledButtonTheme: _filledButtonTheme,
    inputDecorationTheme: _inputDecorationTheme,
    fontFamily: 'NotoSans',
  );
}
