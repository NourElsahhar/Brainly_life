// Routes of the habits feature (owner: M4).
// app_router.dart combines the route lists of all features.
//   habitsRoutes           -> the Habits tab (inside the bottom bar)
//   habitsFullScreenRoutes -> new / detail / edit (full screen, no bottom bar)
// The new habit form can receive a HabitTemplate in `extra`. The edit form
// receives the Habit to edit in `extra` (the detail screen passes it). The
// detail screen comes in the next step and shows a placeholder until then.

import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/routes/app_routes.dart';
import 'package:brainly_life/core/routes/placeholder_screen.dart';
import 'package:brainly_life/core/widgets/widgets.dart';
import 'package:brainly_life/features/habits/data/models/habit_model.dart';
import 'package:brainly_life/features/habits/logic/habit_templates.dart';
import 'package:brainly_life/features/habits/presentation/screens/habit_form_screen.dart';
import 'package:brainly_life/features/habits/presentation/screens/habits_screen.dart';
import 'package:flutter/material.dart';
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
    builder: (context, state) {
      final extra = state.extra;
      return HabitFormScreen(template: extra is HabitTemplate ? extra : null);
    },
  ),
  GoRoute(
    path: AppRoutes.habitDetail,
    builder: (context, state) => const PlaceholderScreen(title: 'Habit'),
  ),
  GoRoute(
    path: AppRoutes.editHabit,
    builder: (context, state) {
      final extra = state.extra;
      if (extra is Habit) return HabitFormScreen(habit: extra);
      // Opened without a habit (for example after the app restarted).
      return Scaffold(
        appBar: AppBar(),
        body: const ErrorView(failure: NotFoundFailure()),
      );
    },
  ),
];
