import 'package:brainly_life/core/widgets/widgets.dart' show PriorityLevel;
import 'package:brainly_life/features/tasks/data/models/task_model.dart';
import 'package:brainly_life/features/tasks/presentation/task_display.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  // Local times, like the user sees them.
  final now = DateTime(2026, 11, 15, 13);
  String time(DateTime d) => DateFormat.jm().format(d);

  group('formatDue', () {
    test('today, tomorrow and yesterday', () {
      final today = DateTime(2026, 11, 15, 17);
      final tomorrow = DateTime(2026, 11, 16, 9);
      final yesterday = DateTime(2026, 11, 14, 20);

      expect(formatDue(today, now), 'Today ${time(today)}');
      expect(formatDue(tomorrow, now), 'Tomorrow ${time(tomorrow)}');
      expect(formatDue(yesterday, now), 'Yesterday ${time(yesterday)}');
    });

    test('other days show the date', () {
      final later = DateTime(2026, 11, 21, 17);

      expect(formatDue(later, now), 'Sat, 21 Nov · ${time(later)}');
    });

    test('a UTC deadline is shown in local time', () {
      final local = DateTime(2026, 11, 15, 23, 30);

      expect(formatDue(local.toUtc(), now), 'Today ${time(local)}');
    });
  });

  test('formatCompleted', () {
    final done = DateTime(2026, 11, 15, 9, 40);

    expect(formatCompleted(done, now), 'Completed today ${time(done)}');
  });

  test('priority maps to the UI level', () {
    expect(TaskPriority.low.level, PriorityLevel.low);
    expect(TaskPriority.medium.level, PriorityLevel.medium);
    expect(TaskPriority.high.level, PriorityLevel.high);
  });
}
