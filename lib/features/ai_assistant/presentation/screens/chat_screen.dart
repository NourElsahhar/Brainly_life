import 'package:flutter/material.dart';
import 'package:brainly_life/core/routes/app_routes.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/widgets.dart';

import '../../../../core/ai/ai_widgets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/theme.dart';
import '../../data/models/chat_message.dart';
import '../../logic/ai_action_handler.dart';
import '../../logic/chat_cubit.dart';
import '../../logic/chat_state.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.actions,
    required this.openAction,
  });

  final AiActionHandler actions;
  final void Function(BuildContext, AiActionType) openAction;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _completed = <(String, int)>{};
  bool _handlingAction = false;
  String? _validation;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _submit([String? prompt]) {
    final text = (prompt ?? _input.text).trim();
    if (text.isEmpty || text.runes.length > ChatCubit.maxMessageLength) {
      setState(() => _validation = AppStrings.messageLength);
      return;
    }
    _input.clear();
    setState(() => _validation = null);
    context.read<ChatCubit>().send(text);
  }

  Future<bool> _confirm(String title, String message) =>
      ConfirmDialog.show(context, title: title, message: message);

  Future<void> _runAction(ChatMessage message, int index) async {
    final action = message.actions[index];
    if (_handlingAction || _completed.contains((message.id, index))) return;
    setState(() => _handlingAction = true);
    try {
      final confirmed = await _confirm(
        _label(action.type),
        action.title ?? _label(action.type),
      );
      if (!mounted || !confirmed) return;
      final result = await widget.actions.execute(action, confirmed: true);
      if (!mounted) return;
      result.fold(
        onSuccess: (type) {
          if (type == null) return;
          if (type == AiActionType.startFocus ||
              type == AiActionType.openPlan) {
            widget.openAction(context, type);
          } else {
            setState(() => _completed.add((message.id, index)));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(AppStrings.actionDone)),
            );
          }
        },
        onFailure: (failure) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(failure.userMessage)));
        },
      );
    } finally {
      if (mounted) setState(() => _handlingAction = false);
    }
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<ChatCubit, ChatState>(
    listener: (_, state) => WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    }),
    builder: (context, state) {
      final cubit = context.read<ChatCubit>();
      final messages = switch (state) {
        ChatLoaded(:final messages) || ChatError(:final messages) => messages,
        _ => const <ChatMessage>[],
      };
      final busy =
          state is ChatInitial ||
          state is ChatLoading ||
          state is ChatLoaded && (state.isSending || state.isClearing);
      return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Icon(Icons.auto_awesome, color: context.palette.primary),
              const SizedBox(width: 8),
              const Text(AppStrings.brainlyAi),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Weekly analytics',
              icon: const Icon(Icons.insights_outlined),
              onPressed: () => context.push(AppRoutes.analytics),
            ),
            IconButton(
              tooltip: AppStrings.clearConversation,
              icon: const Icon(Icons.delete_outline),
              onPressed: busy || messages.isEmpty
                  ? null
                  : () async {
                      final confirmed = await _confirm(
                        AppStrings.clearConversation,
                        AppStrings.clearConversationPrompt,
                      );
                      if (confirmed && mounted) await cubit.clear();
                    },
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.all(AppSpacing.screenMargin),
                  children: [
                    if (state is ChatInitial || state is ChatLoading)
                      const Center(child: CircularProgressIndicator()),
                    if (state is ChatEmpty) ...[
                      const SizedBox(height: 48),
                      Center(
                        child: CircleAvatar(
                          radius: 46,
                          backgroundColor: context.palette.primaryCTA,
                          child: Icon(
                            Icons.auto_awesome,
                            size: 52,
                            color: context.palette.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Hi, how can I help?',
                        textAlign: TextAlign.center,
                        style: context.text.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ask about your studies, tasks or habits.',
                        textAlign: TextAlign.center,
                        style: context.text.bodySmall?.copyWith(
                          color: context.palette.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          for (final item in [
                            (Icons.calendar_month_outlined, 'Plan my day'),
                            (
                              Icons.menu_book_outlined,
                              'Explain a topic simply',
                            ),
                            (Icons.track_changes, 'Help me focus'),
                            (Icons.science_outlined, 'Quiz me on physics'),
                          ])
                            SizedBox(
                              width: 155,
                              child: AppCard(
                                compact: true,
                                onTap: () => _submit(item.$2),
                                child: Column(
                                  children: [
                                    Icon(
                                      item.$1,
                                      color: context.palette.primary,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      item.$2,
                                      textAlign: TextAlign.center,
                                      style: context.text.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                    for (final message in messages) _message(message),
                    if (state is ChatLoaded && state.isSending)
                      const AiLoadingBubble(),
                    if (state is ChatLoaded && state.isClearing)
                      const LinearProgressIndicator(),
                    if (state is ChatError)
                      AiErrorCard(
                        failure: state.failure,
                        onRetry: state.canRetry ? cubit.retry : null,
                      ),
                  ],
                ),
              ),
              if (messages.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final prompt in [
                        'Plan my day',
                        'Explain a topic',
                        'Motivate me',
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            label: Text(prompt),
                            onPressed: busy ? null : () => _submit(prompt),
                          ),
                        ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.s3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _input,
                        enabled: !busy,
                        maxLines: 2,
                        maxLength: ChatCubit.maxMessageLength,
                        label: '',
                        hint: 'Ask Brainly AI...',
                        errorText: _validation,
                        onSubmitted: (_) => _submit(),
                      ),
                    ),
                    IconButton(
                      tooltip: AppStrings.send,
                      onPressed: busy ? null : _submit,
                      icon: Icon(
                        Icons.send_rounded,
                        color: context.palette.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: AiDisclaimer(),
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget _message(ChatMessage message) {
    final assistant = message.role == ChatRole.assistant;
    return Align(
      alignment: assistant
          ? AlignmentDirectional.centerStart
          : AlignmentDirectional.centerEnd,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.s8 * 20),
        child: AppCard(
          color: assistant
              ? context.palette.surface
              : context.palette.primaryCTA,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectionArea(
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: assistant
                          ? context.palette.textPrimary
                          : context.palette.onPrimary,
                    ),
                  ),
                ),
                if (assistant) ...[
                  const AiDisclaimer(),
                  Wrap(
                    spacing: AppSpacing.s2,
                    children: [
                      for (
                        var index = 0;
                        index < message.actions.length;
                        index++
                      )
                        ActionChip(
                          label: Text(_label(message.actions[index].type)),
                          onPressed:
                              _handlingAction ||
                                  _completed.contains((message.id, index))
                              ? null
                              : () => _runAction(message, index),
                        ),
                    ],
                  ),
                ],
                if (assistant)
                  IconButton(
                    tooltip: AppStrings.copyMessage,
                    icon: const Icon(Icons.copy_outlined),
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: message.text),
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(AppStrings.copiedMessage),
                          ),
                        );
                      }
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _label(AiActionType kind) => switch (kind) {
    AiActionType.createTask => 'Create task',
    AiActionType.createHabit => 'Create habit',
    AiActionType.startFocus => 'Start focus',
    AiActionType.openPlan => 'Open plan',
  };
}
