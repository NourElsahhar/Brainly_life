import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/features/habits/data/models/habit_model.dart';
import 'package:brainly_life/features/habits/data/repositories/mock_habit_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clock/clock.dart';

void main() {
  final fixedNow = DateTime.utc(2026, 11, 15, 10);

  Habit newHabit(String name) => Habit(
    id: '',
    name: name,
    icon: 'book',
    colorValue: 0xFF2196F3,
    startDate: '2026-11-01',
    createdAt: DateTime.utc(2026, 11, 1),
    updatedAt: DateTime.utc(2026, 11, 1),
  );

  late MockHabitRepository repository;

  setUp(() {
    repository = MockHabitRepository(now: () => fixedNow);
  });

  test('createHabit gives the habit an id and getHabits returns it', () async {
    final created = (await repository.createHabit(newHabit('Read')))
        .dataOrNull!;
    expect(created.id, isNotEmpty);

    final habits = (await repository.getHabits()).dataOrNull!;
    expect(habits, [created]);
  });

  test('archived habits are hidden unless includeArchived is true', () async {
    final created = (await repository.createHabit(newHabit('Read')))
        .dataOrNull!;
    await repository.archiveHabit(created.id);

    expect((await repository.getHabits()).dataOrNull, isEmpty);
    expect(
      (await repository.getHabits(includeArchived: true))
          .dataOrNull!
          .single
          .archived,
      isTrue,
    );
  });

  test('toggleCompletion completes then un-completes the day', () async {
    final created = (await repository.createHabit(newHabit('Read')))
        .dataOrNull!;

    final first = await repository.toggleCompletion(
      habitId: created.id,
      dateKey: '2026-11-15',
    );
    expect(first.dataOrNull, isTrue);

    final second = await repository.toggleCompletion(
      habitId: created.id,
      dateKey: '2026-11-15',
    );
    expect(second.dataOrNull, isFalse);

    final logs = await repository.getLogs(
      fromDate: '2026-11-01',
      toDate: '2026-11-30',
    );
    expect(logs.dataOrNull, isEmpty);
  });

  test('getLogs returns only logs inside the date range', () async {
    final created = (await repository.createHabit(newHabit('Read')))
        .dataOrNull!;
    for (final day in ['2026-11-10', '2026-11-12', '2026-11-20']) {
      await repository.toggleCompletion(habitId: created.id, dateKey: day);
    }

    final logs = (await repository.getLogs(
      fromDate: '2026-11-11',
      toDate: '2026-11-15',
    )).dataOrNull!;
    expect(logs.map((log) => log.date), ['2026-11-12']);
  });

  test('deleteHabit also deletes its logs', () async {
    final created = (await repository.createHabit(newHabit('Read')))
        .dataOrNull!;
    await repository.toggleCompletion(
      habitId: created.id,
      dateKey: '2026-11-15',
    );
    await repository.deleteHabit(created.id);

    final logs = await repository.getLogs(
      fromDate: '2026-11-01',
      toDate: '2026-11-30',
    );
    expect(logs.dataOrNull, isEmpty);
  });

  test('unknown habit returns NotFoundFailure', () async {
    final result = await repository.toggleCompletion(
      habitId: 'nope',
      dateKey: '2026-11-15',
    );
    expect(result.failureOrNull, isA<NotFoundFailure>());
  });

  test('toggleCompletion updates the streak fields of the habit', () async {
    await withClock(Clock.fixed(DateTime.utc(2026, 11, 15, 10)), () async {
      final created = (await repository.createHabit(newHabit('Read')))
          .dataOrNull!;
      for (final day in ['2026-11-13', '2026-11-14', '2026-11-15']) {
        await repository.toggleCompletion(habitId: created.id, dateKey: day);
      }

      final habit = (await repository.getHabits()).dataOrNull!.single;
      expect(habit.currentStreak, 3);
      expect(habit.bestStreak, 3);
      expect(habit.lastCompletedDate, '2026-11-15');
    });
  });
}
