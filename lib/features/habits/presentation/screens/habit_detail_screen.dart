// HabitDetailScreen shows one habit: its icon, name and schedule, the current
// and best streak, the last 30 days rate, a month calendar, the 7 and 30 day
// completion bars, and the Archive and Delete buttons. Tapping a day in the
// calendar marks it or unmarks it (up to 7 days back). The pencil opens the
// edit form. Archive and Delete ask for confirmation first. All colors, text
// styles and spacing come from the theme.

import 'package:brainly_life/core/constants/app_strings.dart';
import 'package:brainly_life/core/routes/app_routes.dart';
import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/utils/utils.dart';
import 'package:brainly_life/core/widgets/widgets.dart';
import 'package:brainly_life/features/habits/data/models/habit_model.dart';
import 'package:brainly_life/features/habits/logic/habit_detail_cubit.dart';
import 'package:brainly_life/features/habits/logic/habit_detail_state.dart';
import 'package:brainly_life/features/habits/presentation/widgets/habit_icons.dart';
import 'package:brainly_life/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class HabitDetailScreen extends StatelessWidget {
  const HabitDetailScreen({super.key, required this.habitId});

  final String habitId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<HabitDetailCubit>(param1: habitId)..load(),
      child: const HabitDetailView(),
    );
  }
}

class HabitDetailView extends StatelessWidget {
  const HabitDetailView({super.key});

  void _close(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.habits);
    }
  }

  Future<void> _edit(BuildContext context, Habit habit) async {
    final cubit = context.read<HabitDetailCubit>();
    await context.push(AppRoutes.editHabitPath(habit.id), extra: habit);
    if (!cubit.isClosed) cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HabitDetailCubit, HabitDetailState>(
      listenWhen: (previous, current) =>
          (current is HabitDetailRemoved && previous is! HabitDetailRemoved) ||
          (current is HabitDetailLoaded &&
              current.actionFailure != null &&
              (previous is! HabitDetailLoaded ||
                  previous.actionFailure != current.actionFailure)),
      listener: (context, state) {
        if (state is HabitDetailRemoved) {
          _close(context);
        } else if (state is HabitDetailLoaded && state.actionFailure != null) {
          AppSnackBar.error(context, state.actionFailure!.userMessage);
        }
      },
      builder: (context, state) {
        final cubit = context.read<HabitDetailCubit>();
        final habit = state is HabitDetailLoaded ? state.habit : null;
        return Scaffold(
          appBar: AppBar(
            actions: [
              if (habit != null)
                IconButton(
                  tooltip: AppStrings.habitDetailEditTooltip,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _edit(context, habit),
                ),
              const SizedBox(width: AppSpacing.s2),
            ],
          ),
          body: switch (state) {
            HabitDetailInitial() ||
            HabitDetailLoading() ||
            HabitDetailRemoved() => const LoadingView(),
            HabitDetailError(:final failure) => ErrorView(
              failure: failure,
              onRetry: cubit.load,
            ),
            HabitDetailLoaded loaded => _DetailBody(
              state: loaded,
              cubit: cubit,
            ),
          },
        );
      },
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.state, required this.cubit});

  final HabitDetailLoaded state;
  final HabitDetailCubit cubit;

  Future<void> _archive(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: AppStrings.habitArchiveConfirmTitle,
      message: AppStrings.habitArchiveConfirmMessage,
      confirmLabel: AppStrings.habitArchiveAction,
    );
    if (confirmed) cubit.archive();
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: AppStrings.habitDeleteConfirmTitle,
      message: state.currentStreak > 0
          ? AppStrings.habitDeleteConfirmWithStreak(state.currentStreak)
          : AppStrings.habitDeleteConfirmMessage,
      confirmLabel: AppStrings.habitDeleteAction,
      isDestructive: true,
    );
    if (confirmed) cubit.delete();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenMargin,
        AppSpacing.s2,
        AppSpacing.screenMargin,
        AppSpacing.s6,
      ),
      children: [
        _Header(habit: state.habit),
        const SizedBox(height: AppSpacing.s5),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _StatCard(
                  valueKey: const Key('habit_current_streak'),
                  value: '${state.currentStreak}',
                  label: AppStrings.habitDetailCurrentStreak,
                  icon: Icons.local_fire_department_rounded,
                  iconColor: p.warningAccent,
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: _StatCard(
                  valueKey: const Key('habit_best_streak'),
                  value: '${state.bestStreak}',
                  label: AppStrings.habitDetailBestStreak,
                  icon: Icons.emoji_events_rounded,
                  iconColor: p.warningAccent,
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: _StatCard(
                  valueKey: const Key('habit_rate_30'),
                  value: AppStrings.habitDetailPercent(state.rate30),
                  label: AppStrings.habitDetailLast30Days,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.cardGap),
        _CalendarCard(state: state, cubit: cubit),
        const SizedBox(height: AppSpacing.cardGap),
        _CompletionCard(state: state),
        const SizedBox(height: AppSpacing.s5),
        Row(
          children: [
            if (!state.habit.archived) ...[
              Expanded(
                child: AppButton(
                  label: AppStrings.habitArchiveAction,
                  icon: Icons.archive_outlined,
                  type: AppButtonType.secondary,
                  onPressed: () => _archive(context),
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
            ],
            Expanded(
              child: AppButton(
                label: AppStrings.habitDeleteAction,
                icon: Icons.delete_outline_rounded,
                type: AppButtonType.destructive,
                onPressed: () => _delete(context),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

String _subtitle(Habit habit) => switch (habit.frequencyType) {
  HabitFrequencyType.daily => AppStrings.habitEveryDay,
  HabitFrequencyType.weekdays => AppStrings.habitEveryWeekdays(
    ([...habit.weekdays]..sort()).map(AppStrings.habitWeekdayShort).join(', '),
  ),
  HabitFrequencyType.timesPerWeek => AppStrings.habitTimesPerWeekSubtitle(
    habit.timesPerWeek ?? 1,
  ),
};

class _Header extends StatelessWidget {
  const _Header({required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = Color(habit.colorValue);
    final iconColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? p.onPrimary
        : p.textPrimary;

    return Row(
      children: [
        Container(
          width: AppSpacing.s10 + AppSpacing.s8,
          height: AppSpacing.s10 + AppSpacing.s8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(
            habitIconFor(habit.icon),
            size: AppSpacing.s8,
            color: iconColor,
          ),
        ),
        const SizedBox(width: AppSpacing.s4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(habit.name, style: context.text.headlineLarge),
              const SizedBox(height: AppSpacing.s1),
              Text(
                _subtitle(habit),
                style: context.text.bodyMedium?.copyWith(
                  color: p.textSecondary,
                ),
              ),
              if (habit.archived) ...[
                const SizedBox(height: AppSpacing.s2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s3,
                    vertical: AppSpacing.s1,
                  ),
                  decoration: BoxDecoration(
                    color: p.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    AppStrings.habitDetailArchivedBadge,
                    style: context.text.labelMedium?.copyWith(
                      color: p.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.valueKey,
    required this.value,
    required this.label,
    this.icon,
    this.iconColor,
  });

  final Key valueKey;
  final String value;
  final String label;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      compact: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: iconColor, size: AppSizes.iconNavigation),
                const SizedBox(width: AppSpacing.s1),
              ],
              Text(value, key: valueKey, style: AppTextStyles.metricCounter),
            ],
          ),
          const SizedBox(height: AppSpacing.s1),
          Text(
            label,
            textAlign: TextAlign.center,
            style: context.text.bodySmall?.copyWith(color: p.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({required this.state, required this.cubit});

  final HabitDetailLoaded state;
  final HabitDetailCubit cubit;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final first = DateKeyUtils.parse(state.monthStart);
    // Empty cells before day 1, so the days sit under the right weekday.
    final offset = (first.weekday - state.weekStartDay + 7) % 7;
    final days = state.monthDateKeys;
    final weekdays = [
      for (var i = 0; i < 7; i++) ((state.weekStartDay - 1 + i) % 7) + 1,
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat.yMMMM().format(first),
                  style: context.text.headlineSmall,
                ),
              ),
              IconButton(
                tooltip: AppStrings.habitDetailPrevMonth,
                onPressed: state.canGoPrevious ? cubit.previousMonth : null,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              IconButton(
                tooltip: AppStrings.habitDetailNextMonth,
                onPressed: state.canGoNext ? cubit.nextMonth : null,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s2),
          Row(
            children: [
              for (final day in weekdays)
                Expanded(
                  child: Center(
                    child: Text(
                      AppStrings.habitWeekdayShort(day),
                      style: context.text.bodySmall?.copyWith(
                        color: p.textSecondary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s2),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisExtent: AppSizes.minTouchTarget,
            ),
            itemCount: offset + days.length,
            itemBuilder: (context, index) {
              if (index < offset) return const SizedBox.shrink();
              return _DayCell(
                dateKey: days[index - offset],
                state: state,
                cubit: cubit,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.dateKey,
    required this.state,
    required this.cubit,
  });

  final String dateKey;
  final HabitDetailLoaded state;
  final HabitDetailCubit cubit;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDone = state.doneDates.contains(dateKey);
    final isToday = dateKey == state.today;
    final canToggle = state.canToggleDay(dateKey);
    final outOfRange =
        dateKey.compareTo(state.today) > 0 ||
        dateKey.compareTo(state.habit.startDate) < 0;
    final color = Color(state.habit.colorValue);
    final onColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? p.onPrimary
        : p.textPrimary;
    final number = int.parse(dateKey.substring(8));

    return Semantics(
      button: canToggle,
      selected: isDone,
      label: '$number',
      child: InkResponse(
        key: ValueKey('habit_day_$dateKey'),
        onTap: canToggle ? () => cubit.toggleDay(dateKey) : null,
        radius: AppSizes.minTouchTarget / 2,
        child: Center(
          child: Container(
            width: AppSpacing.s8 + AppSpacing.s1,
            height: AppSpacing.s8 + AppSpacing.s1,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone ? color : null,
              border: isToday && !isDone
                  ? Border.all(color: color, width: 2)
                  : null,
            ),
            child: Text(
              '$number',
              style: context.text.bodyMedium?.copyWith(
                color: isDone
                    ? onColor
                    : (outOfRange ? p.textTertiary : p.textPrimary),
                fontWeight: isDone ? FontWeight.w700 : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompletionCard extends StatelessWidget {
  const _CompletionCard({required this.state});

  final HabitDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.habitDetailCompletion,
            style: context.text.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.s3),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _RateColumn(
                    label: AppStrings.habitDetailLast7Days,
                    valueText: AppStrings.habitDetailCompletionDays(
                      state.doneLast7,
                      state.dueLast7,
                    ),
                    rate: state.rate7,
                  ),
                ),
                const VerticalDivider(width: AppSpacing.s6),
                Expanded(
                  child: _RateColumn(
                    label: AppStrings.habitDetailLast30Days,
                    valueText: AppStrings.habitDetailPercent(state.rate30),
                    rate: state.rate30,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RateColumn extends StatelessWidget {
  const _RateColumn({
    required this.label,
    required this.valueText,
    required this.rate,
  });

  final String label;
  final String valueText;
  final double rate;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.text.bodySmall?.copyWith(color: p.textSecondary),
        ),
        const SizedBox(height: AppSpacing.s1),
        Text(valueText, style: AppTextStyles.metricCounter),
        const SizedBox(height: AppSpacing.s2),
        LinearProgressIndicator(
          value: rate.clamp(0.0, 1.0).toDouble(),
          minHeight: AppSpacing.s2,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          color: p.teal,
          backgroundColor: p.progressTrack,
        ),
      ],
    );
  }
}
