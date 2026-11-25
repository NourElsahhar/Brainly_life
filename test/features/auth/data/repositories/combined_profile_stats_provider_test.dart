// Tests for CombinedProfileStatsProvider and the habits/focus sources:
// each number comes from its source, a missing or failing source shows 0.

import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/auth/data/repositories/profile_stats_provider.dart';
import 'package:brainly_life/features/focus/data/models/focus_session_model.dart';
import 'package:brainly_life/features/focus/data/repositories/focus_profile_study_source.dart';
import 'package:brainly_life/features/focus/data/repositories/mock_focus_repository.dart';
import 'package:brainly_life/features/habits/data/models/habit_model.dart';
import 'package:brainly_life/features/habits/data/repositories/habit_profile_streak_source.dart';
import 'package:brainly_life/features/habits/data/repositories/mock_habit_repository.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

class _Tasks implements ProfileTasksSource {
  _Tasks(this.result);
  final Result<int> result;
  @override
  Future<Result<int>> tasksDone() async => result;
}

class _Streak implements ProfileStreakSource {
  @override
  Future<Result<int>> streakDays() => throw StateError('boom');
}

void main() {
  Habit habit(String id, int streak, {bool archived = false}) => Habit(
    id: id,
    name: id,
    icon: 'book',
    colorValue: 0xFF2196F3,
    startDate: '2026-11-01',
    archived: archived,
    currentStreak: streak,
    createdAt: DateTime.utc(2026, 11, 1),
    updatedAt: DateTime.utc(2026, 11, 1),
  );

  FocusSession session(String id, FocusSessionType type, int minutes) {
    final start = DateTime.utc(2026, 11, 20, 9);
    return FocusSession(
      id: id,
      type: type,
      startedAt: start,
      endedAt: start.add(Duration(minutes: minutes)),
      plannedMinutes: minutes,
      actualMinutes: minutes,
      completed: true,
      dateKey: '2026-11-20',
      createdAt: start,
      updatedAt: start,
    );
  }

  test('habits: the best current streak of the active habits', () async {
    final source = HabitProfileStreakSource(
      MockHabitRepository(
        habits: [
          habit('a', 3),
          habit('b', 7),
          habit('old', 40, archived: true),
        ],
      ),
    );

    expect((await source.streakDays()).dataOrNull, 7);
  });

  test('focus: every focus minute, breaks not counted', () async {
    final source = FocusProfileStudySource(
      repository: MockFocusRepository(
        sessions: [
          session('s1', FocusSessionType.focus, 25),
          session('s2', FocusSessionType.focus, 50),
          session('s3', FocusSessionType.shortBreak, 5),
        ],
      ),
      timezone: () => 'UTC',
    );

    final minutes = await withClock(
      Clock.fixed(DateTime.utc(2026, 11, 25)),
      source.studiedMinutes,
    );

    expect(minutes.dataOrNull, 75);
  });

  test('combined: missing, failing or throwing sources show 0', () async {
    final provider = CombinedProfileStatsProvider(
      streak: () => _Streak(),
      study: () => null,
      tasks: () => _Tasks(const Result.failure(NetworkFailure())),
    );

    expect((await provider.load()).dataOrNull, ProfileStats.empty);
  });

  test('combined: the three numbers from their sources', () async {
    final provider = CombinedProfileStatsProvider(
      streak: () => HabitProfileStreakSource(
        MockHabitRepository(habits: [habit('a', 4)]),
      ),
      study: () => null,
      tasks: () => _Tasks(const Result.success(12)),
    );

    expect(
      (await provider.load()).dataOrNull,
      const ProfileStats(streakDays: 4, studiedMinutes: 0, tasksDone: 12),
    );
  });
}
