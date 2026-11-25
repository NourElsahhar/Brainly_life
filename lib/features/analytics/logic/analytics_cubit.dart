import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/ai/ai.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/result.dart';
import '../data/models/analytics_models.dart';
import '../data/repositories/analytics_repository.dart';
import 'analytics_calendar.dart';
import 'analytics_state.dart';
import 'productivity_score.dart';
import 'weekly_stats_calculator.dart';

class AnalyticsCubit extends Cubit<AnalyticsState> {
  AnalyticsCubit({
    required this._repository,
    required this._calendar,
    required this._ai,
    required this._now,
  }) : super(const AnalyticsInitial());

  final AnalyticsRepository _repository;
  final AnalyticsCalendar _calendar;
  final AiClient _ai;
  final DateTime Function() _now;
  final _calculator = const WeeklyStatsCalculator();
  final _score = const ProductivityScore();
  late AnalyticsWeek _selected = _calendar.weekContaining(_now());
  int _loadVersion = 0;

  bool get canGoNext =>
      _selected.startUtc.isBefore(_calendar.weekContaining(_now()).startUtc);

  Future<void> move(int direction) async {
    final next = _calendar.shift(_selected, direction);
    if (next.startUtc.isAfter(_calendar.weekContaining(_now()).startUtc)) {
      return;
    }
    _selected = next;
    await load();
  }

  Future<void> load() async {
    final version = ++_loadVersion;
    final now = _now();
    final week = _selected;
    final previous = _calendar.shift(week, -1);
    final isCurrent = now.isBefore(week.endUtc);
    emit(AnalyticsLoading(week));
    final (current, last, saved) = await (
      _repository.readWeek(week, now),
      _repository.readWeek(previous, now),
      isCurrent
          ? Future.value(const Result<WeeklyReport?>.success(null))
          : _repository.readReport(week.key),
    ).wait;
    if (isClosed || version != _loadVersion) return;
    final data = current.dataOrNull;
    if (data == null) {
      emit(AnalyticsError(week, current.failureOrNull!));
      return;
    }

    final stats = _calculator.calculate(
      data,
      week,
      now: now,
      dateKey: _calendar.dateKey,
    );
    final priorData = last.dataOrNull;
    final prior = priorData == null
        ? null
        : _calculator.calculate(
            priorData,
            previous,
            now: now,
            dateKey: _calendar.dateKey,
          );
    if (stats.isEmpty && saved.dataOrNull == null) {
      emit(AnalyticsEmpty(week));
      return;
    }
    emit(
      AnalyticsLoaded(
        week: week,
        stats: stats,
        isCurrent: isCurrent,
        score: _score.calculate(stats),
        previousScore: prior == null ? null : _score.calculate(prior),
        previousStats: prior,
        report: saved.dataOrNull,
        reportFailure: saved.failureOrNull,
      ),
    );
  }

  Future<void> generateReport() async {
    final current = state;
    if (current is! AnalyticsLoaded ||
        current.isCurrent ||
        current.report != null ||
        current.isGenerating) {
      return;
    }
    final version = _loadVersion;
    final weekKey = current.week.key;
    emit(current.withReport(generating: true));

    final saved = await _repository.readReport(weekKey);
    if (isClosed || version != _loadVersion) return;
    if (saved.isFailure || saved.dataOrNull != null) {
      emit(
        current.withReport(
          report: saved.dataOrNull,
          failure: saved.failureOrNull,
        ),
      );
      return;
    }

    final result = await _ai.generate(
      AiRequest(
        feature: AiFeature.weeklyInsight,
        payload: {
          'weekKey': weekKey,
          'stats': current.stats.reportNumbers(current.score ?? 0),
        },
      ),
    );
    if (isClosed || version != _loadVersion) return;
    final data = result.dataOrNull?.data;
    if (data == null) {
      emit(current.withReport(failure: result.failureOrNull));
      return;
    }
    final persisted = await _repository.readReport(weekKey);
    if (isClosed || version != _loadVersion) return;
    emit(
      current.withReport(
        report: persisted.dataOrNull,
        failure: persisted.dataOrNull == null
            ? persisted.failureOrNull ??
                  const AiFailure(
                    userMessage: 'The gateway did not save the weekly report. Please try again.',
                  )
            : null,
      ),
    );
  }
}
