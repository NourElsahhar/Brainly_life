import 'package:brainly_life/core/utils/date_key_utils.dart';
import 'package:brainly_life/features/study_planner/data/models/plan_constraints_model.dart';
import 'package:brainly_life/features/study_planner/data/models/study_enums.dart';
import 'package:brainly_life/features/study_planner/data/models/subject_model.dart';
import 'package:brainly_life/features/study_planner/data/models/topic_model.dart';
import 'package:brainly_life/features/study_planner/logic/local_time.dart';
import 'package:brainly_life/features/study_planner/logic/planner_types.dart';
import 'package:clock/clock.dart';

/// The `studyPlan` AI payload for a new plan, plus the plan period that the
/// validator needs afterwards.
class StudyPlanRequest {
  const StudyPlanRequest({
    required this.payload,
    required this.days,
    required this.subjects,
    required this.topics,
  });

  /// Goes to `AiRequest.payload` unchanged.
  final Map<String, Object?> payload;

  /// The days the AI may use, from today to the day before the last exam.
  final List<PlannerDay> days;

  /// The subjects and topics that were sent, to check the answer against.
  final List<Subject> subjects;
  final List<Topic> topics;
}

/// Builds the payload described by `payloadSchema` in
/// `functions/src/ai/features/studyPlan.ts` (mode "new").
///
/// Privacy (Master Document C.6): only ids, subject names, topic titles,
/// dates and numbers. No uid, name, email or photo.
///
/// Pure Dart: "now" comes from the injected [clock], days from
/// `DateKeyUtils` in the user's [timezone].
class StudyPlanPayloadBuilder {
  const StudyPlanPayloadBuilder({required this.clock, required this.timezone});

  /// Must match `promptVersion` in studyPlan.ts. Saved with the plan.
  static const int promptVersion = 1;

  /// Limits of studyPlan.ts (MAX_PLAN_DAYS, MAX_SUBJECTS, MAX_TOPICS).
  static const int maxPlanDays = 60;
  static const int maxSubjects = 20;
  static const int maxTopics = 150;
  static const int maxTopicMinutes = 200 * 60;
  static const int maxSubjectNameLength = 60;

  final Clock clock;
  final String timezone;

  String get todayKey =>
      DateKeyUtils.toDateKey(clock.now(), timezone: timezone);

  /// The exam day of [subject] in the user's timezone.
  String examDateKey(Subject subject) =>
      DateKeyUtils.toDateKey(subject.examDate, timezone: timezone);

  /// A plan needs at least one day before the exam, so the exam must be
  /// tomorrow or later.
  bool canPlan(Subject subject) =>
      DateKeyUtils.daysBetween(todayKey, examDateKey(subject)) >= 1;

  /// Minutes still to study for [topic]. 0 when it is done.
  static int remainingMinutes(Topic topic) {
    if (topic.status == TopicStatus.done) return 0;
    final left = topic.estimatedMinutes - topic.completedMinutes;
    return left.clamp(0, maxTopicMinutes);
  }

  /// Builds the request for [subjects] and their [topics].
  ///
  /// Subjects whose exam is today or over, finished topics and topics of
  /// other subjects are left out. Throws an [ArgumentError] when nothing
  /// is left to plan; the wizard checks that before.
  StudyPlanRequest buildNew({
    required List<Subject> subjects,
    required List<Topic> topics,
    required PlanConstraints constraints,
    double? previousCompletionRatio,
  }) {
    final today = todayKey;
    final plannable = subjects.where(canPlan).take(maxSubjects).toList();
    final subjectIds = {for (final s in plannable) s.id};
    final openTopics = topics
        .where((t) => subjectIds.contains(t.subjectId))
        .where((t) => remainingMinutes(t) > 0)
        .take(maxTopics)
        .toList();
    if (openTopics.isEmpty) {
      throw ArgumentError('No topics left to plan.');
    }
    // Only subjects that still have work.
    final usedSubjectIds = {for (final t in openTopics) t.subjectId};
    final usedSubjects = plannable
        .where((s) => usedSubjectIds.contains(s.id))
        .toList();

    // The plan ends the day before the last exam, at most 60 days.
    final lastExam = usedSubjects
        .map(examDateKey)
        .reduce((a, b) => a.compareTo(b) >= 0 ? a : b);
    var endDate = DateKeyUtils.addDays(lastExam, -1);
    final maxEnd = DateKeyUtils.addDays(today, maxPlanDays - 1);
    if (endDate.compareTo(maxEnd) > 0) endDate = maxEnd;

    final currentTime = LocalTime.formatTime(
      LocalTime.minuteOfDay(clock.now(), timezone: timezone),
    );

    final payload = <String, Object?>{
      'mode': 'new',
      'today': today,
      'currentTime': currentTime,
      'startDate': today,
      'endDate': endDate,
      'constraints': constraints.toFirestore(),
      'subjects': [
        for (final subject in usedSubjects)
          {
            'id': subject.id,
            'name': _shorten(subject.name.trim(), maxSubjectNameLength),
            'examDate': examDateKey(subject),
            'priority': _priorityName(subject.priority),
          },
      ],
      'topics': [
        for (final topic in openTopics)
          {
            'id': topic.id,
            'subjectId': topic.subjectId,
            'title': topic.title.trim(),
            'difficulty': topic.difficulty,
            'remainingMinutes': remainingMinutes(topic),
          },
      ],
      if (previousCompletionRatio != null)
        'completionRatio': previousCompletionRatio.clamp(0.0, 1.0),
    };

    return StudyPlanRequest(
      payload: payload,
      days: PlannerDay.range(today, endDate),
      subjects: usedSubjects,
      topics: openTopics,
    );
  }

  /// Subject.priority is 1, 2 or 3 (open team decision 3 in the README).
  static String _priorityName(int priority) => switch (priority) {
    <= 1 => 'low',
    2 => 'medium',
    _ => 'high',
  };

  static String _shorten(String text, int max) =>
      text.length <= max ? text : text.substring(0, max);
}
