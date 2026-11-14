// AppTextStyles = the text styles of the app, taken from the design system.
//
// How to use (inside any widget):
//   Text('Title', style: context.text.headlineMedium)
//   Text('Details', style: context.text.bodyMedium)
//
// The color comes from the theme automatically (light and dark), so you
// normally do NOT set a color. For a softer color:
//   style: context.text.bodyMedium?.copyWith(color: context.palette.textSecondary)
//
// Fonts: headings, numbers and badges use Plus Jakarta Sans.
// Body text and small labels use Inter. Arabic text falls back to Cairo.

import 'package:flutter/material.dart';

class AppTextStyles {
  const AppTextStyles._();

  static const String headingFont = 'PlusJakartaSans';
  static const String bodyFont = 'Inter';
  static const List<String> _arabicFallback = ['Cairo', 'Tajawal'];

  // The design gives line height in pixels and letter spacing in "em".
  // Flutter wants height = lineHeight / fontSize and spacing in pixels.
  static TextStyle _style({
    required String family,
    required double size,
    required FontWeight weight,
    required double lineHeight,
    double letterSpacingEm = 0,
  }) {
    return TextStyle(
      fontFamily: family,
      fontFamilyFallback: _arabicFallback,
      fontSize: size,
      fontWeight: weight,
      height: lineHeight / size,
      letterSpacing: letterSpacingEm * size,
    );
  }

  static final TextStyle displayHero = _style(
    family: headingFont, size: 32, weight: FontWeight.w700,
    lineHeight: 40, letterSpacingEm: -0.02,
  );
  static final TextStyle displayHeroMobile = _style(
    family: headingFont, size: 28, weight: FontWeight.w700,
    lineHeight: 36, letterSpacingEm: -0.02,
  );
  static final TextStyle headlineLarge = _style(
    family: headingFont, size: 24, weight: FontWeight.w700,
    lineHeight: 32, letterSpacingEm: -0.015,
  );
  static final TextStyle headlineMedium = _style(
    family: headingFont, size: 20, weight: FontWeight.w600,
    lineHeight: 28, letterSpacingEm: -0.01,
  );
  static final TextStyle headlineSmall = _style(
    family: headingFont, size: 18, weight: FontWeight.w600,
    lineHeight: 24, letterSpacingEm: -0.005,
  );
  static final TextStyle bodyLarge = _style(
    family: bodyFont, size: 16, weight: FontWeight.w500,
    lineHeight: 24, letterSpacingEm: -0.005,
  );
  static final TextStyle bodyMedium = _style(
    family: bodyFont, size: 14, weight: FontWeight.w400, lineHeight: 20,
  );
  static final TextStyle bodySmall = _style(
    family: bodyFont, size: 13, weight: FontWeight.w400, lineHeight: 18,
  );
  static final TextStyle labelPill = _style(
    family: headingFont, size: 12, weight: FontWeight.w600,
    lineHeight: 16, letterSpacingEm: 0.01,
  );
  static final TextStyle labelCaption = _style(
    family: bodyFont, size: 11, weight: FontWeight.w500,
    lineHeight: 14, letterSpacingEm: 0.02,
  );

  /// Big numbers: streaks, hours, progress. Not part of Material's roles,
  /// so use it directly: AppTextStyles.metricCounter
  static final TextStyle metricCounter = _style(
    family: headingFont, size: 22, weight: FontWeight.w800,
    lineHeight: 26, letterSpacingEm: -0.02,
  );

  /// Text inside buttons (design spec 6.1: Plus Jakarta Sans, 14-16, 600-700).
  static final TextStyle button = _style(
    family: headingFont, size: 15, weight: FontWeight.w700, lineHeight: 20,
  );

  /// Connects our styles to Flutter's built-in roles, so standard widgets
  /// (AppBar, ListTile, buttons...) use them automatically.
  static final TextTheme textTheme = TextTheme(
    displayLarge: displayHero,
    displayMedium: displayHeroMobile,
    headlineLarge: headlineLarge,
    headlineMedium: headlineMedium,
    headlineSmall: headlineSmall,
    titleLarge: headlineMedium,
    titleMedium: headlineSmall,
    titleSmall: bodyMedium,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: button,
    labelMedium: labelPill,
    labelSmall: labelCaption,
  );
}

/// Lets any widget write `context.text` instead of
/// `Theme.of(context).textTheme`.
extension AppTextContext on BuildContext {
  TextTheme get text => Theme.of(this).textTheme;
}