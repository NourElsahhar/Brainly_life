import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/core/utils/date_key_utils.dart';
import 'package:brainly_life/features/study_planner/data/models/subject_model.dart';
import 'package:brainly_life/features/study_planner/data/models/topic_model.dart';
import 'package:brainly_life/features/study_planner/data/repositories/study_repository.dart';
import 'package:brainly_life/features/study_planner/logic/subjects_state.dart';
import 'package:clock/clock.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Drives the subjects list: load the subjects with their progress, and
/// delete a subject (the screen asks for confirmation first).
///
/// [timezone] is the user's `settings.timezone`, used to count the days
/// until each exam with `DateKeyUtils`.
class SubjectsCubit extends Cubit<SubjectsState> {
  SubjectsCubit(
    this._repository, {
    required this._timezone,
    this._clock = const Clock(),
  }) : super(const SubjectsInitial());

  final StudyRepository _repository;
  final String _timezone;
  final Clock _clock;

  /// Loads the list. Call it again to retry, or after adding or editing a
  /// subject.
  Future<void> load() async {
    emit(const SubjectsLoading());
    await _loadList();
  }

  /// Deletes the subject with its topics and sessions.
  Future<void> deleteSubject(Subject subject) async {
    final result = await _repository.deleteSubject(subject.id);
    if (isClosed) return;
    switch (result) {
      case Success():
        await _loadList(deletedName: subject.name);
      case Failed(:final failure):
        _showActionFailure(failure);
    }
  }

  Future<void> _loadList({String? deletedName}) async {
    final subjectsResult = await _repository.getSubjects();
    final topicsResult = await _repository.getTopics();
    if (isClosed) return;

    final failure = subjectsResult.failureOrNull ?? topicsResult.failureOrNull;
    if (failure != null) {
      emit(SubjectsError(failure));
      return;
    }
    final subjects = subjectsResult.dataOrNull ?? const <Subject>[];
    final topics = topicsResult.dataOrNull ?? const <Topic>[];
    if (subjects.isEmpty) {
      emit(SubjectsEmpty(deletedName: deletedName));
      return;
    }

    final todayKey = DateKeyUtils.toDateKey(_clock.now(), timezone: _timezone);
    emit(
      SubjectsLoaded(
        subjects: [
          for (final subject in subjects)
            SubjectOverview.of(
              subject,
              topics,
              todayKey: todayKey,
              timezone: _timezone,
            ),
        ],
        deletedName: deletedName,
      ),
    );
  }

  /// Keeps the list and adds the failure, so the screen shows a snackbar.
  void _showActionFailure(Failure failure) {
    final current = state;
    if (current is! SubjectsLoaded) return;
    // Clear an older failure first, so the same failure twice still shows.
    emit(SubjectsLoaded(subjects: current.subjects));
    emit(SubjectsLoaded(subjects: current.subjects, actionFailure: failure));
  }
}
