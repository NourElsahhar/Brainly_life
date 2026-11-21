import '../../../core/errors/failure.dart';
import '../data/models/analytics_models.dart';

sealed class AnalyticsState {
  const AnalyticsState();
}

class AnalyticsInitial extends AnalyticsState {
  const AnalyticsInitial();
}

class AnalyticsLoading extends AnalyticsState {
  const AnalyticsLoading(this.week);
  final AnalyticsWeek week;
}

class AnalyticsEmpty extends AnalyticsState {
  const AnalyticsEmpty(this.week);
  final AnalyticsWeek week;
}

class AnalyticsError extends AnalyticsState {
  const AnalyticsError(this.week, this.failure);
  final AnalyticsWeek week;
  final Failure failure;
}

class AnalyticsLoaded extends AnalyticsState {
  const AnalyticsLoaded({
    required this.week,
    required this.stats,
    required this.isCurrent,
    this.score,
    this.previousScore,
    this.previousStats,
    this.report,
    this.reportFailure,
    this.isGenerating = false,
  });

  final AnalyticsWeek week;
  final WeeklyStats stats;
  final int? score;
  final int? previousScore;
  final WeeklyStats? previousStats;
  final bool isCurrent;
  final WeeklyReport? report;
  final Failure? reportFailure;
  final bool isGenerating;

  AnalyticsLoaded withReport({
    WeeklyReport? report,
    Failure? failure,
    bool generating = false,
  }) => AnalyticsLoaded(
    week: week,
    stats: stats,
    isCurrent: isCurrent,
    score: score,
    previousScore: previousScore,
    previousStats: previousStats,
    report: report ?? this.report,
    reportFailure: failure,
    isGenerating: generating,
  );
}
