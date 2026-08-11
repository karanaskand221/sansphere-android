import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Background
  static const Color background = Color(0xFF050816);
  static const Color backgroundSecondary = Color(0xFF0A1020);
  static const Color surface = Color(0xA6121826);
  static const Color surfaceStrong = Color(0xCC121826);

  // Purple / cyan brand
  static const Color purple = Color(0xFFA855F7);
  static const Color purpleDark = Color(0xFF7C3AED);
  static const Color cyan = Color(0xFF06B6D4);
  static const Color cyanBright = Color(0xFF38BDF8);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0x99FFFFFF);
  static const Color textMuted = Color(0x66FFFFFF);

  // Borders
  static const Color border = Color(0x1FFFFFFF);
  static const Color borderStrong = Color(0x33FFFFFF);
  static const Color activeBorder = Color(0x66A855F7);

  // Status
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [purple, cyan],
  );

  static const LinearGradient purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [purpleDark, purple],
  );

  static const LinearGradient cyanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cyan, cyanBright],
  );
}
