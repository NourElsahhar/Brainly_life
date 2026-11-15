// Tests for AppTextField.
// Run with: fvm flutter test test/core/widgets/app_text_field_test.dart

import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpField(WidgetTester tester, Widget field) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Padding(padding: const EdgeInsets.all(16), child: field),
        ),
      ),
    );
  }

  group('AppTextField', () {
    testWidgets('shows the label and the hint', (tester) async {
      await pumpField(
        tester,
        const AppTextField(label: 'Email', hint: 'name@example.com'),
      );

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('name@example.com'), findsOneWidget);
    });

    testWidgets('shows the error text under the field', (tester) async {
      await pumpField(
        tester,
        const AppTextField(label: 'Email', errorText: 'Enter a valid email'),
      );

      expect(find.text('Enter a valid email'), findsOneWidget);
    });

    testWidgets('calls onChanged while typing', (tester) async {
      String? lastValue;
      await pumpField(
        tester,
        AppTextField(label: 'Title', onChanged: (value) => lastValue = value),
      );

      await tester.enterText(find.byType(TextField), 'Read chapter 3');

      expect(lastValue, 'Read chapter 3');
    });

    testWidgets('password is hidden and the eye shows it', (tester) async {
      await pumpField(
        tester,
        const AppTextField(label: 'Password', obscureText: true),
      );

      TextField field() => tester.widget<TextField>(find.byType(TextField));

      expect(field().obscureText, isTrue);

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      expect(field().obscureText, isFalse);
    });

    testWidgets('a normal field has no eye button', (tester) async {
      await pumpField(tester, const AppTextField(label: 'Name'));

      expect(find.byIcon(Icons.visibility_outlined), findsNothing);
    });

    testWidgets('shows the prefix icon', (tester) async {
      await pumpField(
        tester,
        const AppTextField(label: 'Email', prefixIcon: Icons.mail_outline),
      );

      expect(find.byIcon(Icons.mail_outline), findsOneWidget);
    });

    testWidgets('maxLength stops extra characters', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await pumpField(
        tester,
        AppTextField(label: 'Code', controller: controller, maxLength: 5),
      );

      await tester.enterText(find.byType(TextField), '1234567890');

      expect(controller.text, '12345');
    });
  });
}