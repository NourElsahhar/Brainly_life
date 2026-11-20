import 'package:brainly_life/features/habits/data/models/habit_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final habit = Habit(
    id: 'h1',
    name: 'Read',
    icon: 'book',
    colorValue: 0xFF2196F3,
    frequencyType: HabitFrequencyType.weekdays,
    weekdays: const [1, 3, 5],
    startDate: '2026-11-01',
    currentStreak: 2,
    bestStreak: 5,
    lastCompletedDate: '2026-11-14',
    createdAt: DateTime.utc(2026, 11, 1),
    updatedAt: DateTime.utc(2026, 11, 14),
  );

  test('toFirestore then fromMap gives the same habit', () {
    expect(Habit.fromMap('h1', habit.toFirestore()), habit);
  });

  test('copyWith changes only the given fields', () {
    final copy = habit.copyWith(name: 'Write');
    expect(copy.name, 'Write');
    expect(copy.icon, habit.icon);
  });

  test('defaults are daily, not archived, zero streaks', () {
    final simple = Habit(
      id: 'h2',
      name: 'Water',
      icon: 'water',
      colorValue: 0xFF000000,
      startDate: '2026-11-01',
      createdAt: DateTime.utc(2026, 11, 1),
      updatedAt: DateTime.utc(2026, 11, 1),
    );
    expect(simple.frequencyType, HabitFrequencyType.daily);
    expect(simple.archived, isFalse);
    expect(simple.currentStreak, 0);
    expect(simple.bestStreak, 0);
  });
}
