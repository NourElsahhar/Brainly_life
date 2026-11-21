import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/theme.dart';
import '../../data/models/analytics_models.dart';

class WeeklyTaskChart extends StatelessWidget {
  const WeeklyTaskChart({super.key, required this.days});
  final Map<String, TaskDayStats> days;

  @override
  Widget build(BuildContext context) {
    final entries = days.entries.toList();
    final values = entries.map((entry) => entry.value).toList();
    final maximum = values.fold(
      0,
      (peak, value) => math.max(peak, math.max(value.created, value.completed)),
    );
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: AppSpacing.s8 * 4,
          child: ExcludeSemantics(
            child: BarChart(
              BarChartData(
                maxY: math.max(1, maximum).toDouble(),
                borderData: FlBorderData(show: false),
                titlesData: _titles(
                  entries.map((entry) => entry.key).toList(),
                  context,
                ),
                barGroups: [
                  for (var i = 0; i < values.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: values[i].created.toDouble(),
                          color: palette.primary,
                        ),
                        BarChartRodData(
                          toY: values[i].completed.toDouble(),
                          color: palette.tealStrong,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        Text(
          entries
              .map(
                (entry) =>
                    '${entry.key.substring(5)}  ${AppStrings.created} ${entry.value.created}, ${AppStrings.completed} ${entry.value.completed}',
              )
              .join(' · '),
          style: context.text.bodySmall,
        ),
      ],
    );
  }
}

class WeeklyFocusChart extends StatelessWidget {
  const WeeklyFocusChart({super.key, required this.days});
  final Map<String, int> days;

  @override
  Widget build(BuildContext context) {
    final entries = days.entries.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: AppSpacing.s8 * 4,
          child: ExcludeSemantics(
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: entries
                    .fold(1, (peak, entry) => math.max(peak, entry.value))
                    .toDouble(),
                borderData: FlBorderData(show: false),
                titlesData: _titles(
                  entries.map((entry) => entry.key).toList(),
                  context,
                ),
                lineBarsData: [
                  LineChartBarData(
                    color: context.palette.primary,
                    spots: [
                      for (var i = 0; i < entries.length; i++)
                        FlSpot(i.toDouble(), entries[i].value.toDouble()),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Text(
          entries
              .map(
                (entry) =>
                    '${entry.key.substring(5)}  ${entry.value} ${AppStrings.minutes}',
              )
              .join(' · '),
          style: context.text.bodySmall,
        ),
      ],
    );
  }
}

FlTitlesData _titles(List<String> days, BuildContext context) => FlTitlesData(
  leftTitles: const AxisTitles(),
  rightTitles: const AxisTitles(),
  topTitles: const AxisTitles(),
  bottomTitles: AxisTitles(
    sideTitles: SideTitles(
      showTitles: true,
      interval: 1,
      reservedSize: AppSpacing.s5,
      getTitlesWidget: (value, _) {
        if (value < 0 ||
            value >= days.length ||
            value != value.roundToDouble()) {
          return const SizedBox.shrink();
        }
        return Text(
          days[value.toInt()].substring(8),
          style: context.text.labelSmall,
        );
      },
    ),
  ),
);

class WeeklyStudyChart extends StatelessWidget {
  const WeeklyStudyChart({
    super.key,
    required this.days,
    this.previous = const {},
  });
  final Map<String, int> days, previous;
  @override
  Widget build(BuildContext context) {
    final values = days.values.toList();
    final old = previous.values.toList();
    return Semantics(
      label: days.entries
          .map((e) => '${e.key}: ${e.value} study minutes')
          .join(', '),
      child: SizedBox(
        height: 150,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY:
                math
                    .max(
                      60,
                      [...values, ...old].fold(0, (a, b) => math.max(a, b)),
                    )
                    .toDouble() /
                60,
            borderData: FlBorderData(show: false),
            titlesData: _titles(days.keys.toList(), context),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  for (var i = 0; i < values.length; i++)
                    FlSpot(i.toDouble(), values[i] / 60),
                ],
                color: context.palette.primary,
                barWidth: 3,
                dotData: const FlDotData(show: false),
              ),
              if (old.isNotEmpty)
                LineChartBarData(
                  spots: [
                    for (var i = 0; i < old.length; i++)
                      FlSpot(i.toDouble(), old[i] / 60),
                  ],
                  color: context.palette.iconMuted,
                  dashArray: [5, 4],
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
