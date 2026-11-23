import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/features/study_planner/data/models/topic_model.dart';
import 'package:brainly_life/features/study_planner/logic/subject_overview.dart';
import 'package:equatable/equatable.dart';

sealed class SubjectDetailState extends Equatable {
  const SubjectDetailState();

  @override
  List<Object?> get props => [];
}

final class SubjectDetailLoading extends SubjectDetailState {
  const SubjectDetailLoading();
}

/// The subject with its topics, sorted by title.
final class SubjectDetailLoaded extends SubjectDetailState {
  const SubjectDetailLoaded({
    required this.overview,
    required this.topics,
    this.deletedTopicTitle,
    this.actionFailure,
  });

  final SubjectOverview overview;
  final List<Topic> topics;

  /// Set once after a topic is deleted, so the screen shows a snackbar.
  final String? deletedTopicTitle;

  /// Set when deleting failed. The page stays as it was.
  final Failure? actionFailure;

  @override
  List<Object?> get props => [
    overview,
    topics,
    deletedTopicTitle,
    actionFailure,
  ];
}

/// The subject does not exist any more (for example, deleted on another
/// device). The screen shows a message and a way back.
final class SubjectDetailNotFound extends SubjectDetailState {
  const SubjectDetailNotFound();
}

/// Loading failed. The screen shows the error with a retry button.
final class SubjectDetailError extends SubjectDetailState {
  const SubjectDetailError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

/// The subject was deleted. The screen goes back to the subjects list.
final class SubjectDetailDeleted extends SubjectDetailState {
  const SubjectDetailDeleted(this.subjectName);

  final String subjectName;

  @override
  List<Object?> get props => [subjectName];
}
