// Tests for AppButton.
// Run with: fvm flutter test test/core/widgets/app_button_test.dart

import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpButton(WidgetTester tester, Widget button) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: Center(child: button)),
      ),
    );
  }

  group('AppButton', () {
    testWidgets('shows the label', (tester) async {
      await pumpButton(tester, AppButton(label: 'Save', onPressed: () {}));

      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var taps = 0;
      await pumpButton(
        tester,
        AppButton(label: 'Save', onPressed: () => taps++),
      );

      await tester.tap(find.byType(AppButton));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await pumpButton(
        tester,
        const AppButton(label: 'Save', onPressed: null),
      );

      expect(tester.widget<InkWell>(find.byType(InkWell)).onTap, isNull);
    });

    testWidgets('loading shows a spinner and ignores taps', (tester) async {
      var taps = 0;
      await pumpButton(
        tester,
        AppButton(label: 'Save', isLoading: true, onPressed: () => taps++),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Save'), findsNothing);

      await tester.tap(find.byType(AppButton));
      await tester.pump();

      expect(taps, 0);
    });

    testWidgets('shows the icon when given', (tester) async {
      await pumpButton(
        tester,
        AppButton(label: 'Add', icon: Icons.add, onPressed: () {}),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('expanded false is only as wide as its content',
        (tester) async {
      await pumpButton(
        tester,
        AppButton(label: 'Go', expanded: false, onPressed: () {}),
      );

      expect(tester.getSize(find.byType(AppButton)).width, lessThan(300));
    });

    testWidgets('all four types build without errors', (tester) async {
      for (final type in AppButtonType.values) {
        await pumpButton(
          tester,
          AppButton(label: 'Go', type: type, onPressed: () {}),
        );

        expect(find.text('Go'), findsOneWidget);
      }
    });
  });
}