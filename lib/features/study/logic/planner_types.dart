import '../data/models/study_session_model.dart';

/// One calendar day that the planner is allowed to use.
///
/// The planner never calculates dates itself. The caller builds the list of
/// days with `DateKeyUtils` (user timezone, Master Document E.8) and hands it
/// over, so this file and the planner stay pure and easy to test.
class PlannerDay {
  const PlannerDay({
    required this.dateKey,
    required this.weekday,
    required this.startAt,
  });

  /// `yyyy-MM-dd` in the user's timezone.
  final String dateKey;

  /// 1 = Monday ... 7 = Sunday.
  final int weekday;

  /// UTC moment at which the first session of this day starts.
  final DateTime startAt;
}

/// What the planner produced.
class PlannerResult {
  const PlannerResult({
    required this.sessions,
    required this.unscheduledMinutes,
  });

  /// Planned sessions ordered by day.
  final List<StudySession> sessions;

  /// Minutes that did not fit before the exams, keyed by topic id.
  /// Empty when the whole workload was scheduled.
  final Map<String, int> unscheduledMinutes;

  bool get isComplete => unscheduledMinutes.isEmpty;
}
