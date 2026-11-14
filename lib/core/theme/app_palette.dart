// AppPalette = every semantic color of the app, for light AND dark mode.
// This is the file you use most when building screens.
//
// How to use (inside any widget):
//   final p = context.palette;
//   Container(color: p.surface, ...)
//   Text('Hello', style: TextStyle(color: p.textPrimary))
//
// Why: the same line works in light and dark mode. Never write
// `if (isDark) ...` and never hard-code Colors.white or Color(0xFF...)
// inside screens or widgets.
//
// "Soft" colors are light tinted backgrounds (for chips and banners).
// "Accent" colors are bright fills (for progress and indicators).
// For readable text on light backgrounds use the plain color (success,
// warning, error, info), not the accent.

import 'package:flutter/material.dart';

class AppPalette {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceMuted,
    required this.surfaceSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.primary,
    required this.primaryCTA,
    required this.primaryPressed,
    required this.primarySoft,
    required this.onPrimary,
    required this.teal,
    required this.tealStrong,
    required this.tealSoft,
    required this.success,
    required this.successAccent,
    required this.successSoft,
    required this.warning,
    required this.warningAccent,
    required this.warningSoft,
    required this.error,
    required this.errorAccent,
    required this.errorSoft,
    required this.info,
    required this.infoAccent,
    required this.infoSoft,
    required this.border,
    required this.borderSubtle,
    required this.iconMuted,
    required this.overlay,
    required this.progressTrack,
    required this.navGlass,
  });

  // Surfaces
  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceMuted;
  final Color surfaceSubtle;

  // Text
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary; // low-priority metadata only

  // Brand
  final Color primary; // links, active icons, selected states
  final Color primaryCTA; // fill of the main buttons
  final Color primaryPressed;
  final Color primarySoft;
  final Color onPrimary;

  // Teal (focus and habits)
  final Color teal;
  final Color tealStrong;
  final Color tealSoft;

  // Status
  final Color success;
  final Color successAccent;
  final Color successSoft;
  final Color warning;
  final Color warningAccent;
  final Color warningSoft;
  final Color error;
  final Color errorAccent;
  final Color errorSoft;
  final Color info;
  final Color infoAccent;
  final Color infoSoft;

  // Lines, icons, overlays
  final Color border;
  final Color borderSubtle;
  final Color iconMuted;
  final Color overlay;
  final Color progressTrack;
  final Color navGlass;

  static const AppPalette light = AppPalette(
    background: Color(0xFFF8F9FF),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFEEF1FA),
    surfaceSubtle: Color(0xFFF2F3FB),
    textPrimary: Color(0xFF2D3436),
    textSecondary: Color(0xFF636E72),
    textTertiary: Color(0xFF879198),
    primary: Color(0xFF6C5CE7),
    primaryCTA: Color(0xFF6C5CE7),
    primaryPressed: Color(0xFF4834D4),
    primarySoft: Color(0xFFEAE6FF),
    onPrimary: Color(0xFFFFFFFF),
    teal: Color(0xFF00CEC9),
    tealStrong: Color(0xFF006A67),
    tealSoft: Color(0xFFE0F8F6),
    success: Color(0xFF16866F),
    successAccent: Color(0xFF55EFC4),
    successSoft: Color(0xFFE1F8EF),
    warning: Color(0xFF946000),
    warningAccent: Color(0xFFFDCB6E),
    warningSoft: Color(0xFFFFF4D8),
    error: Color(0xFFC7474A),
    errorAccent: Color(0xFFFF7675),
    errorSoft: Color(0xFFFFE9E7),
    info: Color(0xFF3577B9),
    infoAccent: Color(0xFF74B9FF),
    infoSoft: Color(0xFFE8F3FF),
    border: Color(0xFFE7E5F1),
    borderSubtle: Color.fromRGBO(108, 92, 231, 0.08),
    iconMuted: Color(0xFF858397),
    overlay: Color.fromRGBO(31, 27, 54, 0.40),
    progressTrack: Color(0xFFEEF1FA),
    navGlass: Color.fromRGBO(255, 255, 255, 0.82),
  );

  static const AppPalette dark = AppPalette(
    background: Color(0xFF12111A),
    surface: Color(0xFF1E1C2E),
    surfaceRaised: Color(0xFF242238),
    surfaceMuted: Color(0xFF28253D),
    surfaceSubtle: Color(0xFF302C47),
    textPrimary: Color(0xFFF1F2F6),
    textSecondary: Color(0xFFA4A6B3),
    textTertiary: Color(0xFF85879B),
    primary: Color(0xFFA99BFF),
    primaryCTA: Color(0xFF6C5CE7),
    primaryPressed: Color(0xFF4834D4),
    primarySoft: Color.fromRGBO(108, 92, 231, 0.20),
    onPrimary: Color(0xFFFFFFFF),
    teal: Color(0xFF35DED7),
    tealStrong: Color(0xFF5AF9F3),
    tealSoft: Color.fromRGBO(0, 206, 201, 0.14),
    success: Color(0xFF6BEFCB),
    successAccent: Color(0xFF55EFC4),
    successSoft: Color.fromRGBO(85, 239, 196, 0.14),
    warning: Color(0xFFFFD98B),
    warningAccent: Color(0xFFFDCB6E),
    warningSoft: Color.fromRGBO(253, 203, 110, 0.15),
    error: Color(0xFFFF9290),
    errorAccent: Color(0xFFFF7675),
    errorSoft: Color.fromRGBO(255, 118, 117, 0.15),
    info: Color(0xFF91C9FF),
    infoAccent: Color(0xFF74B9FF),
    infoSoft: Color.fromRGBO(116, 185, 255, 0.15),
    border: Color.fromRGBO(255, 255, 255, 0.09),
    borderSubtle: Color.fromRGBO(255, 255, 255, 0.07),
    iconMuted: Color(0xFFA4A6B3),
    overlay: Color.fromRGBO(0, 0, 0, 0.58),
    progressTrack: Color(0xFF28253D),
    navGlass: Color.fromRGBO(30, 28, 46, 0.82),
  );
}

/// Lets any widget write `context.palette`.
extension AppPaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).brightness == Brightness.dark
      ? AppPalette.dark
      : AppPalette.light;
}