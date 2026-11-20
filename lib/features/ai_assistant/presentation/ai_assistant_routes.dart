// Routes of the ai_assistant feature (owner: M5).
// app_router.dart combines the route lists of all features.
// Replace each PlaceholderScreen with the real screen when it is ready.

import 'package:brainly_life/core/routes/app_routes.dart';
import 'package:brainly_life/core/routes/placeholder_screen.dart';
import 'package:go_router/go_router.dart';

final List<RouteBase> aiAssistantRoutes = [
  GoRoute(
    path: AppRoutes.assistant,
    builder: (context, state) => const PlaceholderScreen(title: 'Brainly AI'),
  ),
];
