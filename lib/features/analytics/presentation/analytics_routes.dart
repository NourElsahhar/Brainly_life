import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../injection.dart';
import '../analytics_injection.dart';
import '../logic/analytics_cubit.dart';
import 'screens/analytics_screen.dart';

final List<RouteBase> analyticsRoutes = [
  GoRoute(path: 'analytics', builder: (_, _) => const _AnalyticsEntry()),
];

class _AnalyticsEntry extends StatefulWidget {
  const _AnalyticsEntry();
  @override
  State<_AnalyticsEntry> createState() => _AnalyticsEntryState();
}

class _AnalyticsEntryState extends State<_AnalyticsEntry> {
  late Future<AnalyticsCubit> _future = getIt<AnalyticsFactory>().create();
  @override
  Widget build(BuildContext context) => FutureBuilder<AnalyticsCubit>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Scaffold(
          appBar: AppBar(title: const Text('Weekly analytics')),
          body: Center(
            child: TextButton(
              onPressed: () =>
                  setState(() => _future = getIt<AnalyticsFactory>().create()),
              child: const Text('Unable to load your account. Retry'),
            ),
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return BlocProvider(
        create: (_) => snapshot.data!..load(),
        child: const AnalyticsScreen(),
      );
    },
  );
}

GoRoute analyticsRoute({
  required AnalyticsCubit Function() createCubit,
  String path = '/analytics',
}) => GoRoute(
  path: path,
  builder: (context, state) => BlocProvider(
    create: (_) => createCubit()..load(),
    child: const AnalyticsScreen(),
  ),
);
