// GatewayHabitSuggestionPort = the real HabitSuggestionPort (owner: M4).
//
// It calls the aiGateway Cloud Function with
//   {feature: 'habitSuggest', payload: {}}
// The payload is empty on purpose: the server reads the habits itself with
// the signed-in uid, so nothing about the user is sent from the phone.
//
// When M5's AiClient is merged, this class can call it instead; the screen
// does not change because it only knows HabitSuggestionPort.

// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/core/utils/app_logger.dart';
import 'package:brainly_life/features/habits/data/models/habit_suggestion_model.dart';
import 'package:brainly_life/features/habits/data/repositories/habit_suggestion_port.dart';
import 'package:cloud_functions/cloud_functions.dart'
    show FirebaseFunctions, FirebaseFunctionsException, HttpsCallableOptions;
/// Calls the gateway and returns its JSON answer. A function, so tests can
/// replace it without Firebase.
typedef AiGatewayCall = Future<Object?> Function(
  String feature,
  Map<String, Object?> payload,
);

class GatewayHabitSuggestionPort implements HabitSuggestionPort {
  GatewayHabitSuggestionPort({
    required AiGatewayCall call,
    required bool Function() aiEnabled,
  }) : _call = call,
       _aiEnabled = aiEnabled;

  /// The real call: the aiGateway callable function.
  factory GatewayHabitSuggestionPort.firebase({
    required FirebaseFunctions functions,
    required bool Function() aiEnabled,
  }) {
    final callable = functions.httpsCallable(
      'aiGateway',
      options: HttpsCallableOptions(timeout: timeout),
    );
    return GatewayHabitSuggestionPort(
      aiEnabled: aiEnabled,
      call: (feature, payload) async {
        final result = await callable.call<Object?>({
          'feature': feature,
          'payload': payload,
        });
        return result.data;
      },
    );
  }

  static const String feature = 'habitSuggest';
  static const Duration timeout = Duration(seconds: 60);
  static const int maxSuggestions = 3;

  static const _unavailable = AiFailure(
    userMessage: 'Suggestions are unavailable right now.',
  );

  final AiGatewayCall _call;
  final bool Function() _aiEnabled;

  @override
  Future<Result<List<HabitSuggestion>>> getSuggestions() async {
    if (!_aiEnabled()) {
      return const Result.failure(
        AiFailure(
          userMessage: 'AI features are off. Turn them on in Settings.',
          code: 'ai_disabled',
        ),
      );
    }
    try {
      final answer = await _call(feature, const {});
      return _parse(answer);
    } on FirebaseFunctionsException catch (e) {
      AppLogger.warning('habitSuggest: ${e.code} ${e.message}', tag: 'Habits');
      if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
        return const Result.failure(
          NetworkFailure(
            userMessage: 'No connection. Please try again.',
            code: 'network',
          ),
        );
      }
      return const Result.failure(_unavailable);
    } on TimeoutException {
      return const Result.failure(
        NetworkFailure(
          userMessage: 'The server is taking too long. Please try again.',
          code: 'timeout',
        ),
      );
    } catch (e) {
      AppLogger.warning('habitSuggest failed: $e', tag: 'Habits');
      return const Result.failure(_unavailable);
    }
  }

  /// Reads {ok, data: {suggestions: [...]}} or {ok: false, error: {...}}.
  static Result<List<HabitSuggestion>> _parse(Object? answer) {
    if (answer is! Map) return const Result.failure(_unavailable);
    if (answer['ok'] != true) {
      final error = answer['error'];
      final code = error is Map ? error['code'] as String? : null;
      final message = error is Map ? error['message'] as String? : null;
      return Result.failure(
        AiFailure(
          userMessage: (message == null || message.isEmpty)
              ? _unavailable.userMessage
              : message,
          code: code,
        ),
      );
    }
    final data = answer['data'];
    final list = data is Map ? data['suggestions'] : null;
    if (list is! List) return const Result.failure(_unavailable);
    final tips = <HabitSuggestion>[
      for (final item in list)
        if (item is Map &&
            item['title'] is String &&
            item['reason'] is String &&
            (item['title'] as String).trim().isNotEmpty)
          HabitSuggestion(
            title: (item['title'] as String).trim(),
            reason: (item['reason'] as String).trim(),
          ),
    ];
    return Result.success(tips.take(maxSuggestions).toList());
  }
}
