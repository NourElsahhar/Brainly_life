// Routes of the focus feature (owner: M4).
// app_router.dart combines the route lists of all features.
// /focus opens the Pomodoro screen, with optional ?taskId= and
// ?studySessionId= (the timer is linked to that task or study session).

import 'package:brainly_life/core/routes/app_routes.dart';
import 'package:brainly_life/core/routes/placeholder_screen.dart';
import 'package:brainly_life/features/focus/presentation/screens/focus_screen.dart';
import 'package:brainly_life/features/focus/presentation/screens/focus_settings_screen.dart';
import 'package:go_router/go_router.dart';

final List<RouteBase> focusRoutes = [
  GoRoute(
    path: AppRoutes.focus,
    builder: (context, state) => FocusScreen(
      taskId: state.uri.queryParameters['taskId'],
      studySessionId: state.uri.queryParameters['studySessionId'],
    ),
    routes: [
      // Full path: /focus/settings (AppRoutes.focusSettings).
      GoRoute(
        path: 'settings',
        builder: (context, state) => const FocusSettingsScreen(),
      ),
      // Full path: /focus/stats (AppRoutes.focusStats). The real screen
      // comes in the next step.
      GoRoute(
        path: 'stats',
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Focus stats'),
      ),
    ],
  ),
];
