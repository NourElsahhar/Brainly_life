// Tests for AppPalette and the accent colors.
// Run with: fvm flutter test test/core/theme/app_palette_test.dart

import 'package:brainly_life/core/theme/app_colors.dart';
import 'package:brainly_life/core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppPalette', () {
    test('light uses the approved background and primary', () {
      expect(AppPalette.light.background, const Color(0xFFF8F9FF));
      expect(AppPalette.light.primary, const Color(0xFF6C5CE7));
    });

    test('dark never uses pure black or pure white surfaces', () {
      expect(AppPalette.dark.background, const Color(0xFF12111A));
      expect(AppPalette.dark.background, isNot(const Color(0xFF000000)));
      expect(AppPalette.dark.surface, isNot(const Color(0xFFFFFFFF)));
    });

    test('dark keeps the brand button color', () {
      expect(AppPalette.dark.primaryCTA, const Color(0xFF6C5CE7));
      expect(AppPalette.dark.primary, const Color(0xFFA99BFF));
    });

    testWidgets('context.palette follows the theme brightness', (tester) async {
      late AppPalette seen;

      Future<void> pump(Brightness brightness) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: Builder(
              builder: (context) {
                seen = context.palette;
                return const SizedBox();
              },
            ),
          ),
        );
        // MaterialApp animates theme changes, so wait until it finishes.
        await tester.pumpAndSettle();
      }

      await pump(Brightness.dark);
      expect(seen, AppPalette.dark);

      await pump(Brightness.light);
      expect(seen, AppPalette.light);
    });
  });

  group('AccentColors', () {
    test('surfaceFor gives the tint of the right mode', () {
      expect(
        AppColors.biology.surfaceFor(Brightness.light),
        const Color(0xFFE1F8EF),
      );
      expect(
        AppColors.biology.surfaceFor(Brightness.dark),
        const Color.fromRGBO(85, 239, 196, 0.14),
      );
    });
  });
}