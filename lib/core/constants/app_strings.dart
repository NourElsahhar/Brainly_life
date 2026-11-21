// AppStrings = every text the user can see, in ONE place.
// Never write user-facing text inside a screen. Add it here instead, in the
// section of your feature, so translation can be added later.
//
// Usage:
//   Text(AppStrings.habitsTitle)
//   Text(AppStrings.habitsProgress(2, 5))
//
// Each owner edits only their own section. Add a new section for your feature
// if it is not here yet.

class AppStrings {
  const AppStrings._();

  // ===== Common (M1) =====

  // ===== Auth (M1) =====

  // ===== Home (M3) =====

  // ===== Tasks (M3) =====

  // ===== Study planner (M2) =====

  // ===== Habits (M4) =====
  static const String habitsTitle = 'Habits';
  static const String habitsEmptyTitle = 'Add your first habit';
  static const String habitsEmptyMessage =
      'Small daily habits add up. Start with one.';
  static const String habitsAddAction = 'Add habit';
  static const String habitsNothingDueTitle = 'Nothing due today';
  static const String habitsNothingDueMessage = 'Enjoy your day off.';
  static const String habitNewTitle = 'New habit';
  static const String habitEditTitle = 'Edit habit';
  static const String habitNameLabel = 'Name';
  static const String habitSaveAction = 'Save';
  static const String habitArchiveAction = 'Archive';
  static const String habitDeleteAction = 'Delete';
  static const String habitArchiveConfirmTitle = 'Archive habit?';
  static const String habitArchiveConfirmMessage =
      'It will stop showing in your daily list. Your history is kept.';
  static const String habitDeleteConfirmTitle = 'Delete habit?';
  static const String habitDeleteConfirmMessage =
      'The habit and its history will be removed. This cannot be undone.';

  // Form validation messages.
  static const String habitNameTaken =
      'You already have an active habit with this name.';
  static const String habitWeekdaysRequired = 'Choose at least one day.';
  static const String habitTimesPerWeekRange = 'Choose a number from 1 to 7.';

  static String habitsProgress(int done, int total) => '$done of $total done';

  static String habitStreakDays(int days) => days == 1 ? '1 day' : '$days days';

  // ===== Focus (M4) =====
  static const String focusTitle = 'Focus';
  static const String focusModeFocus = 'Focus';
  static const String focusModeShortBreak = 'Short break';
  static const String focusModeLongBreak = 'Long break';
  static const String focusStartAction = 'Start';
  static const String focusPauseAction = 'Pause';
  static const String focusResumeAction = 'Resume';
  static const String focusStopAction = 'Stop';
  static const String focusSkipBreakAction = 'Skip break';

  // ===== Analytics and AI (M5) =====
}
