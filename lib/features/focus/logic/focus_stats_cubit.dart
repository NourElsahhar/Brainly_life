// FocusStatsCubit drives the focus statistics screen. It loads the last 90
// days of sessions once, then calculates today's minutes, this week's minutes,
// the focus-day streak, the 7-day chart, the best time of day, the number of
// sessions and the latest history. The calculations are in FocusStatsCalculator.
// `timezone` and `weekStartDay` come from the user's settings.

// ignore_for_file: prefer_initializing_formals

import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/core/utils/utils.dart';
import 'package:brainly_life/features/focus/data/models/focus_session_model.dart';
import 'package:brainly_life/features/focus/data/repositories/focus_repository.dart';
import 'package:brainly_life/features/focus/logic/focus_stats_calculator.dart';
import 'package:brainly_life/features/focus/logic/focus_stats_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FocusStatsCubit extends Cubit<FocusStatsState> {
  FocusStatsCubit({
    required FocusRepository repository,
    required String timezone,
    int weekStartDay = DateTime.monday,
  }) : _repository = repository,
       _timezone = timezone,
       _weekStartDay = weekStartDay,
       _calculator = FocusStatsCalculator(timezone: timezone),
       super(const FocusStatsInitial());

  /// How many days back the statistics look.
  static const int historyDays = 90;

  /// How many sessions the history list shows.
  static const int historyLimit = 20;

  final FocusRepository _repository;
  final String _timezone;
  final int _weekStartDay;
  final FocusStatsCalculator _calculator;

  Future<void> load() async {
    emit(const FocusStatsLoading());
    final today = DateKeyUtils.todayKey(timezone: _timezone);
    final from = DateKeyUtils.addDays(today, -(historyDays - 1));

    final result = await _repository.getSessions(fromDate: from, toDate: today);
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        emit(_build(data, today));
      case Failed(:final failure):
        emit(FocusStatsError(failure));
    }
  }

  FocusStatsState _build(List<FocusSession> sessions, String today) {
    final focus = sessions
        .where((session) => session.type == FocusSessionType.focus)
        .toList();
    if (focus.isEmpty) return const FocusStatsEmpty();

    final week = WeekUtils.weekDateKeys(today, weekStartDay: _weekStartDay);
    final weekMinutes = _calculator.minutesPerDay(
      sessions: focus,
      fromDate: week.first,
      toDate: week.last,
    );
    final last7 = _calculator.minutesPerDay(
      sessions: focus,
      fromDate: DateKeyUtils.addDays(today, -6),
      toDate: today,
    );
    final hour = _calculator.bestHour(focus);
    final newestFirst = [...focus]
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

    return FocusStatsLoaded(
      today: today,
      minutesToday: last7[today] ?? 0,
      minutesThisWeek: weekMinutes.values.fold(0, (sum, m) => sum + m),
      focusDayStreak: _calculator.focusDayStreak(sessions: focus, today: today),
      last7Days: last7,
      bestDayPart: hour == null ? null : FocusDayPart.fromHour(hour),
      totalSessions: _calculator.totalSessions(focus),
      history: newestFirst.take(historyLimit).toList(),
    );
  }
}
