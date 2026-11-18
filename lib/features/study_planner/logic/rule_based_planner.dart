import 'dart:math' as math;

import '../data/models/plan_constraints_model.dart';
import '../data/models/study_enums.dart';
import '../data/models/study_session_model.dart';
import '../data/models/topic_model.dart';
import 'planner_types.dart';

/// Builds a study plan from rules only, without AI.
///
/// It is used as the fallback when AI generation fails and as the engine of
/// the plan adjuster.
///
/// How it works:
///  1. Remaining minutes per topic = estimated - completed. Topics that are
///     done, or have nothing left, are ignored.
///  2. A subject's exam day itself is never used. The day before it is the
///     "buffer day": it stays free unless the work does not fit otherwise.
///  3. Days are filled from the earliest one. On each day, topics are taken in
///     rounds. In every round the topic with the highest
///     `difficulty / daysLeftUntilItsBufferDay` goes first, and gets one
///     session of at most `maxSessionMinutes`.
///  4. A day never gets more minutes than its daily limit.
///  5. Work that cannot fit is reported in [PlannerResult.unscheduledMinutes]
///     instead of being dropped silently.
///
/// It has no Flutter or Firebase imports and never reads the clock: the caller
/// passes the days (starting today) that it is allowed to use.
class RuleBasedPlanner {
  const RuleBasedPlanner();

  /// Shortest session the planner creates (same as the validator minimum).
  static const int minSessionMinutes = 10;

  /// Longest session allowed by the agreed rules.
  static const int maxSessionLimit = 180;

  /// [days] must be ascending, consecutive calendar days starting today.
  /// [examDateKeys] maps a subject id to the `yyyy-MM-dd` of its exam.
  PlannerResult plan({
    required String planId,
    required List<Topic> topics,
    required Map<String, String> examDateKeys,
    required PlanConstraints constraints,
    required List<PlannerDay> days,
    required String Function() newSessionId,
  }) {
    final maxSession = constraints.maxSessionMinutes
        .clamp(minSessionMinutes, maxSessionLimit)
        .toInt();
    final work = _buildWork(topics, examDateKeys, days);
    final capacityLeft = [
      for (final day in days) _capacityOf(day, constraints),
    ];
    final placements = List.generate(days.length, (_) => <_Placement>[]);

    // Pass 1 keeps every buffer day free. Pass 2 may use them for leftovers.
    for (final useBufferDays in [false, true]) {
      _fill(
        work: work,
        capacityLeft: capacityLeft,
        placements: placements,
        maxSession: maxSession,
        useBufferDays: useBufferDays,
      );
    }

    final breakMinutes = math.max(0, constraints.breakMinutes);
    final sessions = <StudySession>[];
    for (var dayIndex = 0; dayIndex < days.length; dayIndex++) {
      final day = days[dayIndex];
      var cursor = day.startAt;
      for (final placement in placements[dayIndex]) {
        sessions.add(
          StudySession(
            id: newSessionId(),
            planId: planId,
            subjectId: placement.topic.subjectId,
            topicId: placement.topic.id,
            dateKey: day.dateKey,
            startAt: cursor,
            plannedMinutes: placement.minutes,
          ),
        );
        cursor = cursor.add(
          Duration(minutes: placement.minutes + breakMinutes),
        );
      }
    }

    return PlannerResult(
      sessions: sessions,
      unscheduledMinutes: {
        for (final item in work)
          if (item.remaining > 0) item.topic.id: item.remaining,
      },
    );
  }

  List<_Work> _buildWork(
    List<Topic> topics,
    Map<String, String> examDateKeys,
    List<PlannerDay> days,
  ) {
    final work = <_Work>[];
    for (final topic in topics) {
      if (topic.status == TopicStatus.done) {
        continue;
      }
      final remaining = topic.estimatedMinutes - topic.completedMinutes;
      if (remaining <= 0) {
        continue;
      }
      work.add(
        _Work(
          topic,
          remaining,
          _bufferIndex(examDateKeys[topic.subjectId], days),
        ),
      );
    }
    return work;
  }

  /// Index of the last day strictly before the exam day, or null when there is
  /// no such day (exam today, in the past, or unknown).
  /// `yyyy-MM-dd` strings sort in date order, so comparing them is enough.
  int? _bufferIndex(String? examDateKey, List<PlannerDay> days) {
    if (examDateKey == null) {
      return null;
    }
    int? found;
    for (var i = 0; i < days.length; i++) {
      if (days[i].dateKey.compareTo(examDateKey) < 0) {
        found = i;
      } else {
        break;
      }
    }
    return found;
  }

  int _capacityOf(PlannerDay day, PlanConstraints constraints) {
    if (constraints.daysOff.contains(day.weekday)) {
      return 0;
    }
    return math.max(0, constraints.minutesPerWeekday[day.weekday] ?? 0);
  }

  void _fill({
    required List<_Work> work,
    required List<int> capacityLeft,
    required List<List<_Placement>> placements,
    required int maxSession,
    required bool useBufferDays,
  }) {
    for (var dayIndex = 0; dayIndex < capacityLeft.length; dayIndex++) {
      while (capacityLeft[dayIndex] >= minSessionMinutes) {
        final candidates =
            work
                .where(
                  (item) =>
                      item.isEligibleOn(dayIndex, useBufferDays: useBufferDays),
                )
                .toList()
              ..sort((a, b) => _compare(a, b, dayIndex, useBufferDays));
        if (candidates.isEmpty) {
          break;
        }

        var placedAny = false;
        for (final item in candidates) {
          final chunk = _chunkSize(
            remaining: item.remaining,
            capacityLeft: capacityLeft[dayIndex],
            maxSession: maxSession,
          );
          if (chunk == 0) {
            continue;
          }
          placements[dayIndex].add(_Placement(item.topic, chunk));
          capacityLeft[dayIndex] -= chunk;
          item.remaining = math.max(0, item.remaining - chunk);
          placedAny = true;
        }
        if (!placedAny) {
          break;
        }
      }
    }
  }

  /// Size of the next session, or 0 when nothing can be placed.
  /// A leftover below the minimum is rounded up to the minimum.
  int _chunkSize({
    required int remaining,
    required int capacityLeft,
    required int maxSession,
  }) {
    final chunk = math.min(math.min(remaining, maxSession), capacityLeft);
    if (chunk >= minSessionMinutes) {
      return chunk;
    }
    if (remaining < minSessionMinutes && capacityLeft >= minSessionMinutes) {
      return minSessionMinutes;
    }
    return 0;
  }

  int _compare(_Work a, _Work b, int dayIndex, bool useBufferDays) {
    final byScore = b
        .scoreOn(dayIndex, useBufferDays: useBufferDays)
        .compareTo(a.scoreOn(dayIndex, useBufferDays: useBufferDays));
    if (byScore != 0) {
      return byScore;
    }
    final byRemaining = b.remaining.compareTo(a.remaining);
    if (byRemaining != 0) {
      return byRemaining;
    }
    return a.topic.id.compareTo(b.topic.id);
  }
}

/// A topic with work left to schedule.
class _Work {
  _Work(this.topic, this.remaining, this.bufferIndex);

  final Topic topic;
  int remaining;

  /// Index of the buffer day of this topic's subject, null if unschedulable.
  final int? bufferIndex;

  bool isEligibleOn(int dayIndex, {required bool useBufferDays}) {
    final buffer = bufferIndex;
    if (remaining <= 0 || buffer == null) {
      return false;
    }
    return useBufferDays ? dayIndex <= buffer : dayIndex < buffer;
  }

  /// Harder topics and topics whose exam is closer get a higher score.
  /// Only called for eligible days, so `daysLeft` is at least 1.
  double scoreOn(int dayIndex, {required bool useBufferDays}) {
    final buffer = bufferIndex ?? dayIndex;
    final lastIndex = useBufferDays ? buffer : buffer - 1;
    final daysLeft = lastIndex - dayIndex + 1;
    return topic.difficulty / daysLeft;
  }
}

class _Placement {
  const _Placement(this.topic, this.minutes);

  final Topic topic;
  final int minutes;
}
