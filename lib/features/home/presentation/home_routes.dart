// Routes of the home feature (owner: M3).
// app_router.dart combines the route lists of all features.

import 'package:brainly_life/core/routes/app_routes.dart';
import 'package:brainly_life/features/home/presentation/screens/home_screen.dart';
import 'package:go_router/go_router.dart';

final List<RouteBase> homeRoutes = [
  GoRoute(
    path: AppRoutes.home,
    builder: (context, state) => const HomeScreen(),
  ),
];
