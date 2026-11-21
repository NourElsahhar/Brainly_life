import 'package:brainly_life/core/ai/ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../tool/m5_preview.dart';
import 'chat_flow.dart';

void main() {
  testWidgets(
    'Chat requires confirmation before creating a task',
    confirmTaskFromChat,
  );

  testWidgets('Chat displays the gateway error and a retry button', (
    tester,
  ) async {
    await tester.pumpWidget(
      M5Preview(
        aiClient: MockAiClient(
          delay: Duration.zero,
          error: AiErrorCode.providerUnavailable,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Brainly AI'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plan my day'));
    await tester.pumpAndSettle();
    expect(find.text(AiErrorCode.providerUnavailable.message), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
