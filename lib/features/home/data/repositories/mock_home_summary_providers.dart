// Fake Home summary providers that return fixed sample data.
// Home uses them until each owner registers the real provider,
// and any feature can use them in tests.

import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/home/data/repositories/home_summary_port.dart';
import 'package:clock/clock.dart';

class MockTaskSummaryProvider implements TaskSummaryProvider {
  MockTaskSummaryProvider({
    this.summary = const TaskSummary(
      dueTodayCount: 3,
      overdueCount: 1,
      completedTodayCount: 2,
      nextTaskTitle: 'Email the supervisor',
    ),
    this.failWith,
  });

  final TaskSummary summary;

  /// When set, the provider returns this failure instead of the summary.
  Failure? failWith;

  @override
  Future<Result<TaskSummary>> todaySummary() async =>
      _answer(summary, failWith);
}

class MockStudySummaryProvider implements StudySummaryProvider {
  /// A null [session] means "no planned session".
  MockStudySummaryProvider({this.session, this.failWith});

  /// A provider whose next session starts in 2 hours.
  factory MockStudySummaryProvider.withSampleData() {
    return MockStudySummaryProvider(
      session: StudySummary(
        sessionId: 'sample_session',
        subjectName: 'Mathematics',
        topicTitle: 'Differential equations',
        startAt: clock.now().toUtc().add(const Duration(hours: 2)),
        plannedMinutes: 45,
      ),
    );
  }

  final StudySummary? session;

  Failure? failWith;

  @override
  Future<Result<StudySummary?>> nextSession() async =>
      _answer(session, failWith);
}

class MockHabitSummaryProvider implements HabitSummaryProvider {
  MockHabitSummaryProvider({
    this.summary = const HabitSummary(
      doneTodayCount: 1,
      dueTodayCount: 3,
      bestCurrentStreak: 5,
      bestStreakHabitName: 'Read 20 pages',
    ),
    this.failWith,
  });

  final HabitSummary summary;

  Failure? failWith;

  @override
  Future<Result<HabitSummary>> todaySummary() async =>
      _answer(summary, failWith);
}

class MockFocusSummaryProvider implements FocusSummaryProvider {
  MockFocusSummaryProvider({
    this.summary = const FocusSummary(minutesToday: 50, sessionsToday: 2),
    this.failWith,
  });

  final FocusSummary summary;

  Failure? failWith;

  @override
  Future<Result<FocusSummary>> todaySummary() async =>
      _answer(summary, failWith);
}

class MockAiTipProvider implements AiTipProvider {
  MockAiTipProvider({
    this.tip = 'Start with the hardest task while your energy is high.',
    this.failWith,
  });

  final String tip;

  Failure? failWith;

  @override
  Future<Result<String>> dailyTip() async => _answer(tip, failWith);
}

/// Returns [failure] when it is set, otherwise [value].
Result<T> _answer<T>(T value, Failure? failure) {
  if (failure != null) return Result.failure(failure);
  return Result.success(value);
}
