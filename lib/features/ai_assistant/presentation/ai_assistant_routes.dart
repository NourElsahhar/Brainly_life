import 'package:flutter/material.dart';

import '../ai_assistant_injection.dart';
import '../../auth/data/models/user_settings_model.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/app_routes.dart';
import '../../../injection.dart';
import '../data/models/chat_message.dart';
import '../logic/ai_action_handler.dart';
import '../logic/chat_cubit.dart';
import '../../analytics/presentation/analytics_routes.dart';
import 'screens/chat_screen.dart';

final List<RouteBase> aiAssistantRoutes = [
  GoRoute(
    path: AppRoutes.assistant,
    builder: (context, state) => const _AssistantEntry(),
    routes: analyticsRoutes,
  ),
];

GoRoute aiAssistantRoute({
  required ChatCubit Function() createCubit,
  required AiActionHandler actions,
  required void Function(BuildContext, AiActionType) openAction,
  String path = '/assistant',
}) => GoRoute(
  path: path,
  builder: (context, state) => BlocProvider(
    create: (_) => createCubit()..load(),
    child: ChatScreen(actions: actions, openAction: openAction),
  ),
);

class _AssistantEntry extends StatefulWidget {
  const _AssistantEntry();
  @override
  State<_AssistantEntry> createState() => _AssistantEntryState();
}

class _AssistantEntryState extends State<_AssistantEntry>
    with WidgetsBindingObserver {
  late Future<UserSettings> _settings = getIt<AiAccount>().settings();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() => _settings = getIt<AiAccount>().settings());
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<UserSettings>(
    future: _settings,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Scaffold(
          appBar: AppBar(title: const Text('Baseet AI')),
          body: Center(
            child: AppButton(
              label: 'Unable to load your account. Retry',
              expanded: false,
              onPressed: () =>
                  setState(() => _settings = getIt<AiAccount>().settings()),
            ),
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (!snapshot.data!.aiEnabled) {
        return Scaffold(
          appBar: AppBar(title: const Text('Baseet AI')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.screenMargin),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: context.palette.primarySoft,
                    child: Icon(
                      Icons.auto_awesome,
                      size: 60,
                      color: context.palette.iconMuted,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'AI features are off',
                    style: context.text.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Turn on AI in Settings to chat, get tips and generate study plans.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'Open settings',
                    onPressed: () => context.go(AppRoutes.settings),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      return BlocProvider(
        create: (_) => getIt<ChatCubit>()..load(),
        child: ChatScreen(
          actions: getIt<AiActionHandler>(),
          openAction: (context, type) {
            if (type == AiActionType.startFocus) context.push(AppRoutes.focus);
            if (type == AiActionType.openPlan) context.go(AppRoutes.plan);
          },
        ),
      );
    },
  );
}
