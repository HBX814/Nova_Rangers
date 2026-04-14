import 'package:flutter/material.dart';

/// CommunityPulse Material 3 theme definition.
///
/// Usage:
///   theme: AppTheme.light
abstract final class AppTheme {
  AppTheme._();

  static const _seedColor = Color(0xFF1565C0);
  static const _white = Colors.white;
  static const _headlineColor = Colors.white;
  static const _bodyColor = Color(0xFFB0C4DE);
  static const _captionColor = Color(0xFF6B8CAE);
  static const _scaffoldStart = Color(0xFF0A1628);
  static const _scaffoldEnd = Color(0xFF1A2744);
  static const _cardBase = Color(0xFF1E2D4A);
  static const _cardBorder = Color(0xFF3D5A8A);
  static const _buttonStart = Color(0xFF1565C0);
  static const _buttonEnd = Color(0xFF0D47A1);
  static const _shadowBase = Color(0xFF000000);

  // ── Shared component themes ───────────────────────────────────────────────

  static final _cardTheme = CardThemeData(
    color: _cardBase.withOpacity(0.8),
    elevation: 0,
    shadowColor: _shadowBase.withOpacity(0.3),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: _cardBorder, width: 1),
    ),
    clipBehavior: Clip.antiAlias,
  );

  static final _appBarTheme = AppBarTheme(
    backgroundColor: _scaffoldStart,
    foregroundColor: _white,
    elevation: 0,
    centerTitle: false,
    shape: const Border(
      bottom: BorderSide(color: _seedColor, width: 1),
    ),
    titleTextStyle: const TextStyle(
      fontFamily: 'NotoSans',
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: _white,
    ),
  );

  static final _filledButtonTheme = FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: _buttonStart,
      foregroundColor: _white,
      elevation: 4,
      shadowColor: _buttonStart.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
    displayLarge: TextStyle(
      fontFamily: 'NotoSans',
      fontWeight: FontWeight.w700,
      color: _headlineColor,
    ),
    displayMedium: TextStyle(
      fontFamily: 'NotoSans',
      fontWeight: FontWeight.w700,
      color: _headlineColor,
    ),
    displaySmall: TextStyle(
      fontFamily: 'NotoSans',
      fontWeight: FontWeight.w700,
      color: _headlineColor,
    ),
    headlineLarge: TextStyle(
      fontFamily: 'NotoSans',
      fontWeight: FontWeight.w700,
      color: _headlineColor,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'NotoSans',
      fontWeight: FontWeight.w700,
      color: _headlineColor,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'NotoSans',
      fontWeight: FontWeight.w700,
      color: _headlineColor,
    ),
    titleLarge: TextStyle(
      fontFamily: 'NotoSans',
      fontWeight: FontWeight.w700,
      color: _headlineColor,
    ),
    titleMedium: TextStyle(
      fontFamily: 'NotoSans',
      fontWeight: FontWeight.w700,
      color: _headlineColor,
    ),
    titleSmall: TextStyle(
      fontFamily: 'NotoSans',
      fontWeight: FontWeight.w700,
      color: _headlineColor,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'NotoSans',
      fontWeight: FontWeight.w400,
      color: _bodyColor,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'NotoSans',
      fontWeight: FontWeight.w400,
      color: _bodyColor,
    ),
    bodySmall: TextStyle(
      fontFamily: 'NotoSans',
      fontWeight: FontWeight.w400,
      color: _captionColor,
    ),
    labelLarge: TextStyle(
      fontFamily: 'NotoSans',
      fontWeight: FontWeight.w500,
      color: _bodyColor,
    ),
    labelMedium: TextStyle(
      fontFamily: 'NotoSans',
      fontWeight: FontWeight.w500,
      color: _captionColor,
    ),
    labelSmall: TextStyle(
      fontFamily: 'NotoSans',
      fontWeight: FontWeight.w400,
      color: _captionColor,
    ),
  );

  static const scaffoldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_scaffoldStart, _scaffoldEnd],
  );

  static const appBarGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_scaffoldStart, _seedColor],
  );

  static const buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_buttonStart, _buttonEnd],
  );

  static final cardShadow = [
    BoxShadow(
      color: _shadowBase.withOpacity(0.3),
      blurRadius: 20,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
  ];

  // Reusable premium decorations that keep the same palette values.
  static const scaffoldDecoration = BoxDecoration(gradient: scaffoldGradient);

  static const appBarDecoration = BoxDecoration(
    gradient: appBarGradient,
    border: Border(
      bottom: BorderSide(color: _seedColor, width: 1),
    ),
  );

  static final glassCardDecoration = BoxDecoration(
    color: _cardBase.withOpacity(0.8),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: _cardBorder, width: 1),
    boxShadow: cardShadow,
  );

  static final filledButtonDecoration = BoxDecoration(
    gradient: buttonGradient,
    borderRadius: BorderRadius.circular(14),
    boxShadow: [
      BoxShadow(
        color: _buttonStart.withOpacity(0.4),
        blurRadius: 12,
        spreadRadius: 0,
        offset: const Offset(0, 6),
      ),
    ],
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
    scaffoldBackgroundColor: _scaffoldStart,
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
    appBarTheme: _appBarTheme,
    filledButtonTheme: _filledButtonTheme,
    inputDecorationTheme: _inputDecorationTheme,
    scaffoldBackgroundColor: _scaffoldStart,
    fontFamily: 'NotoSans',
  );
}
