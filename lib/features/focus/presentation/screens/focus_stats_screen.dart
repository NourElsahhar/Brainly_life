// FocusStatsScreen shows the focus statistics: minutes today and this week,
// the focus-day streak, a 7-day bar chart, the best time of day, the number
// of sessions and the latest history. The numbers come from FocusStatsCubit.
// The chart is drawn with plain widgets. All colors, text styles and spacing
// come from the theme.

import 'package:brainly_life/core/constants/app_strings.dart';
import 'package:brainly_life/core/routes/app_routes.dart';
import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/utils/utils.dart';
import 'package:brainly_life/core/widgets/widgets.dart';
import 'package:brainly_life/features/focus/data/models/focus_session_model.dart';
import 'package:brainly_life/features/focus/logic/focus_stats_cubit.dart';
import 'package:brainly_life/features/focus/logic/focus_stats_state.dart';
import 'package:brainly_life/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class FocusStatsScreen extends StatelessWidget {
  const FocusStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<FocusStatsCubit>()..load(),
      child: const FocusStatsView(),
    );
  }
}

class FocusStatsView extends StatelessWidget {
  const FocusStatsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(AppStrings.focusStatsTitle),
      ),
      body: BlocBuilder<FocusStatsCubit, FocusStatsState>(
        builder: (context, state) => switch (state) {
          FocusStatsInitial() || FocusStatsLoading() => const LoadingView(),
          FocusStatsError(:final failure) => ErrorView(
            failure: failure,
            onRetry: context.read<FocusStatsCubit>().load,
          ),
          FocusStatsEmpty() => const _EmptyBody(),
          FocusStatsLoaded() => _StatsBody(state: state),
        },
      ),
    );
  }
}

/// "50 min" under an hour, otherwise hours like "9 h" or "9.5 h".
String _hoursText(int minutes) {
  final hours = minutes / 60;
  final text = hours == hours.roundToDouble()
      ? '${hours.round()}'
      : hours.toStringAsFixed(1);
  return AppStrings.focusHoursValue(text);
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenMargin),
      child: Column(
        children: [
          const _SummaryRow(minutesToday: 0, minutesThisWeek: 0, streak: 0),
          Expanded(
            child: EmptyView(
              icon: Icons.timer_outlined,
              title: AppStrings.focusStatsEmptyTitle,
              message: AppStrings.focusStatsEmptyMessage,
              actionLabel: AppStrings.focusStatsStartFocus,
              onAction: () => context.canPop()
                  ? context.pop()
                  : context.go(AppRoutes.focus),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsBody extends StatelessWidget {
  const _StatsBody({required this.state});

  final FocusStatsLoaded state;

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
        _SummaryRow(
          minutesToday: state.minutesToday,
          minutesThisWeek: state.minutesThisWeek,
          streak: state.focusDayStreak,
        ),
        const SizedBox(height: AppSpacing.cardGap),
        _WeekChart(days: state.last7Days, today: state.today),
        const SizedBox(height: AppSpacing.cardGap),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _BestTimeCard(dayPart: state.bestDayPart)),
              const SizedBox(width: AppSpacing.s3),
              Expanded(child: _TotalSessionsCard(total: state.totalSessions)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s6),
        Text(AppStrings.focusStatsHistory, style: context.text.headlineSmall),
        const SizedBox(height: AppSpacing.s3),
        for (final session in state.history)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s2),
            child: _HistoryTile(session: session, today: state.today),
          ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.minutesToday,
    required this.minutesThisWeek,
    required this.streak,
  });

  final int minutesToday;
  final int minutesThisWeek;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _StatCard(
              label: AppStrings.focusStatsToday,
              value: Text(
                AppStrings.focusMinutesValue(minutesToday),
                style: AppTextStyles.metricCounter.copyWith(
                  color: p.tealStrong,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: _StatCard(
              label: AppStrings.focusStatsThisWeek,
              value: Text(
                _hoursText(minutesThisWeek),
                style: AppTextStyles.metricCounter.copyWith(color: p.primary),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: _StatCard(
              label: AppStrings.focusStatsStreak,
              value: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_fire_department_rounded,
                    color: p.warningAccent,
                    size: AppSizes.iconNavigation,
                  ),
                  const SizedBox(width: AppSpacing.s1),
                  Text(
                    '$streak',
                    style: AppTextStyles.metricCounter.copyWith(
                      color: p.warning,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      compact: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          value,
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

/// Bar chart of the last 7 days, drawn with plain widgets. The scale goes
/// up in steps of 30 minutes (at least 30) and is split in three.
class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.days, required this.today});

  final Map<String, int> days;
  final String today;

  static const double _plotHeight = AppSpacing.s10 * 3;
  static const double _axisWidth = AppSpacing.s10;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final entries = days.entries.toList();
    final maxMinutes = entries.fold<int>(
      0,
      (m, e) => e.value > m ? e.value : m,
    );
    final niceMax = maxMinutes <= 30 ? 30 : ((maxMinutes + 29) ~/ 30) * 30;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.focusStatsLast7Days,
            style: context.text.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.s3),
          SizedBox(
            height: _plotHeight + AppSpacing.s2 + AppSpacing.s6,
            child: Stack(
              children: [
                // Grid lines with their minute labels.
                for (var i = 0; i <= 3; i++)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: _plotHeight * i / 3,
                    height: AppSpacing.s4,
                    child: Row(
                      children: [
                        SizedBox(
                          width: _axisWidth,
                          child: Text(
                            '${niceMax * i ~/ 3}',
                            style: context.text.labelSmall?.copyWith(
                              color: p.textTertiary,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: p.border)),
                      ],
                    ),
                  ),
                // The bars.
                Positioned(
                  left: _axisWidth,
                  right: 0,
                  bottom: AppSpacing.s2,
                  height: _plotHeight + AppSpacing.s6,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final entry in entries)
                        Expanded(
                          child: _Bar(
                            minutes: entry.value,
                            height: _plotHeight * entry.value / niceMax,
                            isToday: entry.key == today,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: _axisWidth),
            child: Row(
              children: [
                for (final entry in entries)
                  Expanded(
                    child: Text(
                      DateFormat.E().format(DateKeyUtils.parse(entry.key)),
                      textAlign: TextAlign.center,
                      style: context.text.bodySmall?.copyWith(
                        color: entry.key == today
                            ? p.textPrimary
                            : p.textSecondary,
                        fontWeight: entry.key == today ? FontWeight.w700 : null,
                      ),
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

class _Bar extends StatelessWidget {
  const _Bar({
    required this.minutes,
    required this.height,
    required this.isToday,
  });

  final int minutes;
  final double height;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (minutes > 0) ...[
          Text(
            '$minutes',
            style: context.text.labelSmall?.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: AppSpacing.s1),
          FractionallySizedBox(
            widthFactor: 0.6,
            child: Container(
              height: height < AppSpacing.s1 ? AppSpacing.s1 : height,
              decoration: BoxDecoration(
                color: isToday ? p.teal : p.teal.withValues(alpha: 0.55),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.sm),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _BestTimeCard extends StatelessWidget {
  const _BestTimeCard({required this.dayPart});

  final FocusDayPart? dayPart;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final part = dayPart;
    final (icon, text) = switch (part) {
      FocusDayPart.morning => (
        Icons.wb_sunny_rounded,
        AppStrings.focusDayPartMorning,
      ),
      FocusDayPart.afternoon => (
        Icons.wb_twilight_rounded,
        AppStrings.focusDayPartAfternoon,
      ),
      FocusDayPart.evening => (
        Icons.nights_stay_rounded,
        AppStrings.focusDayPartEvening,
      ),
      FocusDayPart.night => (
        Icons.bedtime_rounded,
        AppStrings.focusDayPartNight,
      ),
      null => (Icons.schedule_rounded, '-'),
    };

    return AppCard(
      compact: true,
      child: Row(
        children: [
          _IconBubble(icon: icon, color: p.tealStrong, background: p.tealSoft),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppStrings.focusStatsBestTime,
                  style: context.text.bodySmall?.copyWith(
                    color: p.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.s1),
                Text(
                  text,
                  style: context.text.labelLarge?.copyWith(color: p.tealStrong),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalSessionsCard extends StatelessWidget {
  const _TotalSessionsCard({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      compact: true,
      child: Row(
        children: [
          _IconBubble(
            icon: Icons.bar_chart_rounded,
            color: p.primary,
            background: p.primarySoft,
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppStrings.focusStatsTotalSessions,
                  style: context.text.bodySmall?.copyWith(
                    color: p.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.s1),
                Text(
                  '$total',
                  style: AppTextStyles.metricCounter.copyWith(color: p.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({
    required this.icon,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSpacing.s10,
      height: AppSpacing.s10,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, color: color, size: AppSizes.iconNavigation),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.session, required this.today});

  final FocusSession session;
  final String today;

  String _dayLabel() {
    if (session.dateKey == today) return AppStrings.focusStatsToday;
    if (session.dateKey == DateKeyUtils.addDays(today, -1)) {
      return AppStrings.focusStatsYesterday;
    }
    return DateFormat('d MMM').format(DateKeyUtils.parse(session.dateKey));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final time = DateFormat.jm().format(session.startedAt.toLocal());
    return AppCard(
      compact: true,
      child: Row(
        children: [
          _IconBubble(
            icon: Icons.timer_outlined,
            color: p.tealStrong,
            background: p.tealSoft,
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Text(
              AppStrings.focusHistoryItem(
                _dayLabel(),
                time,
                session.actualMinutes,
              ),
              style: context.text.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
