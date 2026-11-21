import '../errors/result.dart';
import 'ai_client.dart';
import 'ai_failures.dart';
import 'ai_models.dart';

class MockAiClient implements AiClient {
  MockAiClient({
    this.delay = const Duration(milliseconds: 450),
    this.error,
    this.invalidOutput = false,
    this.enabled = true,
    this.fixtures = const {},
  });

  final Duration delay;
  final AiErrorCode? error;
  final bool invalidOutput;
  final bool enabled;
  final Map<AiFeature, Map<String, Object?>> fixtures;

  @override
  Future<Result<AiResponse>> generate(AiRequest request) async {
    if (!enabled) return Result.failure(AiGatewayFailure(AiErrorCode.disabled));
    await Future<void>.delayed(delay);
    if (error case final code?) return Result.failure(AiGatewayFailure(code));
    return Result.success(
      AiResponse(
        usage: AiUsage(remainingToday: 29, feature: request.feature),
        data: invalidOutput
            ? {'unexpected': true}
            : fixtures[request.feature] ?? _fixture(request),
      ),
    );
  }

  Map<String, Object?> _fixture(AiRequest request) => switch (request.feature) {
    AiFeature.studyPlan => {
      'sessions': [
        {
          'subjectId': 'demo-subject',
          'topicId': 'demo-topic',
          'date': request.payload['startDate'] ?? '2026-11-16',
          'startTime': '16:00',
          'plannedMinutes': 25,
        },
      ],
    },
    AiFeature.habitSuggest => {
      'suggestions': [
        {
          'title': 'Start with five minutes',
          'reason': 'A short habit is easier to repeat.',
        },
      ],
    },
    AiFeature.chat => _chat(request.payload['text']),
    AiFeature.dailyTip => {
      'tip': 'Pick one task you can finish before checking your inbox.',
    },
    AiFeature.weeklyInsight => {
      'summary': 'You made progress this week. Review what helped you stay consistent.',
      'recommendations': [
        'Schedule a short focus block.',
        'Review unfinished tasks.',
        'Keep one small daily habit.',
      ],
    },
  };

  Map<String, Object?> _chat(Object? input) {
    final text = input is String ? input.trim() : '';
    final createTask = text.toLowerCase().startsWith('create task:');
    final title = createTask
        ? text.substring('create task:'.length).trim()
        : '';
    if (title.isNotEmpty && title.length <= 100) {
      return {
        'reply': 'I can add that to your tasks.',
        'actions': [
          {'type': 'create_task', 'title': title},
        ],
      };
    }
    return {
      'reply': 'Choose one priority and give it a focused 25-minute block.',
      'actions': <Object?>[],
    };
  }
}
