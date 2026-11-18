import 'package:clock/clock.dart';

import '../data/models/plan_constraints_model.dart';
import '../data/models/study_enums.dart';
import '../data/models/study_session_model.dart';
import '../data/models/topic_model.dart';
import 'planner_types.dart';
import 'rule_based_planner.dart';

/// What the adjuster decided. It changes nothing by itself: the caller saves
/// it (and cancels the reminders `study_<id>` of every missed and removed
/// session).
class AdjustmentResult {
  const AdjustmentResult({
    required this.missedSessions,
    required this.removedSessionIds,
    required this.newSessions,
    required this.unscheduledMinutes,
  });

  /// Planned sessions whose time is over, already copied with the status
  /// `missed`. They stay in the plan as history.
  final List<StudySession> missedSessions;

  /// Planned sessions that had not started yet. They are replaced by
  /// [newSessions].
  final List<String> removedSessionIds;

  /// The re-planned sessions for all remaining work.
  final List<StudySession> newSessions;

  /// Minutes that still do not fit before the exams, keyed by topic id.
  final Map<String, int> unscheduledMinutes;

  bool get isComplete => unscheduledMinutes.isEmpty;
}

/// Repairs a plan when the user fell behind or the available time changed.
///
/// 1. A planned session that is already over becomes `missed`.
/// 2. A planned session that has not started yet is removed.
/// 3. All the work that is still left is planned again over [days] with the
///    same [RuleBasedPlanner].
///
/// Left alone: finished, skipped and already missed sessions, and a planned
/// session that is happening right now. The remaining work comes from each
/// topic (`estimatedMinutes - completedMinutes`), so the minutes of missed
/// sessions are naturally planned again.
///
/// Pure Dart: "now" comes from the injected [clock].
class PlanAdjuster {
  const PlanAdjuster({
    required this.clock,
    this.planner = const RuleBasedPlanner(),
  });

  final Clock clock;
  final RuleBasedPlanner planner;

  /// [sessions] are all the sessions of the plan. [days] must start today and
  /// the first day must not start before "now" (see [PlannerDay]).
  AdjustmentResult adjust({
    required String planId,
    required List<StudySession> sessions,
    required List<Topic> topics,
    required Map<String, String> examDateKeys,
    required PlanConstraints constraints,
    required List<PlannerDay> days,
    required String Function() newSessionId,
  }) {
    final now = clock.now();
    final missed = <StudySession>[];
    final removedIds = <String>[];

    for (final session in sessions) {
      if (session.status != SessionStatus.planned) {
        continue;
      }
      final end = session.startAt.add(
        Duration(minutes: session.plannedMinutes),
      );
      if (!end.isAfter(now)) {
        missed.add(session.copyWith(status: SessionStatus.missed));
      } else if (!session.startAt.isBefore(now)) {
        removedIds.add(session.id);
      }
      // Otherwise the session is happening right now: leave it alone.
    }

    final replanned = planner.plan(
      planId: planId,
      topics: topics,
      examDateKeys: examDateKeys,
      constraints: constraints,
      days: days,
      newSessionId: newSessionId,
    );

    return AdjustmentResult(
      missedSessions: missed,
      removedSessionIds: removedIds,
      newSessions: replanned.sessions,
      unscheduledMinutes: replanned.unscheduledMinutes,
    );
  }
}
