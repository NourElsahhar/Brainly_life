import 'package:brainly_life/core/errors/failure.dart';
import 'package:equatable/equatable.dart';

enum SubjectFormStatus {
  /// Loading the subject to edit.
  loading,

  /// The user is filling the form.
  editing,

  /// Saving. Disable the Save button.
  saving,

  /// Saved. Close the screen.
  saved,

  /// The subject to edit does not exist anymore.
  notFound,

  /// The subject to edit could not load. Show Retry.
  loadFailed,
}

/// Everything the new / edit subject screen shows.
class SubjectFormState extends Equatable {
  const SubjectFormState({
    required this.status,
    required this.isEdit,
    this.name = '',
    this.colorValue,
    this.examDateKey,
    this.priority = SubjectPriority.medium,
    this.nameError,
    this.examDateError,
    this.failure,
  });

  final SubjectFormStatus status;

  /// true for "Edit subject", false for "New subject".
  final bool isEdit;

  final String name;
  final int? colorValue;

  /// The exam day as `yyyy-MM-dd`, or null before the user picks one.
  final String? examDateKey;

  /// 1 = low, 2 = medium, 3 = high (see [SubjectPriority]).
  final int priority;

  /// Shown under the fields, only after the user taps Save once.
  final String? nameError;
  final String? examDateError;

  /// Loading or saving failed. Show `userMessage` in a snackbar.
  final Failure? failure;

  @override
  List<Object?> get props => [
    status,
    isEdit,
    name,
    colorValue,
    examDateKey,
    priority,
    nameError,
    examDateError,
    failure,
  ];
}

/// How `Subject.priority` is stored (open team decision 3 in the README).
abstract final class SubjectPriority {
  static const int low = 1;
  static const int medium = 2;
  static const int high = 3;
}
