// Tests for DefaultFocusSummaryProvider: today's focus minutes and blocks
// (breaks and other days are ignored), the empty state, and a failure.

import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/focus/data/models/focus_session_model.dart';
import 'package:brainly_life/features/focus/data/repositories/focus_summary_provider.dart';
import 'package:brainly_life/features/focus/data/repositories/mock_focus_repository.dart';
import 'package:brainly_life/features/home/data/repositories/home_summary_port.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingRepository extends MockFocusRepository {
  @override
  Future<Result<List<FocusSession>>> getSessions({
    required String fromDate,
    required String toDate,
  }) async => const Result.failure(NetworkFailure());
}

void main() {
  final today = Clock.fixed(DateTime.utc(2026, 11, 16, 10));

  FocusSession session(
    String id,
    String dateKey,
    int minutes, {
    FocusSessionType type = FocusSessionType.focus,
  }) {
    final start = DateTime.utc(2026, 11, int.parse(dateKey.substring(8)), 9);
    return FocusSession(
      id: id,
      type: type,
      startedAt: start,
      endedAt: start.add(Duration(minutes: minutes)),
      plannedMinutes: 25,
      actualMinutes: minutes,
      completed: true,
      dateKey: dateKey,
      createdAt: start,
      updatedAt: start,
    );
  }

  Future<Result<FocusSummary>> summaryFor(MockFocusRepository repository) {
    return withClock(
      today,
      () => DefaultFocusSummaryProvider(
        repository: repository,
        timezone: () => 'UTC',
      ).todaySummary(),
    );
  }

  test('sums only the focus blocks of today', () async {
    final repository = MockFocusRepository(
      sessions: [
        session('a', '2026-11-16', 25),
        session('b', '2026-11-16', 10),
        session('c', '2026-11-16', 5, type: FocusSessionType.shortBreak),
        session('d', '2026-11-15', 25),
      ],
    );

    final result = await summaryFor(repository);
    expect(
      result.dataOrNull,
      const FocusSummary(minutesToday: 35, sessionsToday: 2),
    );
  });

  test('no sessions today gives an empty summary', () async {
    final result = await summaryFor(MockFocusRepository());
    expect(result.dataOrNull!.isEmpty, isTrue);
    expect(result.dataOrNull!.minutesToday, 0);
  });

  test('a failing repository returns the failure', () async {
    final result = await summaryFor(_FailingRepository());
    expect(result.failureOrNull, const NetworkFailure());
  });
}
