import 'package:brainly_life/core/utils/date_key_utils.dart';
import 'package:brainly_life/features/study_planner/data/models/study_enums.dart';
import 'package:brainly_life/features/study_planner/data/models/subject_model.dart';
import 'package:brainly_life/features/study_planner/data/models/topic_model.dart';
import 'package:equatable/equatable.dart';

/// A subject with its progress and exam countdown. Used by the subjects list
/// and the subject detail page, so both always show the same numbers.
class SubjectOverview extends Equatable {
  const SubjectOverview({
    required this.subject,
    required this.topicCount,
    required this.doneTopicCount,
    required this.examDateKey,
    required this.daysUntilExam,
  });

  /// Builds the overview of [subject]. [topics] may contain topics of other
  /// subjects; they are ignored. [todayKey] and the exam day both come from
  /// `DateKeyUtils` in the user's [timezone].
  factory SubjectOverview.of(
    Subject subject,
    Iterable<Topic> topics, {
    required String todayKey,
    required String timezone,
  }) {
    final own = topics.where((t) => t.subjectId == subject.id);
    final examKey = DateKeyUtils.toDateKey(
      subject.examDate,
      timezone: timezone,
    );
    return SubjectOverview(
      subject: subject,
      topicCount: own.length,
      doneTopicCount: own.where((t) => t.status == TopicStatus.done).length,
      examDateKey: examKey,
      daysUntilExam: DateKeyUtils.daysBetween(todayKey, examKey),
    );
  }

  final Subject subject;

  /// All topics of the subject.
  final int topicCount;

  /// Topics with the status `done`.
  final int doneTopicCount;

  /// The exam day as `yyyy-MM-dd`, in the user's timezone.
  final String examDateKey;

  /// Days from today to the exam day.
  /// 0 means the exam is today, a negative number means it is over.
  final int daysUntilExam;

  /// From 0 to 1, for progress bars. 0 when there are no topics yet.
  double get progress => topicCount == 0 ? 0 : doneTopicCount / topicCount;

  bool get isExamOver => daysUntilExam < 0;

  @override
  List<Object?> get props => [
    subject,
    topicCount,
    doneTopicCount,
    examDateKey,
    daysUntilExam,
  ];
}
