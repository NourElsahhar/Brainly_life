import 'package:brainly_life/features/habits/data/models/habit_log_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final log = HabitLog(
    habitId: 'h1',
    date: '2026-11-14',
    completedAt: DateTime.utc(2026, 11, 14, 18),
  );

  test('id is habitId_dateKey', () {
    expect(log.id, 'h1_2026-11-14');
  });

  test('toFirestore then fromMap gives the same log', () {
    expect(HabitLog.fromMap(log.toFirestore()), log);
  });
}
