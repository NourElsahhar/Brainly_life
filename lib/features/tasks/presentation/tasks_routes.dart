// Routes of the tasks feature (owner: M3).
// app_router.dart combines the route lists of all features.
// Replace each PlaceholderScreen with the real screen when it is ready.

import 'package:brainly_life/core/routes/app_routes.dart';
import 'package:brainly_life/core/routes/placeholder_screen.dart';
import 'package:go_router/go_router.dart';

final List<RouteBase> tasksRoutes = [
  GoRoute(
    path: AppRoutes.tasks,
    builder: (context, state) => const PlaceholderScreen(title: 'Tasks'),
  ),
  GoRoute(
    path: AppRoutes.taskDetail,
    builder: (context, state) => PlaceholderScreen(
      title: 'Task ${state.pathParameters['id']}',
    ),
  ),
];
