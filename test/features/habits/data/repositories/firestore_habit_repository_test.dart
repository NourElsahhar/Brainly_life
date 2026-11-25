// Tests for FirestoreHabitRepository with a fake data source (mocktail):
// the toggle flips the day and saves the new streak in one call, a missing
// habit is NotFoundFailure, Firebase errors become Failures, archived
// habits are hidden.

import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/habits/data/datasources/habit_remote_data_source.dart';
import 'package:brainly_life/features/habits/data/models/habit_model.dart';
import 'package:brainly_life/features/habits/data/repositories/firestore_habit_repository.dart';
import 'package:clock/clock.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDataSource extends Mock implements HabitRemoteDataSource {}

void main() {
  final today = Clock.fixed(DateTime.utc(2026, 11, 25, 10));
  late _MockDataSource dataSource;
  late FirestoreHabitRepository repository;

  Habit habit(String id, {bool archived = false, int day = 1}) => Habit(
    id: id,
    name: id,
    icon: 'book',
    colorValue: 0xFF2196F3,
    startDate: '2026-11-01',
    archived: archived,
    createdAt: DateTime.utc(2026, 11, day),
    updatedAt: DateTime.utc(2026, 11, day),
  );

  setUpAll(() {
    registerFallbackValue(DateTime.utc(2026));
    registerFallbackValue(habit('fallback'));
  });

  setUp(() {
    dataSource = _MockDataSource();
    repository = FirestoreHabitRepository(
      dataSource: dataSource,
      timezone: () => 'UTC',
      weekStartDay: () => 1,
      now: () => DateTime.utc(2026, 11, 25, 10),
    );
    when(
      () => dataSource.writeToggle(
        habitId: any(named: 'habitId'),
        dateKey: any(named: 'dateKey'),
        done: any(named: 'done'),
        now: any(named: 'now'),
        currentStreak: any(named: 'currentStreak'),
        bestStreak: any(named: 'bestStreak'),
        lastCompletedDate: any(named: 'lastCompletedDate'),
      ),
    ).thenAnswer((_) async {});
  });

  test('toggle on: saves the log and the new streak', () async {
    when(() => dataSource.getHabit('h1')).thenAnswer((_) async => habit('h1'));
    when(() => dataSource.completedDates('h1'))
        .thenAnswer((_) async => {'2026-11-23', '2026-11-24'});

    final result = await withClock(
      today,
      () => repository.toggleCompletion(habitId: 'h1', dateKey: '2026-11-25'),
    );

    expect(result.dataOrNull, isTrue);
    verify(
      () => dataSource.writeToggle(
        habitId: 'h1',
        dateKey: '2026-11-25',
        done: true,
        now: any(named: 'now'),
        currentStreak: 3,
        bestStreak: 3,
        lastCompletedDate: '2026-11-25',
      ),
    ).called(1);
  });

  test('toggle off: removes the day and lowers the streak', () async {
    when(() => dataSource.getHabit('h1')).thenAnswer((_) async => habit('h1'));
    when(() => dataSource.completedDates('h1'))
        .thenAnswer((_) async => {'2026-11-24', '2026-11-25'});

    final result = await withClock(
      today,
      () => repository.toggleCompletion(habitId: 'h1', dateKey: '2026-11-25'),
    );

    expect(result.dataOrNull, isFalse);
    verify(
      () => dataSource.writeToggle(
        habitId: 'h1',
        dateKey: '2026-11-25',
        done: false,
        now: any(named: 'now'),
        currentStreak: 1,
        bestStreak: 1,
        lastCompletedDate: '2026-11-24',
      ),
    ).called(1);
  });

  test('toggle of a missing habit is NotFoundFailure', () async {
    when(() => dataSource.getHabit('nope')).thenAnswer((_) async => null);

    final result = await repository.toggleCompletion(
      habitId: 'nope',
      dateKey: '2026-11-25',
    );

    expect((result as Failed).failure, isA<NotFoundFailure>());
  });

  test('a Firebase error becomes a Failure (no exception)', () async {
    when(() => dataSource.getHabits()).thenThrow(
      FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
    );

    final result = await repository.getHabits();

    expect(result, isA<Failed<List<Habit>>>());
  });

  test('getHabits hides archived habits and sorts by creation', () async {
    when(() => dataSource.getHabits()).thenAnswer(
      (_) async => [
        habit('b', day: 5),
        habit('old', archived: true, day: 1),
        habit('a', day: 2),
      ],
    );

    final active = await repository.getHabits();
    final all = await repository.getHabits(includeArchived: true);

    expect(active.dataOrNull!.map((h) => h.id), ['a', 'b']);
    expect(all.dataOrNull!.map((h) => h.id), ['old', 'a', 'b']);
  });

  test('createHabit sets createdAt and updatedAt to now', () async {
    when(() => dataSource.createHabit(any())).thenAnswer(
      (invocation) async =>
          (invocation.positionalArguments.first as Habit).copyWith(id: 'new'),
    );

    final result = await repository.createHabit(habit(''));

    expect(result.dataOrNull!.id, 'new');
    expect(result.dataOrNull!.createdAt, DateTime.utc(2026, 11, 25, 10));
  });
}
