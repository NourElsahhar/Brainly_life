import 'package:clock/clock.dart';

import '../../../core/utils/date_key_utils.dart';
import '../data/models/study_enums.dart';
import '../data/models/study_session_model.dart';
import '../data/models/topic_model.dart';

/// What is left of a plan after the user fell behind or changed their free
/// time (Master Document B.2, task 9).
///
/// It changes nothing by itself. The adjust flow sends the remaining work to
/// the AI (`studyPlan` feature, `adjust` mode), validates the new sessions
/// with `PlanValidator`, shows them in the preview, and only after the user
/// accepts it saves [missedSessions], deletes [removedSessionIds] and adds
/// the new sessions. When the AI fails, nothing is saved and the current plan
/// stays exactly as it was.
class PlanAdjustment {
  const PlanAdjustment({
    required this.missedSessions,
    required this.removedSessionIds,
    required this.bookedSessions,
    required this.remainingMinutesByTopic,
    required this.completionRatio,
  });

  /// Planned sessions that are already over, copied with the status
  /// `missed`. They stay in the plan as history.
  final List<StudySession> missedSessions;

  /// Planned sessions that have not started yet. The new AI sessions
  /// replace them.
  final List<String> removedSessionIds;

  /// Sessions that stay and still use time from today on: sessions done
  /// today and a session happening right now. Pass them to `PlanValidator`
  /// as `existingSessions`; their minutes are [bookedMinutesByDate].
  final List<StudySession> bookedSessions;

  /// Minutes still to study, by topic id. Only topics of this plan with work
  /// left are included. This is `remainingMinutes` in the AI payload.
  final Map<String, int> remainingMinutesByTopic;

  /// Share of the work that was due and got done, from 0 to 1.
  final double completionRatio;

  bool get hasRemainingWork => remainingMinutesByTopic.isNotEmpty;

  /// Minutes per day already used by [bookedSessions]
  /// (`bookedMinutesByDate` in the AI payload).
  Map<String, int> get bookedMinutesByDate {
    final minutes = <String, int>{};
    for (final session in bookedSessions) {
      minutes[session.dateKey] =
          (minutes[session.dateKey] ?? 0) + session.plannedMinutes;
    }
    return minutes;
  }
}

/// Works out what an adjustment has to re-plan. The AI does the planning;
/// there is no rule-based planner (Master Document v1.1).
///
/// For every session of the plan:
/// 1. A planned session that is already over becomes `missed`.
/// 2. A planned session that has not started yet is removed.
/// 3. A planned session happening right now stays, and so does a session
///    done today: both are "booked" time.
/// 4. Older done, skipped and missed sessions are history and stay untouched.
///
/// The remaining work of a topic is `estimatedMinutes - completedMinutes`,
/// minus the session happening right now. So the minutes of missed sessions
/// are naturally part of it. Only topics used by the plan's sessions count.
///
/// [PlanAdjustment.completionRatio] is done minutes / (done + missed +
/// skipped minutes), or 1 when nothing was due yet.
///
/// Pure Dart: "now" comes from the injected [clock], and "today" comes from
/// `DateKeyUtils` with the user's [timezone].
class PlanAdjuster {
  const PlanAdjuster({required this.clock, required this.timezone});

  final Clock clock;

  /// The user's IANA timezone (`settings.timezone`), e.g. 'Africa/Cairo'.
  final String timezone;

  /// [sessions] are all the sessions of the plan. [topics] may contain
  /// topics outside the plan; they are ignored.
  PlanAdjustment adjust({
    required List<StudySession> sessions,
    required List<Topic> topics,
  }) {
    final now = clock.now();
    final todayKey = DateKeyUtils.toDateKey(now, timezone: timezone);
    final missed = <StudySession>[];
    final removedIds = <String>[];
    final booked = <StudySession>[];
    final runningMinutesByTopic = <String, int>{};
    var doneMinutes = 0;
    var notDoneMinutes = 0;

    for (final session in sessions) {
      final minutes = session.plannedMinutes;
      switch (session.status) {
        case SessionStatus.done:
          doneMinutes += minutes;
          if (session.dateKey.compareTo(todayKey) >= 0) {
            booked.add(session);
          }
        case SessionStatus.skipped || SessionStatus.missed:
          notDoneMinutes += minutes;
        case SessionStatus.planned:
          final end = session.startAt.add(Duration(minutes: minutes));
          if (!end.isAfter(now)) {
            missed.add(session.copyWith(status: SessionStatus.missed));
            notDoneMinutes += minutes;
          } else if (!session.startAt.isBefore(now)) {
            removedIds.add(session.id);
          } else {
            // Happening right now: leave it alone.
            booked.add(session);
            runningMinutesByTopic[session.topicId] =
                (runningMinutesByTopic[session.topicId] ?? 0) + minutes;
          }
      }
    }

    final planTopicIds = {for (final session in sessions) session.topicId};
    final remaining = <String, int>{};
    for (final topic in topics) {
      final inPlan = planTopicIds.contains(topic.id);
      if (!inPlan || topic.status == TopicStatus.done) {
        continue;
      }
      final left =
          topic.estimatedMinutes -
          topic.completedMinutes -
          (runningMinutesByTopic[topic.id] ?? 0);
      if (left > 0) {
        remaining[topic.id] = left;
      }
    }

    final dueMinutes = doneMinutes + notDoneMinutes;
    return PlanAdjustment(
      missedSessions: missed,
      removedSessionIds: removedIds,
      bookedSessions: booked,
      remainingMinutesByTopic: remaining,
      completionRatio: dueMinutes == 0 ? 1.0 : doneMinutes / dueMinutes,
    );
  }
}
