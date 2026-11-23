// PlaceholderScreen = a temporary screen that only shows its name.
// Every feature uses it in its *_routes.dart until the real screen exists.
// When your screen is ready, replace the PlaceholderScreen with it.

import 'package:brainly_life/core/widgets/widgets.dart';
import 'package:flutter/material.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title, this.message});

  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: EmptyView(
        icon: Icons.construction_rounded,
        title: title,
        message: message ?? 'This screen is not built yet.',
      ),
    );
  }
}
