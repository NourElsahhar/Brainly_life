import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/habits/data/models/habit_log_model.dart';
import 'package:brainly_life/features/habits/data/models/habit_model.dart';
import 'package:brainly_life/features/habits/data/repositories/habit_repository.dart';

/// In-memory [HabitRepository] for development and tests.
class MockHabitRepository implements HabitRepository {
  MockHabitRepository({
    List<Habit> habits = const [],
    List<HabitLog> logs = const [],
    DateTime Function()? now,
  }) : _habits = {for (final habit in habits) habit.id: habit},
       _logs = {for (final log in logs) log.id: log},
       _now = now ?? (() => DateTime.now().toUtc());

  /// A repository filled with sample habits and logs.
  factory MockHabitRepository.withSampleData() {
    final created = DateTime.utc(2026, 11, 1);
    return MockHabitRepository(
      habits: [
        Habit(
          id: 'sample_read',
          name: 'Read 20 pages',
          icon: 'book',
          colorValue: 0xFF2196F3,
          startDate: '2026-11-01',
          currentStreak: 3,
          bestStreak: 3,
          lastCompletedDate: '2026-11-14',
          createdAt: created,
          updatedAt: created,
        ),
        Habit(
          id: 'sample_gym',
          name: 'Gym',
          icon: 'fitness',
          colorValue: 0xFFE91E63,
          frequencyType: HabitFrequencyType.weekdays,
          weekdays: const [1, 3, 5],
          startDate: '2026-11-01',
          createdAt: created,
          updatedAt: created,
        ),
      ],
      logs: [
        for (final day in ['2026-11-12', '2026-11-13', '2026-11-14'])
          HabitLog(
            habitId: 'sample_read',
            date: day,
            completedAt: DateTime.utc(2026, 11, 14, 18),
          ),
      ],
    );
  }

  final Map<String, Habit> _habits;
  final Map<String, HabitLog> _logs;
  final DateTime Function() _now;
  int _counter = 0;

  @override
  Future<Result<List<Habit>>> getHabits({bool includeArchived = false}) async {
    final habits =
        _habits.values
            .where((habit) => includeArchived || !habit.archived)
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return Result.success(habits);
  }

  @override
  Future<Result<Habit>> createHabit(Habit habit) async {
    _counter++;
    final saved = habit.copyWith(id: 'mock_habit_$_counter');
    _habits[saved.id] = saved;
    return Result.success(saved);
  }

  @override
  Future<Result<void>> updateHabit(Habit habit) async {
    if (!_habits.containsKey(habit.id)) {
      return const Result.failure(NotFoundFailure());
    }
    _habits[habit.id] = habit.copyWith(updatedAt: _now());
    return const Result.success(null);
  }

  @override
  Future<Result<void>> archiveHabit(String habitId) async {
    final habit = _habits[habitId];
    if (habit == null) return const Result.failure(NotFoundFailure());
    _habits[habitId] = habit.copyWith(archived: true, updatedAt: _now());
    return const Result.success(null);
  }

  @override
  Future<Result<void>> deleteHabit(String habitId) async {
    if (_habits.remove(habitId) == null) {
      return const Result.failure(NotFoundFailure());
    }
    _logs.removeWhere((_, log) => log.habitId == habitId);
    return const Result.success(null);
  }

  @override
  Future<Result<List<HabitLog>>> getLogs({
    required String fromDate,
    required String toDate,
    String? habitId,
  }) async {
    final logs = _logs.values
        .where(
          (log) =>
              log.date.compareTo(fromDate) >= 0 &&
              log.date.compareTo(toDate) <= 0 &&
              (habitId == null || log.habitId == habitId),
        )
        .toList();
    return Result.success(logs);
  }

  @override
  Future<Result<bool>> toggleCompletion({
    required String habitId,
    required String dateKey,
  }) async {
    if (!_habits.containsKey(habitId)) {
      return const Result.failure(NotFoundFailure());
    }
    final id = HabitLog.buildId(habitId, dateKey);
    if (_logs.remove(id) != null) return const Result.success(false);
    _logs[id] = HabitLog(habitId: habitId, date: dateKey, completedAt: _now());
    return const Result.success(true);
  }
}
