import '../../../../core/utils/date_key_utils.dart';
import '../models/plan_constraints_model.dart';
import '../models/study_enums.dart';
import '../models/study_plan_model.dart';
import '../models/study_session_model.dart';
import '../models/subject_model.dart';
import '../models/topic_model.dart';

/// Sample data for [MockStudyRepository], also used by the Home dashboard and
/// Analytics while the real data does not exist yet.
///
/// Everything is built relative to [now], so the data always looks current:
/// two sessions today, two tomorrow, history from the last two days.
/// All days come from `DateKeyUtils`; nothing here calculates days itself.
class StudySampleData {
  StudySampleData._({
    required this.subjects,
    required this.topics,
    required this.plan,
    required this.sessions,
  });

  factory StudySampleData.build({
    required DateTime now,
    required String timezone,
  }) {
    final today = DateKeyUtils.toDateKey(now, timezone: timezone);
    String day(int offset) => DateKeyUtils.addDays(today, offset);
    DateTime at(String dateKey, int hour, [int minute = 0]) {
      final start = DateKeyUtils.dayBounds(dateKey, timezone: timezone).start;
      return start.add(Duration(hours: hour, minutes: minute));
    }

    Subject subject(String id, String name, int color, int examIn, int prio) {
      return Subject(
        id: id,
        name: name,
        colorValue: color,
        examDate: at(day(examIn), 9),
        priority: prio,
        createdAt: now,
        updatedAt: now,
      );
    }

    Topic topic(
      String id,
      String subjectId,
      String title,
      int difficulty,
      int estimated,
      TopicStatus status,
      int completed,
    ) {
      return Topic(
        id: id,
        subjectId: subjectId,
        title: title,
        difficulty: difficulty,
        estimatedMinutes: estimated,
        status: status,
        completedMinutes: completed,
        createdAt: now,
        updatedAt: now,
      );
    }

    StudySession session(
      String id,
      String subjectId,
      String topicId,
      int dayOffset,
      int hour, {
      int minute = 0,
      int minutes = 60,
      SessionStatus status = SessionStatus.planned,
      int actual = 0,
    }) {
      final dateKey = day(dayOffset);
      return StudySession(
        id: id,
        planId: 'plan_sample',
        subjectId: subjectId,
        topicId: topicId,
        dateKey: dateKey,
        startAt: at(dateKey, hour, minute),
        plannedMinutes: minutes,
        actualMinutes: actual,
        status: status,
        createdAt: now,
        updatedAt: now,
      );
    }

    return StudySampleData._(
      subjects: [
        subject('subject_os', 'Operating Systems', 0xFF3F51B5, 10, 1),
        subject('subject_db', 'Databases', 0xFF009688, 14, 2),
        subject('subject_la', 'Linear Algebra', 0xFFFF9800, 21, 3),
      ],
      topics: [
        topic(
          'topic_os_deadlocks',
          'subject_os',
          'Deadlocks',
          4,
          180,
          TopicStatus.inProgress,
          60,
        ),
        topic(
          'topic_os_scheduling',
          'subject_os',
          'CPU scheduling',
          3,
          120,
          TopicStatus.done,
          120,
        ),
        topic(
          'topic_os_memory',
          'subject_os',
          'Memory management',
          5,
          240,
          TopicStatus.notStarted,
          0,
        ),
        topic(
          'topic_db_normalization',
          'subject_db',
          'Normalization',
          3,
          120,
          TopicStatus.notStarted,
          0,
        ),
        topic(
          'topic_db_joins',
          'subject_db',
          'SQL joins',
          2,
          90,
          TopicStatus.inProgress,
          30,
        ),
        topic(
          'topic_db_transactions',
          'subject_db',
          'Transactions',
          4,
          150,
          TopicStatus.notStarted,
          0,
        ),
        topic(
          'topic_la_eigen',
          'subject_la',
          'Eigenvalues',
          5,
          240,
          TopicStatus.notStarted,
          0,
        ),
        topic(
          'topic_la_matrices',
          'subject_la',
          'Matrix operations',
          2,
          90,
          TopicStatus.done,
          90,
        ),
      ],
      plan: StudyPlan(
        id: 'plan_sample',
        title: 'Midterms preparation',
        startDate: at(day(-2), 0),
        endDate: at(day(9), 0),
        generatedBy: PlanGenerator.rules,
        constraints: PlanConstraints(
          minutesPerWeekday: {for (var d = 1; d <= 7; d++) d: 120},
          daysOff: {5},
          maxSessionMinutes: 60,
          breakMinutes: 10,
        ),
        createdAt: now,
        updatedAt: now,
      ),
      sessions: [
        session(
          'session_skipped',
          'subject_la',
          'topic_la_eigen',
          -2,
          17,
          status: SessionStatus.skipped,
        ),
        session(
          'session_done',
          'subject_os',
          'topic_os_deadlocks',
          -1,
          17,
          status: SessionStatus.done,
          actual: 55,
        ),
        session(
          'session_missed',
          'subject_db',
          'topic_db_joins',
          -1,
          18,
          minute: 10,
          minutes: 45,
          status: SessionStatus.missed,
        ),
        session('session_today_1', 'subject_os', 'topic_os_deadlocks', 0, 17),
        session(
          'session_today_2',
          'subject_db',
          'topic_db_normalization',
          0,
          18,
          minute: 10,
          minutes: 45,
        ),
        session('session_tomorrow_1', 'subject_os', 'topic_os_memory', 1, 17),
        session(
          'session_tomorrow_2',
          'subject_la',
          'topic_la_eigen',
          1,
          18,
          minute: 10,
        ),
        session('session_day2', 'subject_db', 'topic_db_transactions', 2, 17),
      ],
    );
  }

  final List<Subject> subjects;
  final List<Topic> topics;
  final StudyPlan plan;
  final List<StudySession> sessions;
}
