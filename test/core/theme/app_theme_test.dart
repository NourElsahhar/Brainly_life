// Tests for AppTheme.
// Run with: fvm flutter test test/core/theme/app_theme_test.dart

import 'package:brainly_life/core/theme/app_palette.dart';
import 'package:brainly_life/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme', () {
    test('light and dark use Material 3 with the right brightness', () {
      expect(AppTheme.light.brightness, Brightness.light);
      expect(AppTheme.dark.brightness, Brightness.dark);
      expect(AppTheme.light.useMaterial3, isTrue);
      expect(AppTheme.dark.useMaterial3, isTrue);
    });

    test('screen background comes from the palette', () {
      expect(
        AppTheme.light.scaffoldBackgroundColor,
        AppPalette.light.background,
      );
      expect(
        AppTheme.dark.scaffoldBackgroundColor,
        AppPalette.dark.background,
      );
    });

    test('the main button color is the brand violet in both modes', () {
      expect(AppTheme.light.colorScheme.primary, const Color(0xFF6C5CE7));
      expect(AppTheme.dark.colorScheme.primary, const Color(0xFF6C5CE7));
    });

    test('cards use the surface color of each mode', () {
      expect(AppTheme.light.colorScheme.surface, AppPalette.light.surface);
      expect(AppTheme.dark.colorScheme.surface, AppPalette.dark.surface);
    });

    test('text uses the design size and the palette text color', () {
      final light = AppTheme.light.textTheme.bodyMedium;
      final dark = AppTheme.dark.textTheme.bodyMedium;

      expect(light?.fontSize, 14);
      expect(light?.color, AppPalette.light.textPrimary);
      expect(dark?.color, AppPalette.dark.textPrimary);
    });

    test('default fonts follow the design', () {
      expect(AppTheme.light.textTheme.bodyMedium?.fontFamily, 'Inter');
      expect(
        AppTheme.light.textTheme.headlineLarge?.fontFamily,
        'PlusJakartaSans',
      );
    });
  });
}