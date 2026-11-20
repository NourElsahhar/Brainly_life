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

  // The tabs of the bottom bar
  static const String home = '/home';
  static const String plan = '/plan'; // study planner
  static const String assistant = '/assistant'; // Brainly AI
  static const String habits = '/habits';
  static const String profile = '/profile';
  static const String settings = '/profile/settings';

  // Full screen (open on top of the bottom bar)
    static const String tasks = '/tasks';
  static const String newTask = '/tasks/new';
  static const String taskCategories = '/tasks/categories';
  static const String taskDetail = '/tasks/:id';
  static const String editTask = '/tasks/:id/edit';
  static const String focus = '/focus'; // ?taskId=&studySessionId=

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
}
