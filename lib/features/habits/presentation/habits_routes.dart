// Routes of the habits feature (owner: M4).
// app_router.dart combines the route lists of all features.
//   habitsRoutes           -> the Habits tab (inside the bottom bar)
//   habitsFullScreenRoutes -> new / detail / edit (full screen, no bottom bar)
// The form and the detail screens come in the next steps. Until then they
// show a placeholder.

import 'package:brainly_life/core/routes/app_routes.dart';
import 'package:brainly_life/core/routes/placeholder_screen.dart';
import 'package:brainly_life/features/habits/presentation/screens/habits_screen.dart';
import 'package:go_router/go_router.dart';

final List<RouteBase> habitsRoutes = [
  GoRoute(
    path: AppRoutes.habits,
    builder: (context, state) => const HabitsScreen(),
  ),
];

final List<RouteBase> habitsFullScreenRoutes = [
  // /habits/new must come before /habits/:id.
  GoRoute(
    path: AppRoutes.newHabit,
    builder: (context, state) => const PlaceholderScreen(title: 'New habit'),
  ),
  GoRoute(
    path: AppRoutes.habitDetail,
    builder: (context, state) => const PlaceholderScreen(title: 'Habit'),
  ),
  GoRoute(
    path: AppRoutes.editHabit,
    builder: (context, state) => const PlaceholderScreen(title: 'Edit habit'),
  ),
];
