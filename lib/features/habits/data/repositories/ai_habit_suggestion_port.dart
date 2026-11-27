// AiHabitSuggestionPort = the real HabitSuggestionPort (owner: M4).
//
// It builds the habit statistics of the last 30 days (HabitAiStats) and
// asks the shared AiClient (feature habitSuggest). The AiClient checks
// "Use AI features", the daily limit and the answer's shape.

// ignore_for_file: prefer_initializing_formals

import 'package:brainly_life/core/ai/ai_client.dart';
import 'package:brainly_life/core/ai/ai_models.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/core/utils/date_key_utils.dart';
import 'package:brainly_life/features/habits/data/models/habit_suggestion_model.dart';
import 'package:brainly_life/features/habits/data/repositories/habit_repository.dart';
import 'package:brainly_life/features/habits/data/repositories/habit_suggestion_port.dart';
import 'package:brainly_life/features/habits/logic/habit_ai_stats.dart';

class AiHabitSuggestionPort implements HabitSuggestionPort {
  AiHabitSuggestionPort({
    required AiClient client,
    required HabitRepository repository,
    required String Function() timezone,
  }) : _client = client,
       _repository = repository,
       _timezone = timezone;

  static const int maxSuggestions = 3;

  final AiClient _client;
  final HabitRepository _repository;
  final String Function() _timezone;

  @override
  Future<Result<List<HabitSuggestion>>> getSuggestions() async {
    final today = DateKeyUtils.todayKey(timezone: _timezone());

    final habits = await _repository.getHabits();
    if (habits case Failed(:final failure)) return Result.failure(failure);
    final logs = await _repository.getLogs(
      fromDate: HabitAiStats.firstDay(today),
      toDate: today,
    );
    if (logs case Failed(:final failure)) return Result.failure(failure);

    final result = await _client.generate(
      AiRequest(
        feature: AiFeature.habitSuggest,
        payload: HabitAiStats.payload(
          today: today,
          habits: habits.dataOrNull!,
          logs: logs.dataOrNull!,
        ),
      ),
    );
    return result.fold(
      onSuccess: (response) {
        final list = response.data['suggestions'];
        return Result.success([
          if (list is List)
            for (final item in list.take(maxSuggestions))
              if (item is Map &&
                  item['title'] is String &&
                  item['reason'] is String)
                HabitSuggestion(
                  title: item['title'] as String,
                  reason: item['reason'] as String,
                ),
        ]);
      },
      onFailure: (failure) => Result.failure(failure),
    );
  }
}
