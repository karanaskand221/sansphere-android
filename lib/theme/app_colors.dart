import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ------------------------------------------------------------
  // SanSphere — Light Student App Palette
  // ------------------------------------------------------------

  // Backgrounds
  static const Color background = Color(0xFFF8FAFC);
  static const Color backgroundSecondary = Color(0xFFF1F5F9);

  // Surfaces
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceStrong = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFF8FAFC);

  // Brand
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color indigo = Color(0xFF4F46E5);
  static const Color purple = Color(0xFF7C3AED);
  static const Color purpleLight = Color(0xFFA855F7);
  static const Color cyan = Color(0xFF0891B2);
  static const Color cyanBright = Color(0xFF06B6D4);

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);

  // Borders
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderStrong = Color(0xFFCBD5E1);
  static const Color activeBorder = Color(0xFF2563EB);

  // Semantic colors
  static const Color success = Color(0xFF16A34A);
  static const Color successSoft = Color(0xFFDCFCE7);

  static const Color warning = Color(0xFFD97706);
  static const Color warningSoft = Color(0xFFFEF3C7);

  static const Color error = Color(0xFFDC2626);
  static const Color errorSoft = Color(0xFFFEE2E2);

  // SanCoins
  static const Color sanCoin = Color(0xFFF59E0B);
  static const Color sanCoinDark = Color(0xFFD97706);
  static const Color sanCoinSoft = Color(0xFFFFF7ED);

  // Resource states
  static const Color free = Color(0xFF16A34A);
  static const Color paid = Color(0xFF2563EB);

  // Brand gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primary,
      indigo,
    ],
  );

  static const LinearGradient purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      purple,
      purpleLight,
    ],
  );

  static const LinearGradient cyanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      cyan,
      cyanBright,
    ],
  );

  static const LinearGradient sanCoinGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF59E0B),
      Color(0xFFFBBF24),
    ],
  );
}
