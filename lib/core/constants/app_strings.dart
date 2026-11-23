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
    static const String onboardingSkip = 'Skip';
  static const String onboardingNext = 'Next';
  static const String onboardingGetStarted = 'Get started';
  static const String onboardingHaveAccount = 'I already have an account';
  static const String onboardingTitle1 = 'Plan your studies with AI';
  static const String onboardingSubtitle1 =
      'Tell us your subjects and exam dates. Baseet builds your study plan for you.';
  static const String onboardingTitle2 = 'Build habits, stay focused';
  static const String onboardingSubtitle2 =
      'Track daily habits and use the focus timer to get more done.';
  static const String onboardingTitle3 = 'See your week clearly';
  static const String onboardingSubtitle3 =
      'Weekly reports show your progress and give you tips to improve.';

  // ===== Home (M3) =====

  // ===== Tasks (M3) =====

  // ===== Study planner (M2) =====

  // ===== Habits (M4) =====
  static const String habitsTitle = 'Habits';
  static const String habitsEmptyTitle = 'Start your first habit';
  static const String habitsEmptyMessage =
      'Small daily habits add up. Pick one to begin.';
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

    static const String habitsEmptyCta = 'New habit';
  static const String habitsDoneToday = 'done today';
  static const String habitsAllDone = 'All done for today!';
  static const String habitsFocusTooltip = 'Focus timer';
  static const String habitsAddTooltip = 'Add habit';
  static const String habitMarkDone = 'Mark as done';
  static const String habitMarkUndone = 'Mark as not done';
  static const String habitTemplateRead = 'Read 10 pages';
  static const String habitTemplateWater = 'Drink water';
  static const String habitTemplateWalk = 'Walk 15 min';

  static String habitsKeepGoing(String? name) =>
      name == null ? 'Keep going!' : 'Keep going, $name!';

  static String habitStreakLabel(int days) => '$days-day streak';

  static const String habitsAiTitle = 'AI suggestions';
  static const String habitsAiGet = 'Get suggestions';
  static const String habitsAiAdd = 'Add';
  static const String habitsAiDismiss = 'Dismiss';
  static const String habitsAiRetry = 'Try again';
  static const String habitsAiUnavailable =
      'Suggestions are unavailable right now.';
  static const String habitsAiEmpty = 'No new suggestions for now.';
  static const String habitsAiDisclaimer = 'AI can make mistakes.';

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
  static const String focusSettingsTitle = 'Focus settings';
  static const String focusSettingsTimerSection = 'Timer';
  static const String focusSettingsBehaviourSection = 'Behaviour';
  static const String focusLabelFocus = 'Focus';
  static const String focusLabelShortBreak = 'Short break';
  static const String focusLabelLongBreak = 'Long break';
  static const String focusLabelSessionsBeforeLong = 'Sessions before long break';
  static const String focusAutoStart = 'Auto-start next session';
  static const String focusSound = 'Sound';
  static const String focusVibration = 'Vibration';
  static const String focusKeepScreenOn = 'Keep screen on';
  static const String focusResetDefaults = 'Reset to defaults';
  static const String focusDecrease = 'Decrease';
  static const String focusIncrease = 'Increase';

  static String focusMinutesValue(int minutes) => '$minutes min';
  static const String focusStatsTooltip = 'Statistics';
  static const String focusSettingsTooltip = 'Settings';
  static const String focusLinkedTask = 'Linked to a task';
  static const String focusLinkedStudySession = 'Linked to a study session';
  static const String focusFocusDone = 'Focus block finished';
  static const String focusBreakDone = 'Break is over';
  static const String focusStartShortBreak = 'Start short break';
  static const String focusStartLongBreak = 'Start long break';

  static String focusCycleLabel(int done, int total) =>
      '$done of $total focus blocks done';

  static const String focusStatsTitle = 'Focus stats';
  static const String focusStatsToday = 'Today';
  static const String focusStatsYesterday = 'Yesterday';
  static const String focusStatsThisWeek = 'This week';
  static const String focusStatsStreak = 'Focus-day streak';
  static const String focusStatsLast7Days = 'Last 7 days';
  static const String focusStatsBestTime = 'Best time of day';
  static const String focusStatsTotalSessions = 'Total sessions';
  static const String focusStatsHistory = 'History';
  static const String focusStatsEmptyTitle = 'No focus sessions yet';
  static const String focusStatsEmptyMessage =
      'Start a session to see your stats here.';
  static const String focusStatsStartFocus = 'Start focus';
  static const String focusDayPartMorning = 'Morning (5 AM–12 PM)';
  static const String focusDayPartAfternoon = 'Afternoon (12–6 PM)';
  static const String focusDayPartEvening = 'Evening (6–9 PM)';
  static const String focusDayPartNight = 'Night (9 PM–5 AM)';

  static String focusHoursValue(String hours) => '$hours h';

  static String focusHistoryItem(String day, String time, int minutes) =>
      '$day $time · $minutes min';
  // ===== Analytics and AI (M5) =====
}
