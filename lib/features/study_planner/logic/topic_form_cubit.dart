import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/study_planner/data/models/study_enums.dart';
import 'package:brainly_life/features/study_planner/data/models/topic_model.dart';
import 'package:brainly_life/features/study_planner/data/repositories/study_repository.dart';
import 'package:brainly_life/features/study_planner/logic/topic_form_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Drives the new / edit topic screen.
///
/// Call [startCreate] with the subject id for a new topic, or [startEdit]
/// with the topic id. Field errors show only after the first [save].
///
/// The user types the estimate in hours; it is stored as
/// `estimatedMinutes`.
class TopicFormCubit extends Cubit<TopicFormState> {
  TopicFormCubit(this._repository)
    : super(
        const TopicFormState(status: TopicFormStatus.loading, isEdit: false),
      );

  /// Validation limits (Master Document B.2).
  static const int maxTitleLength = 100;
  static const int minDifficulty = 1;
  static const int maxDifficulty = 5;
  static const double minHours = 0.5;
  static const double maxHours = 200;

  final StudyRepository _repository;

  /// The topic as it was before editing. null when creating.
  Topic? _original;
  String? _originalHoursText;
  String _subjectId = '';
  bool _isEdit = false;
  TopicFormStatus _status = TopicFormStatus.loading;
  bool _showErrors = false;

  String _title = '';
  int? _difficulty;
  String _hoursText = '';
  TopicStatus _topicStatus = TopicStatus.notStarted;

  void startCreate(String subjectId) {
    _isEdit = false;
    _original = null;
    _subjectId = subjectId;
    _status = TopicFormStatus.editing;
    _emitForm();
  }

  /// Loads the topic and fills the form. Call it again to retry.
  Future<void> startEdit(String topicId) async {
    _isEdit = true;
    _status = TopicFormStatus.loading;
    _emitForm();

    final result = await _repository.getTopics();
    if (isClosed) return;

    switch (result) {
      case Success(:final data):
        final topic = data.where((t) => t.id == topicId).firstOrNull;
        if (topic == null) {
          _status = TopicFormStatus.notFound;
          _emitForm(failure: const NotFoundFailure());
          return;
        }
        _fillFrom(topic);
        _status = TopicFormStatus.editing;
        _emitForm();
      case Failed(:final failure):
        _status = TopicFormStatus.loadFailed;
        _emitForm(failure: failure);
    }
  }

  void titleChanged(String value) => _update(() => _title = value);

  void difficultyChanged(int value) => _update(() => _difficulty = value);

  void hoursChanged(String value) => _update(() => _hoursText = value);

  void statusChanged(TopicStatus value) => _update(() => _topicStatus = value);

  /// Checks the fields, then adds or updates the topic.
  Future<void> save() async {
    if (_status != TopicFormStatus.editing) return;
    _showErrors = true;
    if (_titleError != null ||
        _difficultyError != null ||
        _hoursError != null) {
      _emitForm();
      return;
    }

    _status = TopicFormStatus.saving;
    _emitForm();

    final topic = _buildTopic();
    final failure = _original == null
        ? (await _repository.addTopic(topic)).failureOrNull
        : (await _repository.updateTopic(topic)).failureOrNull;
    if (isClosed) return;

    _status = failure == null ? TopicFormStatus.saved : TopicFormStatus.editing;
    _emitForm(failure: failure);
  }

  /// Deletes the topic being edited, with its study sessions.
  /// The screen asks for confirmation first.
  Future<void> delete() async {
    final original = _original;
    if (_status != TopicFormStatus.editing || original == null) return;

    _status = TopicFormStatus.saving;
    _emitForm();

    final failure = (await _repository.deleteTopic(original.id)).failureOrNull;
    if (isClosed) return;

    _status = failure == null
        ? TopicFormStatus.deleted
        : TopicFormStatus.editing;
    _emitForm(failure: failure);
  }

  /// The typed hours as a number. Accepts "1,5" too.
  double? get _hours => double.tryParse(_hoursText.trim().replaceAll(',', '.'));

  String? get _titleError {
    final title = _title.trim();
    if (title.isEmpty) return 'Enter a topic title';
    if (title.length > maxTitleLength) {
      return 'Use $maxTitleLength characters or fewer';
    }
    return null;
  }

  String? get _difficultyError =>
      _difficulty == null ? 'Pick a difficulty' : null;

  String? get _hoursError {
    if (_hoursText.trim().isEmpty) return 'Enter the estimated hours';
    final hours = _hours;
    if (hours == null || !hours.isFinite) return 'Enter a number, e.g. 1.5';
    if (hours < minHours || hours > maxHours) {
      return 'Use between 0.5 and 200 hours';
    }
    return null;
  }

  void _update(void Function() change) {
    if (_status != TopicFormStatus.editing) return;
    change();
    _emitForm();
  }

  void _fillFrom(Topic topic) {
    _original = topic;
    _subjectId = topic.subjectId;
    _title = topic.title;
    _difficulty = topic.difficulty;
    _topicStatus = topic.status;
    _originalHoursText = hoursTextOf(topic.estimatedMinutes);
    _hoursText = _originalHoursText!;
  }

  Topic _buildTopic() {
    final original = _original;
    // Keep the exact minutes when the hours text did not change, so
    // 100 minutes ("1.67") does not become 100.2 and then 100 again.
    final minutes = original != null && _hoursText == _originalHoursText
        ? original.estimatedMinutes
        : (_hours! * 60).round();

    return Topic(
      id: original?.id ?? '', // a new topic gets its id from the repository
      subjectId: _subjectId,
      title: _title.trim(),
      difficulty: _difficulty!,
      estimatedMinutes: minutes,
      status: _topicStatus,
      // Studied minutes come from sessions and focus, not from this form.
      completedMinutes: original?.completedMinutes ?? 0,
      createdAt: original?.createdAt,
      updatedAt: original?.updatedAt,
    );
  }

  void _emitForm({Failure? failure}) {
    emit(
      TopicFormState(
        status: _status,
        isEdit: _isEdit,
        title: _title,
        difficulty: _difficulty,
        hoursText: _hoursText,
        topicStatus: _topicStatus,
        titleError: _showErrors ? _titleError : null,
        difficultyError: _showErrors ? _difficultyError : null,
        hoursError: _showErrors ? _hoursError : null,
        failure: failure,
      ),
    );
  }

  /// 120 -> "2", 90 -> "1.5", 100 -> "1.67".
  static String hoursTextOf(int minutes) {
    final text = (minutes / 60).toStringAsFixed(2);
    return text.replaceFirst(RegExp(r'\.?0+$'), '');
  }
}
