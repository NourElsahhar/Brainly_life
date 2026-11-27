import 'package:brainly_life/core/ai/ai.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../tool/m5_preview.dart';

Future<void> confirmTaskFromChat(WidgetTester tester) async {
  final created = <String>[];
  await tester.pumpWidget(
    M5Preview(
      clock: Clock.fixed(DateTime.utc(2026, 11, 15)),
      aiClient: MockAiClient(delay: Duration.zero),
      onTaskCreated: created.add,
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Baseet AI'));
  await tester.pumpAndSettle();
  expect(find.text('Plan my day'), findsOneWidget);
  await tester.enterText(find.byType(TextField), 'Create task: Read chapter 2');
  await tester.tap(find.byTooltip('Send'));
  await tester.pumpAndSettle();
  expect(find.text('I can add that to your tasks.'), findsOneWidget);
  await tester.tap(find.text('Create task'));
  await tester.pumpAndSettle();
  expect(created, isEmpty);
  await tester.tap(find.text('Cancel'));
  await tester.pumpAndSettle();
  expect(created, isEmpty);
  await tester.tap(find.text('Create task'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Confirm'));
  await tester.pumpAndSettle();
  expect(created, ['Read chapter 2']);
}
