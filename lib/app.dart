// The root widget of the app: MaterialApp with our light and dark themes.
// TEMPORARY: `home` is a placeholder. It will become MaterialApp.router
// when the go_router setup is added.

import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';

class BrainlyLifeApp extends StatelessWidget {
  const BrainlyLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Brainly Life',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const Scaffold(
        body: Center(child: Text('Brainly Life')),
      ),
    );
  }
}