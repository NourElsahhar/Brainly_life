// Tests for AppCard.
// Run with: fvm flutter test test/core/widgets/app_card_test.dart

import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpCard(WidgetTester tester, Widget card) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: Center(child: card)),
      ),
    );
  }

  group('AppCard', () {
    testWidgets('shows its child', (tester) async {
      await pumpCard(tester, const AppCard(child: Text('Hello')));

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('a normal card is not tappable', (tester) async {
      await pumpCard(tester, const AppCard(child: Text('Hello')));

      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var taps = 0;
      await pumpCard(
        tester,
        AppCard(onTap: () => taps++, child: const Text('Hello')),
      );

      await tester.tap(find.byType(AppCard));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('normal padding is 20 and compact padding is 16',
        (tester) async {
      const content = SizedBox(width: 100, height: 50);

      await pumpCard(tester, const AppCard(child: content));
      expect(tester.getSize(find.byType(AppCard)), const Size(140, 90));

      await pumpCard(tester, const AppCard(compact: true, child: content));
      expect(tester.getSize(find.byType(AppCard)), const Size(132, 82));
    });

    testWidgets('custom padding wins', (tester) async {
      await pumpCard(
        tester,
        const AppCard(
          padding: EdgeInsets.all(4),
          child: SizedBox(width: 100, height: 50),
        ),
      );

      expect(tester.getSize(find.byType(AppCard)), const Size(108, 58));
    });
  });
}