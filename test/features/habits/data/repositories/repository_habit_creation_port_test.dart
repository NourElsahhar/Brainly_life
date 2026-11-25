// Tests for RepositoryHabitCreationPort: the same rules as the habit form,
// and a valid draft is saved with today's start date.

import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/habits/data/models/habit_model.dart';
import 'package:brainly_life/features/habits/data/repositories/habit_creation_port.dart';
import 'package:brainly_life/features/habits/data/repositories/mock_habit_repository.dart';
import 'package:brainly_life/features/habits/data/repositories/repository_habit_creation_port.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockHabitRepository repository;
  late RepositoryHabitCreationPort port;

  setUp(() {
    repository = MockHabitRepository();
    port = RepositoryHabitCreationPort(
      repository,
      timezone: () => 'UTC',
      now: () => DateTime.utc(2026, 11, 25, 10),
    );
  });

  Future<Failure?> failureOf(HabitDraft draft) async {
    final result = await port.createHabit(draft);
    return result is Failed<String> ? result.failure : null;
  }

  test('a valid draft is saved', () async {
    final result = await port.createHabit(
      const HabitDraft(
        name: '  Drink water ',
        frequencyType: HabitFrequencyType.weekdays,
        weekdays: [5, 1, 1],
      ),
    );

    final id = result.dataOrNull!;
    final saved = (await repository.getHabits()).dataOrNull!.single;
    expect(saved.id, id);
    expect(saved.name, 'Drink water');
    expect(saved.weekdays, [1, 5]);
    expect(saved.startDate, '2026-11-25');
    expect(saved.timesPerWeek, isNull);
  });

  test('bad drafts are ValidationFailure', () async {
    final bad = [
      const HabitDraft(name: '   '),
      HabitDraft(name: 'x' * (Habit.maxNameLength + 1)),
      const HabitDraft(name: 'Gym', frequencyType: HabitFrequencyType.weekdays),
      const HabitDraft(
        name: 'Gym',
        frequencyType: HabitFrequencyType.weekdays,
        weekdays: [8],
      ),
      const HabitDraft(
        name: 'Gym',
        frequencyType: HabitFrequencyType.timesPerWeek,
      ),
      const HabitDraft(
        name: 'Gym',
        frequencyType: HabitFrequencyType.timesPerWeek,
        timesPerWeek: 8,
      ),
    ];
    for (final draft in bad) {
      expect(
        await failureOf(draft),
        isA<ValidationFailure>(),
        reason: '$draft',
      );
    }
    expect((await repository.getHabits()).dataOrNull, isEmpty);
  });

  test('a name already used (any case) is refused', () async {
    await port.createHabit(const HabitDraft(name: 'Read'));

    expect(
      await failureOf(const HabitDraft(name: ' read ')),
      isA<ValidationFailure>(),
    );
  });
}
