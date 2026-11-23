// HabitSuggestionsCard is the "AI suggestions" card of the Habits screen. It
// starts with a "Get suggestions" button (the AI is called only after a tap),
// then shows up to 3 tips. Each tip has Add (opens the new habit form with the
// tip as the name) and a dismiss button. It needs a HabitSuggestionCubit above
// it in the tree.
//
// HabitSuggestionsSection = the card with its own cubit from getIt. Use it in
// the Habits screen once HabitSuggestionPort is registered (see the notes for
// M5 in the PR).

import 'package:brainly_life/core/constants/app_strings.dart';
import 'package:brainly_life/core/routes/app_routes.dart';
import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/widgets/widgets.dart';
import 'package:brainly_life/features/habits/data/models/habit_model.dart';
import 'package:brainly_life/features/habits/data/models/habit_suggestion_model.dart';
import 'package:brainly_life/features/habits/logic/habit_suggestion_cubit.dart';
import 'package:brainly_life/features/habits/logic/habit_suggestion_state.dart';
import 'package:brainly_life/features/habits/logic/habit_templates.dart';
import 'package:brainly_life/features/habits/presentation/widgets/habit_icons.dart';
import 'package:brainly_life/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The card with its own cubit from getIt. The default "Add" opens the new
/// habit form with the tip as the name.
class HabitSuggestionsSection extends StatelessWidget {
  const HabitSuggestionsSection({super.key, this.onAdd});

  /// Replaces the default "Add" action.
  final void Function(HabitSuggestion suggestion)? onAdd;

  void _openForm(BuildContext context, HabitSuggestion suggestion) {
    final name = suggestion.title.length > Habit.maxNameLength
        ? suggestion.title.substring(0, Habit.maxNameLength)
        : suggestion.title;
    context.push(
      AppRoutes.newHabit,
      extra: HabitTemplate(name: name, icon: habitIcons.keys.first),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<HabitSuggestionCubit>(),
      child: Builder(
        builder: (context) => HabitSuggestionsCard(
          onAdd: onAdd ?? (suggestion) => _openForm(context, suggestion),
        ),
      ),
    );
  }
}

class HabitSuggestionsCard extends StatelessWidget {
  const HabitSuggestionsCard({super.key, required this.onAdd});

  final void Function(HabitSuggestion suggestion) onAdd;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: p.primary),
              const SizedBox(width: AppSpacing.s2),
              Text(AppStrings.habitsAiTitle, style: context.text.headlineSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          BlocBuilder<HabitSuggestionCubit, HabitSuggestionState>(
            builder: (context, state) {
              final cubit = context.read<HabitSuggestionCubit>();
              return switch (state) {
                HabitSuggestionInitial() => AppButton(
                  label: AppStrings.habitsAiGet,
                  icon: Icons.auto_awesome_rounded,
                  type: AppButtonType.secondary,
                  onPressed: cubit.fetch,
                ),
                HabitSuggestionLoading() => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.s2),
                    child: CircularProgressIndicator(
                      color: p.primary,
                      backgroundColor: p.progressTrack,
                    ),
                  ),
                ),
                HabitSuggestionEmpty() => Text(
                  AppStrings.habitsAiEmpty,
                  style: context.text.bodyMedium?.copyWith(
                    color: p.textSecondary,
                  ),
                ),
                HabitSuggestionError() => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.habitsAiUnavailable,
                      style: context.text.bodyMedium?.copyWith(
                        color: p.textSecondary,
                      ),
                    ),
                    AppButton(
                      label: AppStrings.habitsAiRetry,
                      type: AppButtonType.text,
                      expanded: false,
                      onPressed: cubit.fetch,
                    ),
                  ],
                ),
                HabitSuggestionLoaded(:final suggestions) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < suggestions.length; i++) ...[
                      if (i > 0) const Divider(),
                      _SuggestionRow(
                        suggestion: suggestions[i],
                        onAdd: () => onAdd(suggestions[i]),
                        onDismiss: () => cubit.dismiss(suggestions[i]),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.s2),
                    Text(
                      AppStrings.habitsAiDisclaimer,
                      style: context.text.labelSmall?.copyWith(
                        color: p.textTertiary,
                      ),
                    ),
                  ],
                ),
              };
            },
          ),
        ],
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({
    required this.suggestion,
    required this.onAdd,
    required this.onDismiss,
  });

  final HabitSuggestion suggestion;
  final VoidCallback onAdd;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(suggestion.title, style: context.text.bodyLarge),
                const SizedBox(height: AppSpacing.s1),
                Text(
                  suggestion.reason,
                  style: context.text.bodySmall?.copyWith(
                    color: p.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        TextButton(
          onPressed: onAdd,
          style: TextButton.styleFrom(
            foregroundColor: p.primary,
            minimumSize: const Size.square(AppSizes.minTouchTarget),
          ),
          child: Text(AppStrings.habitsAiAdd, style: context.text.labelLarge),
        ),
        IconButton(
          tooltip: AppStrings.habitsAiDismiss,
          onPressed: onDismiss,
          icon: Icon(Icons.close_rounded, color: p.iconMuted),
        ),
      ],
    );
  }
}
