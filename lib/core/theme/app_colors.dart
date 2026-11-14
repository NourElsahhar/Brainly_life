// AppColors = the raw brand colors of "Luminous Clarity" (the team design).
// These never change between light and dark mode.
//
// Do NOT use them for backgrounds or text inside screens.
// For those, use the palette so light and dark mode work automatically:
//   context.palette.surface
//   context.palette.textPrimary
//
// Use AppColors directly only for:
//   - gradients (AppColors.primaryGradient)
//   - subject colors (AppColors.biology, AppColors.mathematics, ...)

import 'package:flutter/material.dart';

/// One accent color with its soft background in light and dark mode.
class AccentColors {
  const AccentColors({
    required this.accent,
    required this.lightSurface,
    required this.darkSurface,
  });

  final Color accent;
  final Color lightSurface;
  final Color darkSurface;

  Color surfaceFor(Brightness brightness) =>
      brightness == Brightness.light ? lightSurface : darkSurface;
}

class AppColors {
  const AppColors._();

  // Brand palette
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryDeep = Color(0xFF4834D4);
  static const Color teal = Color(0xFF00CEC9);
  static const Color tealDeep = Color(0xFF006A67);
  static const Color reward = Color(0xFFFDCB6E);
  static const Color successAccent = Color(0xFF55EFC4);
  static const Color alertAccent = Color(0xFFFF7675);
  static const Color calmBlue = Color(0xFF74B9FF);
  static const Color neutral = Color(0xFFB2BEC3);
  static const Color reflectiveLilac = Color(0xFFA29BFE);

  // TEMPORARY: kept only so the old app_theme.dart still compiles.
  // It is removed when AppTheme is rewritten.
  static const Color seed = primary;

  // Gradients (use only for high-value areas: main buttons, AI, progress)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDeep],
  );
  static const LinearGradient aiGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, teal],
  );
  static const LinearGradient progressGradient = LinearGradient(
    colors: [primary, teal],
  );
  static const LinearGradient streakGradient = LinearGradient(
    colors: [reward, alertAccent],
  );

  // Subject / category colors (always show a text label too, not color only)
  static const AccentColors biology = AccentColors(
    accent: Color(0xFF55EFC4),
    lightSurface: Color(0xFFE1F8EF),
    darkSurface: Color.fromRGBO(85, 239, 196, 0.14),
  );
  static const AccentColors mathematics = AccentColors(
    accent: Color(0xFF6C5CE7),
    lightSurface: Color(0xFFEAE6FF),
    darkSurface: Color.fromRGBO(108, 92, 231, 0.20),
  );
  static const AccentColors physics = AccentColors(
    accent: Color(0xFF74B9FF),
    lightSurface: Color(0xFFE8F3FF),
    darkSurface: Color.fromRGBO(116, 185, 255, 0.15),
  );
  static const AccentColors personal = AccentColors(
    accent: Color(0xFFFFB48F),
    lightSurface: Color(0xFFFFF0E8),
    darkSurface: Color.fromRGBO(255, 180, 143, 0.14),
  );
  static const AccentColors rewards = AccentColors(
    accent: Color(0xFFFDCB6E),
    lightSurface: Color(0xFFFFF4D8),
    darkSurface: Color.fromRGBO(253, 203, 110, 0.15),
  );
}