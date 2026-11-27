// Tests for AiHabitSuggestionPort: it sends the habit statistics through
// the shared AiClient and reads at most 3 tips.

import 'package:brainly_life/core/ai/ai.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/habits/data/models/habit_suggestion_model.dart';
import 'package:brainly_life/features/habits/data/repositories/ai_habit_suggestion_port.dart';
import 'package:brainly_life/features/habits/data/repositories/mock_habit_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAi implements AiClient {
  _FakeAi(this.answer);
  final Result<AiResponse> answer;
  AiRequest? sent;

  @override
  Future<Result<AiResponse>> generate(AiRequest request) async {
    sent = request;
    return answer;
  }
}

void main() {
  AiResponse response(List<Object?> tips) => AiResponse(
    data: {'suggestions': tips},
    usage: const AiUsage(remainingToday: 4, feature: AiFeature.habitSuggest),
  );

  test('sends the statistics and reads the tips', () async {
    const tip = {'title': 'Read at night', 'reason': 'You read most then.'};
    final ai = _FakeAi(Result.success(response([tip, tip, tip, tip])));
    final port = AiHabitSuggestionPort(
      client: ai,
      repository: MockHabitRepository.withSampleData(),
      timezone: () => 'Africa/Cairo',
    );

    final result = await port.getSuggestions();

    expect(ai.sent!.feature, AiFeature.habitSuggest);
    expect(ai.sent!.payload['habits'], isA<List<Object?>>());
    expect(result.dataOrNull, hasLength(3));
    expect(
      result.dataOrNull!.first,
      const HabitSuggestion(
        title: 'Read at night',
        reason: 'You read most then.',
      ),
    );
  });

  test('an AI failure is passed on', () async {
    final port = AiHabitSuggestionPort(
      client: _FakeAi(
        Result.failure(AiGatewayFailure(AiErrorCode.rateLimited)),
      ),
      repository: MockHabitRepository(),
      timezone: () => 'Africa/Cairo',
    );

    final result = await port.getSuggestions();

    expect(result.failureOrNull, isA<AiGatewayFailure>());
  });
}
