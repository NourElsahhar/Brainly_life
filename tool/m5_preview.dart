import 'package:brainly_life/core/ai/ai.dart';
import 'package:brainly_life/core/constants/app_strings.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/features/ai_assistant/data/repositories/daily_ai_tip_provider.dart';
import 'package:brainly_life/features/ai_assistant/data/repositories/mock_chat_repository.dart';
import 'package:brainly_life/features/ai_assistant/logic/ai_action_handler.dart';
import 'package:brainly_life/features/ai_assistant/logic/chat_cubit.dart';
import 'package:brainly_life/features/ai_assistant/presentation/ai_assistant_routes.dart';
import 'package:brainly_life/features/ai_assistant/presentation/widgets/daily_ai_tip_card.dart';
import 'package:brainly_life/features/analytics/data/repositories/mock_analytics_repository.dart';
import 'package:brainly_life/features/analytics/data/repositories/mock_weekly_insight_client.dart';
import 'package:brainly_life/features/analytics/logic/analytics_cubit.dart';
import 'package:brainly_life/features/analytics/logic/iana_analytics_calendar.dart';
import 'package:brainly_life/features/analytics/presentation/analytics_routes.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/data/latest.dart' as tzdata;

void main() => runApp(M5Preview());

class M5Preview extends StatefulWidget {
  const M5Preview({
    super.key,
    this.clock = const Clock(),
    this.aiClient,
    this.onTaskCreated,
  });

  final Clock clock;
  final AiClient? aiClient;
  final void Function(String)? onTaskCreated;

  @override
  State<M5Preview> createState() => _M5PreviewState();
}

class _M5PreviewState extends State<M5Preview> {
  final _chat = MockChatRepository();
  final _analytics = MockAnalyticsRepository();
  final _actions = <String>[];
  late final _client = widget.aiClient ?? MockAiClient();
  late final _calendar = ianaAnalyticsCalendar(
    timezone: 'Africa/Cairo',
    weekStartDay: DateTime.monday,
  );
  late final _tip = const MockAiTipProvider().dailyTip();

  late final _router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => _home(context)),
      aiAssistantRoute(
        createCubit: () => ChatCubit(
          repository: _chat,
          client: _client,
          now: widget.clock.now,
        ),
        actions: AiActionHandler(
          createTask: _createTask,
          createHabit: _createDraft,
        ),
        openAction: (context, action) => ScaffoldMessenger.of(context)
            .showSnackBar(
              const SnackBar(content: Text(AppStrings.actionUnavailable)),
            ),
      ),
      analyticsRoute(
        createCubit: () => AnalyticsCubit(
          repository: _analytics,
          calendar: _calendar,
          ai: MockWeeklyInsightClient(repository: _analytics, client: _client),
          now: widget.clock.now,
        ),
      ),
    ],
  );

  @override
  void initState() {
    super.initState();
    tzdata.initializeTimeZones();
  }

  Future<Result<String>> _createTask(String title) async {
    widget.onTaskCreated?.call(title);
    return _createDraft(title);
  }

  Future<Result<String>> _createDraft(String title) async {
    setState(() => _actions.add(title));
    return Result.success(_actions.length.toString());
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Brainly Life',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    routerConfig: _router,
  );

  Widget _home(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Brainly Life')),
    body: ListView(
      padding: const EdgeInsets.all(AppSpacing.screenMargin),
      children: [
        DailyAiTipCard(tip: _tip),
        ListTile(
          leading: const Icon(Icons.auto_awesome_outlined),
          title: const Text(AppStrings.brainlyAi),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/assistant'),
        ),
        ListTile(
          leading: const Icon(Icons.insights_outlined),
          title: const Text(AppStrings.analytics),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/analytics'),
        ),
        for (final action in _actions)
          ListTile(leading: const Icon(Icons.check), title: Text(action)),
      ],
    ),
  );
}
