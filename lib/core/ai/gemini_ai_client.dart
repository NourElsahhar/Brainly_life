// GeminiAiClient = the real AiClient WITHOUT Cloud Functions.
//
// The team has no Blaze plan, so the app talks to Gemini directly through
// Firebase AI Logic (Gemini Developer API, free on the Spark plan).
// Everything the aiGateway function did now happens here, on the phone:
//   1. AI off in Settings -> `disabled` (no call)
//   2. payload over 20 KB -> `payloadTooLarge`
//   3. daily limit per feature (counted on this phone) -> `rateLimited`
//   4. builds the prompt (GeminiPrompts) with the app's data
//   5. calls Gemini in JSON mode, checks the answer, retries once if the
//      answer is broken
//   6. weeklyInsight: saves the report in users/{uid}/weeklyReports
//
// The screens and cubits do not change: they only know AiClient.
//
// Firebase is only in [GeminiCall] (firebase_gemini_call.dart), so this
// class is tested with a fake call.

// ignore_for_file: prefer_initializing_formals, unintended_html_in_doc_comment

import 'dart:async';
import 'dart:convert';

import '../errors/failure.dart';
import '../errors/result.dart';
import 'ai_client.dart';
import 'ai_failures.dart';
import 'ai_models.dart';
import 'gemini_prompts.dart';

/// Sends one prompt to Gemini and returns its text (JSON), or throws
/// [GeminiCallException].
typedef GeminiCall = Future<String?> Function(
  AiPrompt prompt, {
  required double temperature,
});

/// A problem of the Gemini call, already turned into a gateway error code.
class GeminiCallException implements Exception {
  const GeminiCallException(this.code);

  final AiErrorCode code;

  @override
  String toString() => 'GeminiCallException(${code.wireName})';
}

/// Counts the AI calls of a day (key = '<day>_<feature>').
abstract interface class AiUsageCounter {
  Future<int> used(String key);
  Future<void> add(String key);
}

/// For tests and the first run.
class MemoryAiUsageCounter implements AiUsageCounter {
  final Map<String, int> _counts = {};

  @override
  Future<int> used(String key) async => _counts[key] ?? 0;

  @override
  Future<void> add(String key) async => _counts[key] = (_counts[key] ?? 0) + 1;
}

class GeminiAiClient implements AiClient {
  GeminiAiClient({
    required GeminiCall call,
    required Future<bool> Function() isEnabled,
    required AiUsageCounter usage,
    required Future<String> Function() today,
    Future<Map<String, Object?>> Function()? chatContext,
    Future<void> Function(
      String weekKey,
      Map<String, Object?> stats,
      Map<String, Object?> report,
    )?
    saveWeeklyReport,
  }) : _call = call,
       _isEnabled = isEnabled,
       _usage = usage,
       _today = today,
       _chatContext = chatContext,
       _saveWeeklyReport = saveWeeklyReport;

  /// Calls per feature per day (same as the server modules).
  static const Map<AiFeature, int> dailyLimits = {
    AiFeature.studyPlan: 5,
    AiFeature.habitSuggest: 5,
    AiFeature.chat: 20,
    AiFeature.dailyTip: 3,
    AiFeature.weeklyInsight: 3,
  };

  static const Map<AiFeature, double> temperatures = {
    AiFeature.studyPlan: 0.3,
    AiFeature.habitSuggest: 0.4,
    AiFeature.chat: 0.7,
    AiFeature.dailyTip: 0.7,
    AiFeature.weeklyInsight: 0.3,
  };

  static const int maxPayloadBytes = 20 * 1024;
  static const Duration timeout = Duration(seconds: 60);

  final GeminiCall _call;
  final Future<bool> Function() _isEnabled;
  final AiUsageCounter _usage;
  final Future<String> Function() _today;
  final Future<Map<String, Object?>> Function()? _chatContext;
  final Future<void> Function(
    String weekKey,
    Map<String, Object?> stats,
    Map<String, Object?> report,
  )?
  _saveWeeklyReport;

  @override
  Future<Result<AiResponse>> generate(AiRequest request) async {
    try {
      if (!await _isEnabled()) {
        return Result.failure(AiGatewayFailure(AiErrorCode.disabled));
      }
      final payload = Map<String, Object?>.from(request.payload);
      if (utf8.encode(jsonEncode(payload)).length > maxPayloadBytes) {
        return Result.failure(AiGatewayFailure(AiErrorCode.payloadTooLarge));
      }

      final feature = request.feature;
      final limit = dailyLimits[feature]!;
      final key = '${await _today()}_${feature.name}';
      final used = await _usage.used(key);
      if (used >= limit) {
        return Result.failure(AiGatewayFailure(AiErrorCode.rateLimited));
      }

      final prompt = await _prompt(feature, payload);
      final data = await _ask(feature, prompt);
      if (data == null) {
        return Result.failure(AiGatewayFailure(AiErrorCode.invalidResponse));
      }
      await _usage.add(key);

      if (feature == AiFeature.weeklyInsight) {
        final save = _saveWeeklyReport;
        if (save == null) {
          return Result.failure(AiGatewayFailure(AiErrorCode.internal));
        }
        await save(
          '${payload['weekKey']}',
          Map<String, Object?>.from(payload['stats'] as Map),
          data,
        );
      }

      return Result.success(
        AiResponse(
          data: data,
          usage: AiUsage(remainingToday: limit - used - 1, feature: feature),
        ),
      );
    } on GeminiCallException catch (error) {
      return Result.failure(AiGatewayFailure(error.code));
    } on TimeoutException {
      return const Result.failure(
        NetworkFailure(userMessage: 'Baseet AI timed out. Please try again.'),
      );
    } catch (_) {
      return Result.failure(AiGatewayFailure(AiErrorCode.internal));
    }
  }

  Future<AiPrompt> _prompt(
    AiFeature feature,
    Map<String, Object?> payload,
  ) async => switch (feature) {
    AiFeature.studyPlan => GeminiPrompts.studyPlan(payload),
    AiFeature.habitSuggest => GeminiPrompts.habitSuggest(payload),
    AiFeature.chat => GeminiPrompts.chat(payload, await _safeContext()),
    AiFeature.dailyTip => GeminiPrompts.dailyTip(),
    AiFeature.weeklyInsight => GeminiPrompts.weeklyInsight(payload),
  };

  /// The chat still works when the app data cannot be read.
  Future<Map<String, Object?>> _safeContext() async {
    try {
      return await _chatContext?.call() ?? const {};
    } catch (_) {
      return const {'note': 'The app data could not be loaded right now.'};
    }
  }

  /// Asks Gemini; a broken answer is retried once (like the gateway).
  Future<Map<String, Object?>?> _ask(AiFeature feature, AiPrompt prompt) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      final text = await _call(
        prompt,
        temperature: temperatures[feature]!,
      ).timeout(timeout);
      final data = checkAnswer(feature, decodeJson(text));
      if (data != null) return data;
    }
    return null;
  }

  /// The JSON object in Gemini's text (also inside ```json fences).
  static Map<String, Object?>? decodeJson(String? text) {
    if (text == null) return null;
    var body = text.trim();
    if (body.startsWith('```')) {
      body = body
          .replaceFirst(RegExp(r'^```[a-zA-Z]*\s*'), '')
          .replaceFirst(RegExp(r'\s*```$'), '');
    }
    try {
      final value = jsonDecode(body);
      return value is Map ? Map<String, Object?>.from(value) : null;
    } on FormatException {
      return null;
    }
  }

  /// Checks the answer's shape (like the server's responseSchema) and
  /// fixes small problems. null = broken answer.
  static Map<String, Object?>? checkAnswer(
    AiFeature feature,
    Map<String, Object?>? data,
  ) {
    if (data == null) return null;
    switch (feature) {
      case AiFeature.studyPlan:
        final sessions = data['sessions'];
        if (sessions is! List || sessions.isEmpty || sessions.length > 240) {
          return null;
        }
        final valid = sessions.every(
          (s) =>
              s is Map &&
              s['subjectId'] is String &&
              s['topicId'] is String &&
              s['date'] is String &&
              s['startTime'] is String &&
              s['plannedMinutes'] is int,
        );
        // M2's PlanValidator checks the rest before anything is saved.
        return valid ? {'sessions': sessions} : null;

      case AiFeature.habitSuggest:
        final list = data['suggestions'];
        if (list is! List) return null;
        final tips = [
          for (final item in list)
            if (item is Map &&
                _text(item['title'], 80) != null &&
                _text(item['reason'], 160) != null)
              {
                'title': _text(item['title'], 80),
                'reason': _text(item['reason'], 160),
              },
        ];
        return {'suggestions': tips.take(3).toList()};

      case AiFeature.chat:
        final reply = _text(data['reply'], 4000);
        if (reply == null) return null;
        final actions = data['actions'];
        return {
          'reply': reply,
          // Unknown actions are ignored later by the chat.
          'actions': actions is List
              ? actions.whereType<Map>().take(4).toList()
              : const <Object?>[],
        };

      case AiFeature.dailyTip:
        final tip = _text(data['tip'], 240);
        return tip == null ? null : {'tip': tip};

      case AiFeature.weeklyInsight:
        final summary = _text(data['summary'], 1200);
        final list = data['recommendations'];
        if (summary == null || list is! List) return null;
        final tips = [
          for (final item in list)
            if (_text(item, 240) case final String text) text,
        ];
        if (tips.length < 3) return null;
        return {'summary': summary, 'recommendations': tips.take(3).toList()};
    }
  }

  /// Trimmed text of 1..max characters, else null.
  static String? _text(Object? value, int max) {
    if (value is! String) return null;
    final text = value.trim();
    if (text.isEmpty || text.length > max) return null;
    return text;
  }
}
