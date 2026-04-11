import 'package:flutter/material.dart';

class AppConfig {
  AppConfig._(); // prevent instantiation

  // ── API ──────────────────────────────────────────────────────────────────
  static const String baseUrl = 'https://communitypulse-api-619376803975.asia-south1.run.app/api/v1';

  // ── App metadata ─────────────────────────────────────────────────────────
  static const String appName = 'CommunityPulse';

  // ── Theme colours ─────────────────────────────────────────────────────────
  static const Color primaryColor     = Color(0xFF1565C0);
  static const Color accentColor      = Color(0xFFFF6F00);
  static const Color backgroundColor  = Color(0xFFF5F5F5);
  static const Color errorColor       = Color(0xFFC62828);

  // ── Category colours ──────────────────────────────────────────────────────
  static const Map<String, Color> categoryColors = {
    'FLOOD':          Color(0xFF1565C0), // blue
    'MEDICAL':        Color(0xFFC62828), // red
    'FOOD':           Color(0xFFE65100), // orange
    'DROUGHT':        Color(0xFF5D4037), // brown
    'SHELTER':        Color(0xFF2E7D32), // green
    'EDUCATION':      Color(0xFF6A1B9A), // purple
    'INFRASTRUCTURE': Color(0xFF546E7A), // grey
    'WATER':          Color(0xFF00838F), // cyan
  };
}
