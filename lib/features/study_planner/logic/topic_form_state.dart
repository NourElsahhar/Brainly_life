import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/features/study_planner/data/models/study_enums.dart';
import 'package:equatable/equatable.dart';

enum TopicFormStatus {
  /// Loading the topic to edit.
  loading,

  /// The user is filling the form.
  editing,

  /// Saving or deleting. Disable the buttons.
  saving,

  /// Saved. Close the screen with [TopicFormResult.saved].
  saved,

  /// Deleted. Close the screen with [TopicFormResult.deleted].
  deleted,

  /// The topic to edit does not exist anymore.
  notFound,

  /// The topic to edit could not load. Show Retry.
  loadFailed,
}

/// What the topic form screen closes with, so the subject page can show
/// the right message.
enum TopicFormResult { saved, deleted }

/// Everything the new / edit topic screen shows.
class TopicFormState extends Equatable {
  const TopicFormState({
    required this.status,
    required this.isEdit,
    this.title = '',
    this.difficulty,
    this.hoursText = '',
    this.topicStatus = TopicStatus.notStarted,
    this.titleError,
    this.difficultyError,
    this.hoursError,
    this.failure,
  });

  final TopicFormStatus status;

  /// true for "Edit topic", false for "New topic".
  final bool isEdit;

  final String title;

  /// 1 (easy) to 5 (hard). null until the user picks one.
  final int? difficulty;

  /// The estimated hours as the user typed them, e.g. "1.5".
  final String hoursText;

  final TopicStatus topicStatus;

  /// Shown under the fields, only after the user taps Save once.
  final String? titleError;
  final String? difficultyError;
  final String? hoursError;

  /// Loading, saving or deleting failed. Show `userMessage` in a snackbar.
  final Failure? failure;

  @override
  List<Object?> get props => [
    status,
    isEdit,
    title,
    difficulty,
    hoursText,
    topicStatus,
    titleError,
    difficultyError,
    hoursError,
    failure,
  ];
}
