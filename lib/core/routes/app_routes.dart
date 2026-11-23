// AppRoutes = every screen path of the app, in ONE place.
// Never write a path like '/tasks' as text inside a screen. Use these.
//
// Usage:
//   context.go(AppRoutes.home);                      // "take me there" (tabs, after login)
//   context.push(AppRoutes.taskPath('abc123'));      // opens on top, back button works
//   context.push(AppRoutes.focusPath(taskId: 'abc123'));
//
// These paths are a first version and may change. Change them HERE only.

class AppRoutes {
  const AppRoutes._();

  // Before sign in (no bottom bar)
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Open to everyone, signed in or not (full screen).
  static const String terms = '/terms';
  static const String privacy = '/privacy';

  // The tabs of the bottom bar
  static const String home = '/home';
  static const String plan = '/plan'; // study planner
  static const String assistant = '/assistant'; // Brainly AI
  static const String habits = '/habits';
  static const String profile = '/profile';

  // Full screen (open on top of the bottom bar)
  // Settings is opened with context.push from any tab, so the back arrow
  // returns to the tab the user came from.
  static const String settings = '/settings';
  static const String tasks = '/tasks';
  static const String newTask = '/tasks/new';
  static const String taskCategories = '/tasks/categories';
  static const String taskDetail = '/tasks/:id';
  static const String editTask = '/tasks/:id/edit';
  static const String focus = '/focus'; // ?taskId=&studySessionId=
  static const String focusSettings = '/focus/settings';
  static const String focusStats = '/focus/stats';
  static const String newHabit = '/habits/new';
  static const String habitDetail = '/habits/:id';
  static const String editHabit = '/habits/:id/edit';
  static String taskPath(String id) => '/tasks/$id';
  static String editTaskPath(String id) => '/tasks/$id/edit';
  static String focusPath({String? taskId, String? studySessionId}) {
    // The ? means "add this only when it is not null".
    final query = <String, String>{
      'taskId': ?taskId,
      'studySessionId': ?studySessionId,
    };
    return Uri(
      path: focus,
      queryParameters: query.isEmpty ? null : query,
    ).toString();
  }
  static String habitPath(String id) => '/habits/$id';
  static String editHabitPath(String id) => '/habits/$id/edit';
}
