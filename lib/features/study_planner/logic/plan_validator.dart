import 'package:clock/clock.dart';

import '../data/models/plan_constraints_model.dart';
import '../data/models/study_enums.dart';
import '../data/models/study_session_model.dart';
import '../data/models/topic_model.dart';
import 'planner_types.dart';
import 'rule_based_planner.dart';

/// The kinds of problem the validator can find in a plan.
enum PlanViolationType {
  /// A planned session starts before "now".
  sessionInPast,

  /// The session's day is not one of the days the plan may use.
  dateOutsidePlanDays,

  /// The session is on a weekday the user marked as a day off.
  dayOff,

  /// The sessions of one day add up to more than that weekday's limit.
  dailyLimitExceeded,

  /// Two sessions overlap in time.
  overlappingSessions,

  /// The session points to a subject that does not exist.
  unknownSubject,

  /// The session points to a topic that does not exist.
  unknownTopic,

  /// The topic exists but belongs to a different subject.
  topicSubjectMismatch,

  /// Duration is not between 10 and 180 minutes.
  durationOutOfRange,

  /// Duration is longer than the user's `maxSessionMinutes`.
  exceedsMaxSession,

  /// The session is after the exam day of its subject.
  afterExamDay,
}

/// One problem found in a plan.
///
/// [sessionId] is null for problems about a whole day, in which case
/// [dateKey] says which day.
class PlanViolation {
  const PlanViolation(this.type, {this.sessionId, this.dateKey});

  final PlanViolationType type;
  final String? sessionId;
  final String? dateKey;
}

class PlanValidationResult {
  const PlanValidationResult(this.violations);

  final List<PlanViolation> violations;

  bool get isValid => violations.isEmpty;

  Set<PlanViolationType> get types => {for (final v in violations) v.type};
}

/// Checks any plan, made by the rules or by the AI, before it is saved.
///
/// It reports every problem it finds, not just the first one. It is pure Dart
/// and reads the time only from the injected [Clock].
class PlanValidator {
  const PlanValidator({required this.clock});

  /// The only source of "now" for this class (injected, so tests can fix it).
  final Clock clock;

  /// [days] are the days the plan may use (the same list the planner gets).
  /// [examDateKeys] maps a subject id to the `yyyy-MM-dd` of its exam.
  PlanValidationResult validate({
    required List<StudySession> sessions,
    required Set<String> subjectIds,
    required List<Topic> topics,
    required Map<String, String> examDateKeys,
    required PlanConstraints constraints,
    required List<PlannerDay> days,
  }) {
    final violations = <PlanViolation>[];
    final now = clock.now();
    final weekdayByDateKey = {for (final day in days) day.dateKey: day.weekday};
    final topicById = {for (final topic in topics) topic.id: topic};

    for (final session in sessions) {
      void report(PlanViolationType type) {
        violations.add(PlanViolation(type, sessionId: session.id));
      }

      final minutes = session.plannedMinutes;
      if (minutes < RuleBasedPlanner.minSessionMinutes ||
          minutes > RuleBasedPlanner.maxSessionLimit) {
        report(PlanViolationType.durationOutOfRange);
      }
      if (minutes > constraints.maxSessionMinutes) {
        report(PlanViolationType.exceedsMaxSession);
      }
      if (session.status == SessionStatus.planned &&
          session.startAt.isBefore(now)) {
        report(PlanViolationType.sessionInPast);
      }

      if (!subjectIds.contains(session.subjectId)) {
        report(PlanViolationType.unknownSubject);
      }
      final topic = topicById[session.topicId];
      if (topic == null) {
        report(PlanViolationType.unknownTopic);
      } else if (topic.subjectId != session.subjectId) {
        report(PlanViolationType.topicSubjectMismatch);
      }

      // `yyyy-MM-dd` strings sort in date order, so comparing is enough.
      final examDateKey = examDateKeys[session.subjectId];
      if (examDateKey != null && session.dateKey.compareTo(examDateKey) > 0) {
        report(PlanViolationType.afterExamDay);
      }

      final weekday = weekdayByDateKey[session.dateKey];
      if (weekday == null) {
        report(PlanViolationType.dateOutsidePlanDays);
      } else if (constraints.daysOff.contains(weekday)) {
        report(PlanViolationType.dayOff);
      }
    }

    _checkDailyLimits(sessions, weekdayByDateKey, constraints, violations);
    _checkOverlaps(sessions, violations);

    return PlanValidationResult(violations);
  }

  void _checkDailyLimits(
    List<StudySession> sessions,
    Map<String, int> weekdayByDateKey,
    PlanConstraints constraints,
    List<PlanViolation> violations,
  ) {
    final minutesByDay = <String, int>{};
    for (final session in sessions) {
      if (weekdayByDateKey.containsKey(session.dateKey)) {
        minutesByDay[session.dateKey] =
            (minutesByDay[session.dateKey] ?? 0) + session.plannedMinutes;
      }
    }
    for (final entry in minutesByDay.entries) {
      final weekday = weekdayByDateKey[entry.key];
      // Sessions on a day off are already reported as dayOff.
      if (weekday == null || constraints.daysOff.contains(weekday)) {
        continue;
      }
      final limit = constraints.minutesPerWeekday[weekday] ?? 0;
      if (entry.value > limit) {
        violations.add(
          PlanViolation(
            PlanViolationType.dailyLimitExceeded,
            dateKey: entry.key,
          ),
        );
      }
    }
  }

  void _checkOverlaps(
    List<StudySession> sessions,
    List<PlanViolation> violations,
  ) {
    final ordered = [...sessions]
      ..sort((a, b) {
        final byStart = a.startAt.compareTo(b.startAt);
        return byStart != 0 ? byStart : a.id.compareTo(b.id);
      });

    DateTime? latestEnd;
    for (final session in ordered) {
      final end = session.startAt.add(
        Duration(minutes: session.plannedMinutes),
      );
      final previousEnd = latestEnd;
      if (previousEnd != null && session.startAt.isBefore(previousEnd)) {
        violations.add(
          PlanViolation(
            PlanViolationType.overlappingSessions,
            sessionId: session.id,
          ),
        );
      }
      if (previousEnd == null || end.isAfter(previousEnd)) {
        latestEnd = end;
      }
    }
  }
}
