// Tests for GeminiAiClient with a fake Gemini call (no Firebase):
// AI off, daily limit, broken answers (one retry), fences, errors, the
// chat context in the prompt and the saved weekly report.

import 'package:brainly_life/core/ai/ai.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<AiPrompt> prompts;
  late MemoryAiUsageCounter usage;

  GeminiAiClient client(
    List<Object?> answers, {
    bool enabled = true,
    Map<String, Object?> context = const {},
    Future<void> Function(String, Map<String, Object?>, Map<String, Object?>)?
    save,
  }) {
    final queue = [...answers];
    return GeminiAiClient(
      call: (prompt, {required temperature}) async {
        prompts.add(prompt);
        final next = queue.removeAt(0);
        if (next is Exception) throw next;
        return next as String?;
      },
      isEnabled: () async => enabled,
      usage: usage,
      today: () async => '2026-11-27',
      chatContext: () async => context,
      saveWeeklyReport: save,
    );
  }

  setUp(() {
    prompts = [];
    usage = MemoryAiUsageCounter();
  });

  AiRequest tip() => AiRequest(feature: AiFeature.dailyTip, payload: const {});

  test('a good answer is returned with the calls left today', () async {
    final result = await client(['{"tip":"Start small."}']).generate(tip());

    expect(result.dataOrNull!.data, {'tip': 'Start small.'});
    expect(result.dataOrNull!.usage.remainingToday, 2);
    expect(prompts.single.system, GeminiPrompts.dailyTipSystem);
  });

  test('JSON inside ```json fences is read', () async {
    final result = await client(['```json\n{"tip":"Start small."}\n```'])
        .generate(tip());

    expect(result.dataOrNull!.data['tip'], 'Start small.');
  });

  test('AI off: no call, disabled', () async {
    final result = await client(const [], enabled: false).generate(tip());

    expect(prompts, isEmpty);
    expect(
      (result.failureOrNull! as AiGatewayFailure).kind,
      AiErrorCode.disabled,
    );
  });

  test('the daily limit stops the 4th tip of the day', () async {
    final ai = client(List.filled(4, '{"tip":"Plan."}'));
    for (var i = 0; i < 3; i++) {
      expect((await ai.generate(tip())).isSuccess, isTrue);
    }
    final fourth = await ai.generate(tip());

    expect(
      (fourth.failureOrNull! as AiGatewayFailure).kind,
      AiErrorCode.rateLimited,
    );
    expect(prompts, hasLength(3));
  });

  test('a broken answer is retried once, then invalidResponse', () async {
    final fixed = await client(['not json', '{"tip":"Plan."}']).generate(tip());
    expect(fixed.dataOrNull!.data['tip'], 'Plan.');

    final broken = await client(['oops', '{"wrong":1}']).generate(tip());
    expect(
      (broken.failureOrNull! as AiGatewayFailure).kind,
      AiErrorCode.invalidResponse,
    );
  });

  test('a Gemini error becomes the matching gateway error', () async {
    final result = await client([
      const GeminiCallException(AiErrorCode.rateLimited),
    ]).generate(tip());

    expect(
      (result.failureOrNull! as AiGatewayFailure).kind,
      AiErrorCode.rateLimited,
    );
    // A failed call does not use the daily limit.
    expect(await usage.used('2026-11-27_dailyTip'), 0);
  });

  test('chat: the app data goes inside the data block', () async {
    final result =
        await client(
          ['{"reply":"Math at 18:00.","actions":[{"type":"open_plan"}]}'],
          context: {
            'studyPlanner': {
              'subjects': [
                {'name': 'Math', 'examDate': '2026-12-10'},
              ],
            },
          },
        ).generate(
          AiRequest(
            feature: AiFeature.chat,
            payload: const {'text': 'What do I study today?', 'history': []},
          ),
        );

    expect(result.dataOrNull!.data['reply'], 'Math at 18:00.');
    final user = prompts.single.user;
    expect(user, startsWith('<user_data>'));
    expect(user, contains('"examDate":"2026-12-10"'));
    expect(user, contains('What do I study today?'));
  });

  test('weekly insight: the report is saved', () async {
    Map<String, Object?>? saved;
    final result =
        await client(
          ['{"summary":"Good week.","recommendations":["a","b","c"]}'],
          save: (weekKey, stats, report) async {
            expect(weekKey, '2026-W47');
            expect(stats['tasksCompleted'], 2);
            saved = report;
          },
        ).generate(
          AiRequest(
            feature: AiFeature.weeklyInsight,
            payload: const {
              'weekKey': '2026-W47',
              'stats': {'tasksCompleted': 2},
            },
          ),
        );

    expect(result.isSuccess, isTrue);
    expect(saved!['recommendations'], ['a', 'b', 'c']);
  });

  test('any other error is a gateway failure (no crash)', () async {
    final ai = GeminiAiClient(
      call: (prompt, {required temperature}) async =>
          throw TimeoutExceptionForTest(),
      isEnabled: () async => true,
      usage: usage,
      today: () async => '2026-11-27',
    );
    final result = await ai.generate(tip());
    expect(
      (result.failureOrNull! as AiGatewayFailure).kind,
      AiErrorCode.internal,
    );
  });

  group('checkAnswer', () {
    test('habit tips: bad items are dropped, at most 3', () {
      final data = GeminiAiClient.checkAnswer(AiFeature.habitSuggest, {
        'suggestions': [
          {'title': 'A', 'reason': 'r'},
          {'title': '', 'reason': 'r'},
          {'title': 'B', 'reason': 'r'},
          {'title': 'C', 'reason': 'r'},
          {'title': 'D', 'reason': 'r'},
        ],
      });
      expect((data!['suggestions'] as List).map((t) => (t as Map)['title']), [
        'A',
        'B',
        'C',
      ]);
    });

    test('study plan: sessions need the right fields', () {
      expect(
        GeminiAiClient.checkAnswer(AiFeature.studyPlan, {'sessions': []}),
        isNull,
      );
      expect(
        GeminiAiClient.checkAnswer(AiFeature.studyPlan, {
          'sessions': [
            {
              'subjectId': 's',
              'topicId': 't',
              'date': '2026-11-28',
              'startTime': '18:00',
              'plannedMinutes': 45,
            },
          ],
        }),
        isNotNull,
      );
    });
  });
}

/// Any error that is not a GeminiCallException.
class TimeoutExceptionForTest implements Exception {}
