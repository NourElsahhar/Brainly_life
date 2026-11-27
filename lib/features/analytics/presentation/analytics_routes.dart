import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/routes/app_routes.dart';
import '../../../injection.dart';
import '../logic/analytics_state.dart';
import '../analytics_injection.dart';
import '../logic/analytics_cubit.dart';
import 'screens/analytics_screen.dart';

final List<RouteBase> analyticsRoutes = [
  GoRoute(path: 'analytics', builder: (_, _) => const _AnalyticsEntry()),
];

/// The same screens on top of the bottom bar, opened from Profile:
///   /analytics         -> this week's analytics
///   /analytics/report  -> the AI report of LAST week (the last finished one)
final List<RouteBase> analyticsFullScreenRoutes = [
  GoRoute(
    path: AppRoutes.weeklyAnalytics,
    builder: (_, _) => const _AnalyticsEntry(),
    routes: [
      GoRoute(
        path: 'report',
        builder: (_, _) => const _AnalyticsEntry(lastWeekReport: true),
      ),
    ],
  ),
];

class _AnalyticsEntry extends StatefulWidget {
  const _AnalyticsEntry({this.lastWeekReport = false});

  /// Opens the AI report of last week instead of the analytics.
  final bool lastWeekReport;

  @override
  State<_AnalyticsEntry> createState() => _AnalyticsEntryState();
}

class _AnalyticsEntryState extends State<_AnalyticsEntry> {
  late Future<AnalyticsCubit> _future = _create();

  Future<AnalyticsCubit> _create() async {
    final cubit = await getIt<AnalyticsFactory>().create();
    // The report is only for a finished week: start on last week.
    if (widget.lastWeekReport) await cubit.move(-1);
    return cubit;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<AnalyticsCubit>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Scaffold(
          appBar: AppBar(title: const Text('Weekly analytics')),
          body: Center(
            child: TextButton(
              onPressed: () => setState(() => _future = _create()),
              child: const Text('Unable to load your account. Retry'),
            ),
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (widget.lastWeekReport) {
        return BlocProvider(
          create: (_) => snapshot.data!, // already loaded by move(-1)
          child: BlocBuilder<AnalyticsCubit, AnalyticsState>(
            builder: (context, state) => state is AnalyticsLoaded
                ? const WeeklyReportScreen()
                : Scaffold(
                    appBar: AppBar(title: const Text(AppStrings.weeklyReport)),
                    body: const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          AppStrings.noAnalytics,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
          ),
        );
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
