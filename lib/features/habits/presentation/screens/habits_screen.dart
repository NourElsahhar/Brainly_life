// HabitsScreen is the Habits tab: a progress ring with today's count, the
// habits due today (tap the check to mark one done, tap the card to open it),
// and an empty state with quick-start habits. The Focus timer and "add habit"
// buttons are in the top bar. All colors, text styles and spacing come from
// the theme.

import 'package:brainly_life/core/constants/app_strings.dart';
import 'package:brainly_life/core/routes/app_routes.dart';
import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/widgets/widgets.dart';
import 'package:brainly_life/features/habits/logic/habit_suggestion_cubit.dart';
import 'package:brainly_life/features/habits/logic/habit_templates.dart';
import 'package:brainly_life/features/habits/logic/habits_cubit.dart';
import 'package:brainly_life/features/habits/logic/habits_state.dart';
import 'package:brainly_life/features/habits/presentation/widgets/habit_icons.dart';
import 'package:brainly_life/features/habits/presentation/widgets/habit_suggestions_card.dart';
import 'package:brainly_life/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<HabitsCubit>()..loadHabits(),
      child: const HabitsView(),
    );
  }
}

class HabitsView extends StatelessWidget {
  const HabitsView({super.key});

  /// Opens a screen on top, and refreshes the list when the user comes back.
  Future<void> _open(
    BuildContext context,
    String location, {
    Object? extra,
  }) async {
    final cubit = context.read<HabitsCubit>();
    await context.push(location, extra: extra);
    cubit.loadHabits(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.habitsTitle),
        actions: [
          IconButton(
            tooltip: AppStrings.habitsFocusTooltip,
            icon: const Icon(Icons.timer_outlined),
            onPressed: () => context.push(AppRoutes.focus),
          ),
          IconButton(
            tooltip: AppStrings.habitsAddTooltip,
            icon: Icon(Icons.add_rounded, color: p.primary),
            onPressed: () => _open(context, AppRoutes.newHabit),
          ),
          const SizedBox(width: AppSpacing.s2),
        ],
      ),
      body: BlocConsumer<HabitsCubit, HabitsState>(
        listenWhen: (previous, current) =>
            current is HabitsLoaded &&
            current.toggleFailure != null &&
            (previous is! HabitsLoaded ||
                previous.toggleFailure != current.toggleFailure),
        listener: (context, state) {
          if (state is HabitsLoaded && state.toggleFailure != null) {
            AppSnackBar.error(context, state.toggleFailure!.userMessage);
          }
        },
        builder: (context, state) {
          final cubit = context.read<HabitsCubit>();
          return switch (state) {
            HabitsInitial() || HabitsLoading() => const LoadingView(),
            HabitsError(:final failure) => ErrorView(
              failure: failure,
              onRetry: cubit.loadHabits,
            ),
            HabitsEmpty() => _EmptyBody(
              onNew: () => _open(context, AppRoutes.newHabit),
              onTemplate: (template) =>
                  _open(context, AppRoutes.newHabit, extra: template),
            ),
            HabitsLoaded loaded when loaded.items.isEmpty => const EmptyView(
              icon: Icons.event_available_rounded,
              title: AppStrings.habitsNothingDueTitle,
              message: AppStrings.habitsNothingDueMessage,
            ),
            HabitsLoaded loaded => _HabitsList(
              loaded: loaded,
              onToggle: cubit.toggleHabit,
              onOpen: (id) => _open(context, AppRoutes.habitPath(id)),
            ),
          };
        },
      ),
    );
  }
}

class _HabitsList extends StatelessWidget {
  const _HabitsList({
    required this.loaded,
    required this.onToggle,
    required this.onOpen,
  });

  final HabitsLoaded loaded;
  final void Function(String habitId) onToggle;
  final void Function(String habitId) onOpen;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenMargin,
        AppSpacing.s2,
        AppSpacing.screenMargin,
        AppSpacing.s6,
      ),
      children: [
        _ProgressCard(loaded: loaded),
        const SizedBox(height: AppSpacing.cardGap),
        for (final item in loaded.items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s2),
            child: _HabitTile(
              item: item,
              onTap: () => onOpen(item.habit.id),
              onToggle: () => onToggle(item.habit.id),
            ),
          ),
        // AI tips (only after the user taps "Get suggestions").
        if (getIt.isRegistered<HabitSuggestionCubit>()) ...[
          const SizedBox(height: AppSpacing.s4),
          const HabitSuggestionsSection(),
        ],
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.loaded});

  final HabitsLoaded loaded;

  static const double _ringSize = AppSpacing.s10 * 3;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final allDone =
        loaded.totalCount > 0 && loaded.completedCount == loaded.totalCount;

    return AppCard(
      child: Row(
        children: [
          SizedBox(
            width: _ringSize,
            height: _ringSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: loaded.progress,
                    strokeWidth: AppSizes.progressActiveStrokeWidth,
                    strokeCap: StrokeCap.round,
                    color: p.teal,
                    backgroundColor: p.progressTrack,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${loaded.completedCount}/${loaded.totalCount}',
                      style: context.text.headlineLarge,
                    ),
                    Text(
                      AppStrings.habitsDoneToday,
                      style: context.text.bodySmall?.copyWith(
                        color: p.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.star_rounded, color: p.teal),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  allDone
                      ? AppStrings.habitsAllDone
                      : AppStrings.habitsKeepGoing(loaded.userName),
                  style: context.text.headlineMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitTile extends StatelessWidget {
  const _HabitTile({
    required this.item,
    required this.onTap,
    required this.onToggle,
  });

  final HabitTodayItem item;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final habit = item.habit;
    final color = Color(habit.colorValue);

    return AppCard(
      compact: true,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: AppSizes.minTouchTarget,
            height: AppSizes.minTouchTarget,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(habitIconFor(habit.icon), color: color),
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.headlineSmall,
                ),
                if (habit.currentStreak > 0)
                  Row(
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        size: AppSizes.iconSmall,
                        color: p.warningAccent,
                      ),
                      const SizedBox(width: AppSpacing.s1),
                      Text(
                        AppStrings.habitStreakLabel(habit.currentStreak),
                        style: context.text.bodySmall?.copyWith(
                          color: p.textSecondary,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          _CheckButton(isDone: item.isDone, onPressed: onToggle),
        ],
      ),
    );
  }
}

class _CheckButton extends StatelessWidget {
  const _CheckButton({required this.isDone, required this.onPressed});

  final bool isDone;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return IconButton(
      tooltip: isDone ? AppStrings.habitMarkUndone : AppStrings.habitMarkDone,
      onPressed: onPressed,
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: AppSpacing.s8,
        height: AppSpacing.s8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDone ? p.teal : null,
          border: Border.all(color: isDone ? p.teal : p.border, width: 2),
        ),
        child: isDone
            ? Icon(
                Icons.check_rounded,
                size: AppSizes.iconStandard,
                color: p.onPrimary,
              )
            : null,
      ),
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody({required this.onNew, required this.onTemplate});

  final VoidCallback onNew;
  final void Function(HabitTemplate template) onTemplate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: EmptyView(
            icon: Icons.eco_outlined,
            title: AppStrings.habitsEmptyTitle,
            message: AppStrings.habitsEmptyMessage,
            actionLabel: AppStrings.habitsEmptyCta,
            onAction: onNew,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenMargin,
            0,
            AppSpacing.screenMargin,
            AppSpacing.s6,
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.s2,
            runSpacing: AppSpacing.s2,
            children: [
              for (final template in habitTemplates)
                _TemplateChip(
                  template: template,
                  onTap: () => onTemplate(template),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TemplateChip extends StatelessWidget {
  const _TemplateChip({required this.template, required this.onTap});

  final HabitTemplate template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = BorderRadius.circular(AppRadius.pill);
    return Material(
      color: p.tealSoft,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  habitIconFor(template.icon),
                  size: AppSizes.iconStandard,
                  color: p.tealStrong,
                ),
                const SizedBox(width: AppSpacing.s2),
                Text(
                  template.name,
                  style: context.text.labelMedium?.copyWith(
                    color: p.tealStrong,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
