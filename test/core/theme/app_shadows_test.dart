// Tests for AppShadows.
// Run with: fvm flutter test test/core/theme/app_shadows_test.dart

import 'package:brainly_life/core/theme/app_shadows.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpWith(
    WidgetTester tester,
    Brightness brightness,
    void Function(BuildContext context) onBuild,
  ) {
    return tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: Builder(
          builder: (context) {
            onBuild(context);
            return const SizedBox();
          },
        ),
      ),
    );
  }

  group('AppShadows', () {
    testWidgets('light card has two soft shadows', (tester) async {
      late List<BoxShadow> shadows;
      await pumpWith(
        tester,
        Brightness.light,
        (context) => shadows = AppShadows.card(context),
      );

      expect(shadows.length, 2);
    });

    testWidgets('dark card has no shadow', (tester) async {
      late List<BoxShadow> shadows;
      await pumpWith(
        tester,
        Brightness.dark,
        (context) => shadows = AppShadows.card(context),
      );

      expect(shadows, isEmpty);
    });

    testWidgets('floating and modal always have a shadow', (tester) async {
      late List<BoxShadow> floating;
      late List<BoxShadow> modal;
      await pumpWith(tester, Brightness.dark, (context) {
        floating = AppShadows.floating(context);
        modal = AppShadows.modal(context);
      });

      expect(floating, isNotEmpty);
      expect(modal, isNotEmpty);
    });
  });
}