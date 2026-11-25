// Tests for GatewayHabitSuggestionPort with a fake gateway call: it sends
// the feature with an EMPTY payload, reads the tips, and turns every
// problem into a Failure.

import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/habits/data/models/habit_suggestion_model.dart';
import 'package:brainly_life/features/habits/data/repositories/gateway_habit_suggestion_port.dart';
import 'package:cloud_functions/cloud_functions.dart'
    show FirebaseFunctionsException;
import 'package:flutter_test/flutter_test.dart';

void main() {
  String? sentFeature;
  Map<String, Object?>? sentPayload;

  GatewayHabitSuggestionPort port(
    Future<Object?> Function() answer, {
    bool aiEnabled = true,
  }) {
    return GatewayHabitSuggestionPort(
      aiEnabled: () => aiEnabled,
      call: (feature, payload) {
        sentFeature = feature;
        sentPayload = payload;
        return answer();
      },
    );
  }

  setUp(() {
    sentFeature = null;
    sentPayload = null;
  });

  test('reads up to 3 tips and sends nothing about the user', () async {
    final tip = {'title': 'Read at night', 'reason': 'You read most then.'};
    final result = await port(
      () async => {
        'ok': true,
        'data': {
          'suggestions': [tip, tip, tip, tip],
        },
      },
    ).getSuggestions();

    expect(sentFeature, 'habitSuggest');
    expect(sentPayload, isEmpty);
    expect(result.dataOrNull, hasLength(3));
    expect(
      result.dataOrNull!.first,
      const HabitSuggestion(
        title: 'Read at night',
        reason: 'You read most then.',
      ),
    );
  });

  test('AI off in Settings: no call, a clear failure', () async {
    final result = await port(
      () async => fail('should not call'),
      aiEnabled: false,
    ).getSuggestions();

    expect(sentFeature, isNull);
    expect((result as Failed).failure, isA<AiFailure>());
  });

  test('a gateway error shows the server message', () async {
    final result = await port(
      () async => {
        'ok': false,
        'error': {'code': 'rate_limited', 'message': 'Try again tomorrow.'},
      },
    ).getSuggestions();

    final failure = (result as Failed).failure;
    expect(failure.code, 'rate_limited');
    expect(failure.userMessage, 'Try again tomorrow.');
  });

  test('a broken answer or an exception is a failure', () async {
    final broken = await port(() async => 'oops').getSuggestions();
    final thrown = await port(
      () async =>
          throw FirebaseFunctionsException(code: 'internal', message: 'x'),
    ).getSuggestions();
    final offline = await port(
      () async =>
          throw FirebaseFunctionsException(code: 'unavailable', message: 'x'),
    ).getSuggestions();

    expect((broken as Failed).failure, isA<AiFailure>());
    expect((thrown as Failed).failure, isA<AiFailure>());
    expect((offline as Failed).failure, isA<NetworkFailure>());
  });
}
