import 'package:brainly_life/core/widgets/widgets.dart' show PriorityLevel;
import 'package:brainly_life/features/tasks/data/models/task_model.dart';
import 'package:intl/intl.dart';

/// Turns the task priority into M1's UI level for [PriorityChip].
extension TaskPriorityLevel on TaskPriority {
  PriorityLevel get level => switch (this) {
    TaskPriority.low => PriorityLevel.low,
    TaskPriority.medium => PriorityLevel.medium,
    TaskPriority.high => PriorityLevel.high,
  };
}

/// "Today 3:00 PM", "Tomorrow 9:00 AM", "Yesterday 8:00 PM",
/// or "Sat, 21 Nov · 5:00 PM", in the user's time zone.
String formatDue(DateTime dueAt, DateTime now) {
  final due = dueAt.toLocal();
  return '${_dayLabel(due, now.toLocal())} ${DateFormat.jm().format(due)}';
}

/// "Completed today 3:40 PM", "Completed Sat, 14 Nov · 9:00 AM"...
String formatCompleted(DateTime completedAt, DateTime now) {
  final done = completedAt.toLocal();
  final day = _dayLabel(done, now.toLocal());
  final label = day == 'Today' || day == 'Yesterday' ? day.toLowerCase() : day;
  return 'Completed $label ${DateFormat.jm().format(done)}';
}

String _dayLabel(DateTime date, DateTime today) {
  // Compare calendar days only (UTC avoids daylight saving surprises).
  final days = DateTime.utc(
    date.year,
    date.month,
    date.day,
  ).difference(DateTime.utc(today.year, today.month, today.day)).inDays;
  return switch (days) {
    0 => 'Today',
    1 => 'Tomorrow',
    -1 => 'Yesterday',
    _ => '${DateFormat('EEE, d MMM').format(date)} ·',
  };
}
