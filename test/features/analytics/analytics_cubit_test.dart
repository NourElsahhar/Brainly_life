import 'package:brainly_life/core/ai/ai.dart';
import 'package:brainly_life/features/analytics/data/repositories/mock_analytics_repository.dart';
import 'package:brainly_life/features/analytics/data/repositories/mock_weekly_insight_client.dart';
import 'package:brainly_life/features/analytics/logic/analytics_cubit.dart';
import 'package:brainly_life/features/analytics/logic/analytics_state.dart';
import 'package:brainly_life/features/analytics/logic/iana_analytics_calendar.dart';
import 'package:brainly_life/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;

AnalyticsCubit createCubit(
  MockAnalyticsRepository repository,
  AiClient client,
) => AnalyticsCubit(
  repository: repository,
  calendar: ianaAnalyticsCalendar(
    timezone: 'UTC',
    weekStartDay: DateTime.monday,
  ),
  ai: MockWeeklyInsightClient(repository: repository, client: client),
  now: () => DateTime.utc(2026, 11, 15),
);

void main() {
  setUpAll(tz.initializeTimeZones);

  test(
    'Refuses future weeks and persists a report only for finished weeks',
    () async {
      final repo = MockAnalyticsRepository();
      final cubit = createCubit(repo, MockAiClient(delay: Duration.zero));
      addTearDown(cubit.close);
      await cubit.load();
      final current = cubit.state as AnalyticsLoaded;
      await cubit.move(1);
      expect((cubit.state as AnalyticsLoaded).week.key, current.week.key);
      await cubit.generateReport();
      expect(repo.reports, isEmpty);
      await cubit.move(-1);
      await cubit.generateReport();
      final report = (cubit.state as AnalyticsLoaded).report!;
      expect(report.recommendations, hasLength(3));
      await cubit.load();
      expect((cubit.state as AnalyticsLoaded).report?.summary, report.summary);
      expect(repo.reports, hasLength(1));
    },
  );

  test('An AI failure keeps numeric analytics visible', () async {
    final repo = MockAnalyticsRepository();
    final cubit = createCubit(
      repo,
      MockAiClient(delay: Duration.zero, error: AiErrorCode.disabled),
    );
    addTearDown(cubit.close);
    await cubit.load();
    await cubit.move(-1);
    await cubit.generateReport();
    final state = cubit.state as AnalyticsLoaded;
    expect(state.score, isNotNull);
    expect(state.reportFailure?.code, 'ai_disabled');
    expect(state.report, isNull);
  });

  testWidgets('Shows the empty analytics state', (tester) async {
    final cubit = createCubit(
      MockAnalyticsRepository(empty: true),
      MockAiClient(),
    );
    addTearDown(cubit.close);
    await cubit.load();
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: cubit, child: const AnalyticsScreen()),
      ),
    );
    expect(find.text('Not enough data yet'), findsOneWidget);
    expect(find.byTooltip('Previous week'), findsOneWidget);
  });
}
