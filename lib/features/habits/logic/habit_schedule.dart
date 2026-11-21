// HabitSchedule answers one question: is this habit due on this day?
// Daily and times-per-week habits are due every day after their start date.
// Weekday habits are due only on their chosen weekdays.

import 'package:brainly_life/core/utils/utils.dart';
import 'package:brainly_life/features/habits/data/models/habit_model.dart';

class HabitSchedule {
  const HabitSchedule._();

  static bool isDueOn(Habit habit, String dateKey) {
    if (habit.archived) return false;
    if (habit.startDate.compareTo(dateKey) > 0) return false;
    return switch (habit.frequencyType) {
      HabitFrequencyType.daily || HabitFrequencyType.timesPerWeek => true,
      HabitFrequencyType.weekdays => habit.weekdays.contains(
        DateKeyUtils.parse(dateKey).weekday,
      ),
    };
  }
}
