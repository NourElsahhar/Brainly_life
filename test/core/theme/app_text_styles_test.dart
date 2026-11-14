// Tests for AppTextStyles.
// Run with: fvm flutter test test/core/theme/app_text_styles_test.dart

import 'package:brainly_life/core/theme/app_text_styles.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTextStyles', () {
    test('height is lineHeight divided by font size', () {
      // Design: 24 px text with 32 px line height.
      expect(AppTextStyles.headlineLarge.height, closeTo(32 / 24, 0.0001));
      // Design: 14 px text with 20 px line height.
      expect(AppTextStyles.bodyMedium.height, closeTo(20 / 14, 0.0001));
    });

    test('letter spacing converts em to pixels', () {
      // Design: -0.02em on 32 px = -0.64 px.
      expect(AppTextStyles.displayHero.letterSpacing, closeTo(-0.64, 0.0001));
      expect(AppTextStyles.bodyMedium.letterSpacing, 0);
    });

    test('headings use Plus Jakarta Sans and body uses Inter', () {
      expect(AppTextStyles.headlineLarge.fontFamily, 'PlusJakartaSans');
      expect(AppTextStyles.metricCounter.fontFamily, 'PlusJakartaSans');
      expect(AppTextStyles.bodyLarge.fontFamily, 'Inter');
      expect(AppTextStyles.labelCaption.fontFamily, 'Inter');
    });

    test('Arabic fallback fonts are set', () {
      expect(AppTextStyles.bodyMedium.fontFamilyFallback, ['Cairo', 'Tajawal']);
    });

    test('text theme maps the design styles to Material roles', () {
      expect(AppTextStyles.textTheme.headlineLarge?.fontSize, 24);
      expect(AppTextStyles.textTheme.bodyMedium?.fontSize, 14);
      expect(AppTextStyles.textTheme.labelSmall?.fontSize, 11);
    });
  });
}