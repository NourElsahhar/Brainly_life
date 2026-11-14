// AppTheme = the light and dark ThemeData of the app (Material 3).
// It is built from AppPalette, AppTextStyles and AppRadius.
//
// It is used once, in app.dart:
//   MaterialApp(theme: AppTheme.light, darkTheme: AppTheme.dark, ...)
//
// Everywhere else, read from the palette and text styles:
//   context.palette.surface
//   context.text.bodyMedium
// Never write Colors.white or Color(0xFF...) inside screens or widgets.
//
// Buttons, text fields, cards and dialogs are NOT styled here. Use the
// shared widgets from core/widgets (AppButton, AppTextField, AppCard,
// ConfirmDialog) so they all look the same.

import 'package:flutter/material.dart';

import 'app_palette.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light => _build(AppPalette.light, Brightness.light);
  static ThemeData get dark => _build(AppPalette.dark, Brightness.dark);

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final isLight = brightness == Brightness.light;

    // Text takes the main text color of the current mode automatically.
    final textTheme = AppTextStyles.textTheme.apply(
      bodyColor: p.textPrimary,
      displayColor: p.textPrimary,
    );

    // Written by hand (not generated) so the colors match the design exactly.
    final scheme = ColorScheme(
      brightness: brightness,
      primary: p.primaryCTA,
      onPrimary: p.onPrimary,
      primaryContainer: p.primarySoft,
      onPrimaryContainer: isLight ? p.primaryPressed : p.primary,
      secondary: p.teal,
      onSecondary: isLight ? p.textPrimary : p.background,
      secondaryContainer: p.tealSoft,
      onSecondaryContainer: p.tealStrong,
      error: p.error,
      onError: isLight ? p.onPrimary : p.background,
      errorContainer: p.errorSoft,
      onErrorContainer: p.error,
      surface: p.surface,
      onSurface: p.textPrimary,
      onSurfaceVariant: p.textSecondary,
      surfaceContainerLowest: p.surface,
      surfaceContainerLow: p.surface,
      surfaceContainer: p.surfaceRaised,
      surfaceContainerHigh: p.surfaceMuted,
      surfaceContainerHighest: p.surfaceSubtle,
      outline: p.iconMuted,
      outlineVariant: p.border,
      scrim: p.overlay,
      inverseSurface: p.textPrimary,
      onInverseSurface: p.background,
      inversePrimary: p.primary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: AppTextStyles.bodyFont,
      textTheme: textTheme,
      scaffoldBackgroundColor: p.background,
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineMedium,
      ),
      dividerTheme: DividerThemeData(
        color: p.borderSubtle,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.textPrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: p.background),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
    );
  }
}