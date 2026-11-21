import 'package:brainly_life/app.dart';
import 'package:brainly_life/injection.dart';
import 'package:brainly_life/features/ai_assistant/logic/ai_action_handler.dart';
import 'package:brainly_life/features/ai_assistant/data/models/chat_message.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  tearDown(() => getIt.reset());
  testWidgets('Team shell opens assistant and weekly analytics', (
    tester,
  ) async {
    await configureDependencies(useMocks: true);
    await tester.pumpWidget(const BrainlyLifeApp());
    getIt<GoRouter>().go('/assistant');
    await tester.pumpAndSettle();
    expect(find.text('Hi, how can I help?'), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
    await tester.tap(find.byTooltip('Weekly analytics'));
    await tester.pumpAndSettle();
    expect(find.text('Weekly analytics'), findsOneWidget);
    expect(find.text('Productivity score'), findsOneWidget);
  });
  test('Assistant uses the team task creation port', () async {
    await configureDependencies(useMocks: true);
    final action = AiAction(AiActionType.createTask, title: 'Review biology');
    final handler = getIt<AiActionHandler>();
    final declined = await handler.execute(action, confirmed: false);
    expect(declined.dataOrNull, isNull);
    final accepted = await handler.execute(action, confirmed: true);
    expect(accepted.failureOrNull, isNull);
    expect(accepted.dataOrNull, AiActionType.createTask);
  });
}
