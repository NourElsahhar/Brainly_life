import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/features/study_planner/logic/subject_overview.dart';
import 'package:equatable/equatable.dart';

// The screens that use SubjectsState also need SubjectOverview.
export 'package:brainly_life/features/study_planner/logic/subject_overview.dart';

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
