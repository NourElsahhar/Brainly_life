import 'package:brainly_life/core/ai/ai.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/ai_assistant/data/models/chat_message.dart';
import 'package:brainly_life/features/ai_assistant/data/repositories/mock_chat_repository.dart';
import 'package:brainly_life/features/ai_assistant/logic/ai_action_handler.dart';
import 'package:brainly_life/features/ai_assistant/logic/chat_cubit.dart';
import 'package:brainly_life/features/ai_assistant/logic/chat_state.dart';
import 'package:flutter_test/flutter_test.dart';

class RecordingClient implements AiClient {
  final requests = <AiRequest>[];
  AiErrorCode? error;

  @override
  Future<Result<AiResponse>> generate(AiRequest request) {
    requests.add(request);
    return MockAiClient(delay: Duration.zero, error: error).generate(request);
  }
}

void main() {
  test(
    'Failure can retry without duplicating the saved user message',
    () async {
      final client = RecordingClient()..error = AiErrorCode.providerUnavailable;
      final repo = MockChatRepository();
      final cubit = ChatCubit(
        repository: repo,
        client: client,
        now: () => DateTime.utc(2026),
      );
      addTearDown(cubit.close);
      await cubit.load();
      expect(cubit.state, isA<ChatEmpty>());
      await cubit.send('Create task: Read chapter 2');
      expect(cubit.state, isA<ChatError>());
      expect((await repo.load()).dataOrNull, hasLength(1));
      client.error = null;
      await cubit.retry();
      final messages = (cubit.state as ChatLoaded).messages;
      expect(messages, hasLength(2));
      expect(messages.last.actions.single.title, 'Read chapter 2');
      expect((await repo.load()).dataOrNull, hasLength(2));
      await cubit.clear();
      expect(cubit.state, isA<ChatEmpty>());
      expect((await repo.load()).dataOrNull, isEmpty);
    },
  );

  test(
    'Sends at most 10 earlier messages and validates input locally',
    () async {
      final client = RecordingClient();
      final cubit = ChatCubit(
        repository: MockChatRepository(),
        client: client,
        now: () => DateTime.utc(2026),
      );
      addTearDown(cubit.close);
      await cubit.load();
      await cubit.send('x' * 1001);
      expect(client.requests, isEmpty);
      for (var index = 0; index < 7; index++) {
        await cubit.send('Question $index');
      }
      final payload = client.requests.last.payload;
      expect(payload.keys, ['text', 'history']);
      expect(payload['history'], hasLength(10));
    },
  );

  test('Unknown and unconfirmed chat actions cause no side effects', () async {
    var calls = 0;
    Future<Result<String>> create(String title) async {
      calls++;
      return const Result.success('id');
    }

    final handler = AiActionHandler(createTask: create, createHabit: create);
    final unknown = AiAction.tryParse({'type': 'unknown'});
    const task = AiAction(AiActionType.createTask, title: 'Study');
    expect(
      (await handler.execute(unknown, confirmed: true)).dataOrNull,
      isNull,
    );
    expect((await handler.execute(task, confirmed: false)).dataOrNull, isNull);
    expect(calls, 0);
    expect(
      (await handler.execute(task, confirmed: true)).dataOrNull,
      AiActionType.createTask,
    );
    expect(calls, 1);
  });
}
