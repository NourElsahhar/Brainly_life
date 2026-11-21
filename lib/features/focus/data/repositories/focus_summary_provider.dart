// DefaultFocusSummaryProvider feeds the "Focus" card on the Home dashboard:
// focus minutes and focus blocks of today (breaks are not counted).
// `timezone` returns the user's timezone (settings.timezone).

// ignore_for_file: prefer_initializing_formals

import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/core/utils/utils.dart';
import 'package:brainly_life/features/focus/data/repositories/focus_repository.dart';
import 'package:brainly_life/features/focus/logic/focus_stats_calculator.dart';
import 'package:brainly_life/features/home/data/repositories/home_summary_port.dart';

class DefaultFocusSummaryProvider implements FocusSummaryProvider {
  DefaultFocusSummaryProvider({
    required FocusRepository repository,
    required String Function() timezone,
  }) : _repository = repository,
       _timezone = timezone;

  final FocusRepository _repository;
  final String Function() _timezone;

  @override
  Future<Result<FocusSummary>> todaySummary() async {
    final timezone = _timezone();
    final today = DateKeyUtils.todayKey(timezone: timezone);
    final calculator = FocusStatsCalculator(timezone: timezone);

    final result = await _repository.getSessions(
      fromDate: today,
      toDate: today,
    );
    return result.fold<Result<FocusSummary>>(
      onSuccess: (sessions) => Result.success(
        FocusSummary(
          minutesToday: calculator.totalMinutes(sessions),
          sessionsToday: calculator.totalSessions(sessions),
        ),
      ),
      onFailure: (failure) => Result.failure(failure),
    );
  }
}
