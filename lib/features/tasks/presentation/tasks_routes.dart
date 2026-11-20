// Routes of the tasks feature (owner: M3).
// app_router.dart combines the route lists of all features.
// Replace each PlaceholderScreen with the real screen when it is ready.

import 'package:brainly_life/core/routes/app_routes.dart';
import 'package:brainly_life/core/routes/placeholder_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:brainly_life/features/tasks/presentation/screens/tasks_screen.dart';
import 'package:brainly_life/features/tasks/presentation/screens/task_form_screen.dart';

// Order matters: '/tasks/new' and '/tasks/categories' must come before
// '/tasks/:id', or "new" would be read as a task id.
final List<RouteBase> tasksRoutes = [
  GoRoute(
    path: AppRoutes.tasks,
    builder: (context, state) => const TasksScreen(),
  ),
  GoRoute(
    path: AppRoutes.newTask,
    builder: (context, state) => const TaskFormScreen(),
  ),
  GoRoute(
    path: AppRoutes.taskCategories,
    builder: (context, state) => const PlaceholderScreen(title: 'Categories'),
  ),
  GoRoute(
    path: AppRoutes.taskDetail,
    builder: (context, state) =>
        PlaceholderScreen(title: 'Task ${state.pathParameters['id']}'),
  ),
  GoRoute(
    path: AppRoutes.editTask,
    builder: (context, state) =>
        TaskFormScreen(taskId: state.pathParameters['id']),
  ),
];
