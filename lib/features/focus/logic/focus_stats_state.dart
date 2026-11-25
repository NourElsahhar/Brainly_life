// States of the focus statistics screen: initial, loading, error, empty (no
// focus sessions yet) and loaded (the numbers, the chart data and the history).

import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/features/focus/data/models/focus_session_model.dart';
import 'package:equatable/equatable.dart';

/// Part of the day, used for "best time of day".
enum FocusDayPart {
  morning, // 05:00 to 11:59
  afternoon, // 12:00 to 17:59
  evening, // 18:00 to 20:59
  night; // 21:00 to 04:59

  static FocusDayPart fromHour(int hour) {
    if (hour >= 5 && hour < 12) return morning;
    if (hour >= 12 && hour < 18) return afternoon;
    if (hour >= 18 && hour < 21) return evening;
    return night;
  }
}

sealed class FocusStatsState extends Equatable {
  const FocusStatsState();

  @override
  List<Object?> get props => [];
}

class FocusStatsInitial extends FocusStatsState {
  const FocusStatsInitial();
}

class FocusStatsLoading extends FocusStatsState {
  const FocusStatsLoading();
}

class FocusStatsError extends FocusStatsState {
  const FocusStatsError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

/// No focus sessions yet. The screen shows zeros and a "Start focus" button.
class FocusStatsEmpty extends FocusStatsState {
  const FocusStatsEmpty();
}

class FocusStatsLoaded extends FocusStatsState {
  const FocusStatsLoaded({
    required this.today,
    required this.minutesToday,
    required this.minutesThisWeek,
    required this.focusDayStreak,
    required this.last7Days,
    required this.bestDayPart,
    required this.totalSessions,
    required this.history,
  });

  /// Today as a dateKey.
  final String today;

  final int minutesToday;

  /// Focus minutes of the current week (it starts on the user's week start day).
  final int minutesThisWeek;

  final int focusDayStreak;

  /// Focus minutes of each of the last 7 days (today last), keyed by dateKey.
  final Map<String, int> last7Days;

  /// Null only if no hour could be calculated.
  final FocusDayPart? bestDayPart;

  /// Number of focus blocks in the loaded history window.
  final int totalSessions;

  /// Most recent focus blocks, newest first.
  final List<FocusSession> history;

  @override
  List<Object?> get props => [
    today,
    minutesToday,
    minutesThisWeek,
    focusDayStreak,
    last7Days,
    bestDayPart,
    totalSessions,
    history,
  ];
}
