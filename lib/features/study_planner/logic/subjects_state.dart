import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/features/study_planner/data/models/subject_model.dart';
import 'package:equatable/equatable.dart';

/// Everything one card of the subjects list shows.
class SubjectOverview extends Equatable {
  const SubjectOverview({
    required this.subject,
    required this.topicCount,
    required this.examDateKey,
    required this.doneTopicCount,
    required this.daysUntilExam,
  });

  final Subject subject;

  /// All topics of the subject.
  final int topicCount;

  /// Topics with the status `done`.
  final int doneTopicCount;

  /// Days from today to the exam day, in the user's timezone.
  /// 0 means the exam is today, a negative number means it is over.
  final String examDateKey;
  final int daysUntilExam;

  /// From 0 to 1, for the progress bar. 0 when there are no topics yet.
  double get progress => topicCount == 0 ? 0 : doneTopicCount / topicCount;

  bool get isExamOver => daysUntilExam < 0;

  @override
  List<Object?> get props => [
    subject,
    topicCount,
    examDateKey,
    doneTopicCount,
    daysUntilExam,
  ];
}

sealed class SubjectsState extends Equatable {
  const SubjectsState();

  @override
  List<Object?> get props => [];
}

final class SubjectsInitial extends SubjectsState {
  const SubjectsInitial();
}

final class SubjectsLoading extends SubjectsState {
  const SubjectsLoading();
}

/// The user has no subjects: show "Add your first subject".
final class SubjectsEmpty extends SubjectsState {
  const SubjectsEmpty({this.deletedName});

  /// Set right after the last subject was deleted, for a snackbar.
  final String? deletedName;

  @override
  List<Object?> get props => [deletedName];
}

final class SubjectsLoaded extends SubjectsState {
  const SubjectsLoaded({
    required this.subjects,
    this.deletedName,
    this.actionFailure,
  });

  /// Ordered by exam date, soonest first.
  final List<SubjectOverview> subjects;

  /// Set right after a subject was deleted, for a snackbar.
  final String? deletedName;

  /// Set when deleting failed, for a snackbar. The list stays as it was.
  final Failure? actionFailure;

  @override
  List<Object?> get props => [subjects, deletedName, actionFailure];
}

/// Loading failed: show ErrorView with Retry.
final class SubjectsError extends SubjectsState {
  const SubjectsError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
