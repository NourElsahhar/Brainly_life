// Tests for FocusStatsCubit: the numbers of a normal history, the week
// boundary for two week start days, the empty state, breaks being ignored,
// a failing repository, and the best-time-of-day buckets.

import 'package:bloc_test/bloc_test.dart';
import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/core/utils/utils.dart';
import 'package:brainly_life/features/focus/data/models/focus_session_model.dart';
import 'package:brainly_life/features/focus/data/repositories/mock_focus_repository.dart';
import 'package:brainly_life/features/focus/logic/focus_stats_cubit.dart';
import 'package:brainly_life/features/focus/logic/focus_stats_state.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingRepository extends MockFocusRepository {
  @override
  Future<Result<List<FocusSession>>> getSessions({
    required String fromDate,
    required String toDate,
  }) async => const Result.failure(NetworkFailure());
}

void main() {
  // Monday 2026-11-16.
  final monday = Clock.fixed(DateTime.utc(2026, 11, 16, 10));

  Future<void> at(Future<void> Function() body) => withClock(monday, body);

  FocusSession session(
    String id,
    String dateKey,
    int hour,
    int minutes, {
    FocusSessionType type = FocusSessionType.focus,
  }) {
    final day = DateKeyUtils.parse(dateKey);
    final start = DateTime.utc(day.year, day.month, day.day, hour);
    return FocusSession(
      id: id,
      type: type,
      startedAt: start,
      endedAt: start.add(Duration(minutes: minutes)),
      plannedMinutes: 25,
      actualMinutes: minutes,
      completed: true,
      dateKey: dateKey,
      createdAt: start,
      updatedAt: start,
    );
  }

  final history = [
    session('today_a', '2026-11-16', 9, 25),
    session('today_b', '2026-11-16', 15, 10),
    session(
      'today_break',
      '2026-11-16',
      16,
      5,
      type: FocusSessionType.shortBreak,
    ),
    session('sunday', '2026-11-15', 9, 25),
    session('saturday', '2026-11-14', 9, 25),
    session('older', '2026-11-05', 9, 30),
  ];

  FocusStatsCubit buildCubit(
    MockFocusRepository repository, {
    int weekStartDay = DateTime.monday,
  }) => FocusStatsCubit(
    repository: repository,
    timezone: 'UTC',
    weekStartDay: weekStartDay,
  );

  blocTest<FocusStatsCubit, FocusStatsState>(
    'load emits loading then the statistics',
    build: () => buildCubit(MockFocusRepository(sessions: history)),
    act: (cubit) => at(() => cubit.load()),
    expect: () => [
      const FocusStatsLoading(),
      isA<FocusStatsLoaded>()
          .having((s) => s.today, 'today', '2026-11-16')
          .having((s) => s.minutesToday, 'minutesToday', 35)
          .having((s) => s.minutesThisWeek, 'minutesThisWeek', 35)
          .having((s) => s.focusDayStreak, 'focusDayStreak', 3)
          .having((s) => s.totalSessions, 'totalSessions', 5)
          .having((s) => s.bestDayPart, 'bestDayPart', FocusDayPart.morning)
          .having((s) => s.last7Days, 'last7Days', {
            '2026-11-10': 0,
            '2026-11-11': 0,
            '2026-11-12': 0,
            '2026-11-13': 0,
            '2026-11-14': 25,
            '2026-11-15': 25,
            '2026-11-16': 35,
          })
          .having(
            (s) => s.history.map((item) => item.id).toList(),
            'history newest first',
            ['today_b', 'today_a', 'sunday', 'saturday', 'older'],
          ),
    ],
  );

  blocTest<FocusStatsCubit, FocusStatsState>(
    'the week starts on the chosen week start day',
    build: () => buildCubit(
      MockFocusRepository(sessions: history),
      weekStartDay: DateTime.sunday,
    ),
    act: (cubit) => at(() => cubit.load()),
    skip: 1,
    expect: () => [
      isA<FocusStatsLoaded>().having(
        (s) => s.minutesThisWeek,
        'minutesThisWeek',
        60,
      ),
    ],
  );

  blocTest<FocusStatsCubit, FocusStatsState>(
    'no sessions gives the empty state',
    build: () => buildCubit(MockFocusRepository()),
    act: (cubit) => at(() => cubit.load()),
    expect: () => [const FocusStatsLoading(), const FocusStatsEmpty()],
  );

  blocTest<FocusStatsCubit, FocusStatsState>(
    'breaks alone give the empty state',
    build: () => buildCubit(
      MockFocusRepository(
        sessions: [
          session('b', '2026-11-16', 9, 5, type: FocusSessionType.shortBreak),
        ],
      ),
    ),
    act: (cubit) => at(() => cubit.load()),
    expect: () => [const FocusStatsLoading(), const FocusStatsEmpty()],
  );

  blocTest<FocusStatsCubit, FocusStatsState>(
    'a failing repository gives the error state',
    build: () => buildCubit(_FailingRepository()),
    act: (cubit) => at(() => cubit.load()),
    expect: () => [
      const FocusStatsLoading(),
      const FocusStatsError(NetworkFailure()),
    ],
  );

  test('FocusDayPart buckets the hours of the day', () {
    expect(FocusDayPart.fromHour(4), FocusDayPart.night);
    expect(FocusDayPart.fromHour(5), FocusDayPart.morning);
    expect(FocusDayPart.fromHour(11), FocusDayPart.morning);
    expect(FocusDayPart.fromHour(12), FocusDayPart.afternoon);
    expect(FocusDayPart.fromHour(17), FocusDayPart.afternoon);
    expect(FocusDayPart.fromHour(18), FocusDayPart.evening);
    expect(FocusDayPart.fromHour(20), FocusDayPart.evening);
    expect(FocusDayPart.fromHour(21), FocusDayPart.night);
    expect(FocusDayPart.fromHour(0), FocusDayPart.night);
  });
}
