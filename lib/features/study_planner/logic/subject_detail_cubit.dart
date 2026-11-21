import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/core/utils/date_key_utils.dart';
import 'package:brainly_life/features/study_planner/data/models/subject_model.dart';
import 'package:brainly_life/features/study_planner/data/models/topic_model.dart';
import 'package:brainly_life/features/study_planner/data/repositories/study_repository.dart';
import 'package:brainly_life/features/study_planner/logic/subject_detail_state.dart';
import 'package:brainly_life/features/study_planner/logic/subject_overview.dart';
import 'package:clock/clock.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Drives the subject detail page: the subject header with its progress,
/// the list of its topics, deleting a topic and deleting the subject.
///
/// [timezone] is the user's `settings.timezone`, used to count the days
/// until the exam with `DateKeyUtils`.
class SubjectDetailCubit extends Cubit<SubjectDetailState> {
  SubjectDetailCubit(
    this._repository, {
    required this._timezone,
    this._clock = const Clock(),
  }) : super(const SubjectDetailLoading());

  final StudyRepository _repository;
  final String _timezone;
  final Clock _clock;

  String? _subjectId;

  /// Loads the subject [subjectId]. Call [reload] to retry or to refresh
  /// after adding or editing a topic or the subject.
  Future<void> load(String subjectId) async {
    _subjectId = subjectId;
    emit(const SubjectDetailLoading());
    await _loadPage();
  }

  Future<void> reload() async {
    if (_subjectId == null) return;
    emit(const SubjectDetailLoading());
    await _loadPage();
  }

  /// Deletes [topic] and its study sessions.
  Future<void> deleteTopic(Topic topic) async {
    final result = await _repository.deleteTopic(topic.id);
    if (isClosed) return;
    switch (result) {
      case Success():
        await _loadPage(deletedTopicTitle: topic.title);
      case Failed(:final failure):
        _showActionFailure(failure);
    }
  }

  /// Deletes the subject with all its topics and sessions.
  Future<void> deleteSubject() async {
    final current = state;
    if (current is! SubjectDetailLoaded) return;
    final subject = current.overview.subject;
    final result = await _repository.deleteSubject(subject.id);
    if (isClosed) return;
    switch (result) {
      case Success():
        emit(SubjectDetailDeleted(subject.name));
      case Failed(:final failure):
        _showActionFailure(failure);
    }
  }

  Future<void> _loadPage({String? deletedTopicTitle}) async {
    final subjectId = _subjectId;
    if (subjectId == null) return;

    final subjectsResult = await _repository.getSubjects();
    final topicsResult = await _repository.getTopics(subjectId: subjectId);
    if (isClosed) return;

    final failure = subjectsResult.failureOrNull ?? topicsResult.failureOrNull;
    if (failure != null) {
      emit(SubjectDetailError(failure));
      return;
    }
    final subjects = subjectsResult.dataOrNull ?? const <Subject>[];
    final subject = subjects.where((s) => s.id == subjectId).firstOrNull;
    if (subject == null) {
      emit(const SubjectDetailNotFound());
      return;
    }
    final topics = topicsResult.dataOrNull ?? const <Topic>[];

    final todayKey = DateKeyUtils.toDateKey(_clock.now(), timezone: _timezone);
    emit(
      SubjectDetailLoaded(
        overview: SubjectOverview.of(
          subject,
          topics,
          todayKey: todayKey,
          timezone: _timezone,
        ),
        topics: topics,
        deletedTopicTitle: deletedTopicTitle,
      ),
    );
  }

  /// Keeps the page and adds the failure, so the screen shows a snackbar.
  void _showActionFailure(Failure failure) {
    final current = state;
    if (current is! SubjectDetailLoaded) return;
    final clean = SubjectDetailLoaded(
      overview: current.overview,
      topics: current.topics,
    );
    // Clear an older failure first, so the same failure twice still shows.
    emit(clean);
    emit(
      SubjectDetailLoaded(
        overview: clean.overview,
        topics: clean.topics,
        actionFailure: failure,
      ),
    );
  }
}
