// The root widget of the app: MaterialApp.router with our light and dark
// themes. The router comes from get_it (see injection.dart).

import 'package:brainly_life/core/theme/app_theme.dart';
import 'package:brainly_life/injection.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BrainlyLifeApp extends StatelessWidget {
  const BrainlyLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Brainly Life',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: getIt<GoRouter>(),
    );
  }
}