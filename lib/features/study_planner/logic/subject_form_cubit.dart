import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/core/utils/date_key_utils.dart';
import 'package:brainly_life/features/study_planner/data/models/subject_model.dart';
import 'package:brainly_life/features/study_planner/data/repositories/study_repository.dart';
import 'package:brainly_life/features/study_planner/logic/subject_form_state.dart';
import 'package:clock/clock.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Drives the new / edit subject screen.
///
/// Call [startCreate] for a new subject, or [startEdit] with its id.
/// Field errors show only after the first [save].
///
/// The exam is kept as a day (`examDateKey`). It is saved as the start of
/// that day in the user's [timezone], so `DateKeyUtils` gives the same day
/// back everywhere else.
class SubjectFormCubit extends Cubit<SubjectFormState> {
  SubjectFormCubit(
    this._repository, {
    required this._timezone,
    this._clock = const Clock(),
  }) : super(
         const SubjectFormState(
           status: SubjectFormStatus.loading,
           isEdit: false,
         ),
       );

  /// Subject name length (Master Document B.2, task 15).
  static const int maxNameLength = 60;

  final StudyRepository _repository;
  final String _timezone;
  final Clock _clock;

  /// The subject as it was before editing. null when creating.
  Subject? _original;
  String? _originalExamKey;
  bool _isEdit = false;
  SubjectFormStatus _status = SubjectFormStatus.loading;
  bool _showErrors = false;

  String _name = '';
  int? _colorValue;
  String? _examDateKey;
  int _priority = SubjectPriority.medium;

  void startCreate({required int defaultColorValue}) {
    _isEdit = false;
    _original = null;
    _colorValue = defaultColorValue;
    _status = SubjectFormStatus.editing;
    _emitForm();
  }

  /// Loads the subject and fills the form. Call it again to retry.
  Future<void> startEdit(String subjectId) async {
    _isEdit = true;
    _status = SubjectFormStatus.loading;
    _emitForm();

    final result = await _repository.getSubjects();
    if (isClosed) return;

    switch (result) {
      case Success(:final data):
        final matches = data.where((s) => s.id == subjectId);
        if (matches.isEmpty) {
          _status = SubjectFormStatus.notFound;
          _emitForm(failure: const NotFoundFailure());
          return;
        }
        _fillFrom(matches.first);
        _status = SubjectFormStatus.editing;
        _emitForm();
      case Failed(:final failure):
        _status = SubjectFormStatus.loadFailed;
        _emitForm(failure: failure);
    }
  }

  void nameChanged(String value) => _update(() => _name = value);

  void colorChanged(int value) => _update(() => _colorValue = value);

  /// [date] is the calendar day the user picked. null clears it.
  void examDateChanged(DateTime? date) => _update(
    () => _examDateKey = date == null
        ? null
        : DateKeyUtils.fromCalendarDate(date),
  );

  void priorityChanged(int value) => _update(() => _priority = value);

  /// Checks the fields, then adds or updates the subject.
  Future<void> save() async {
    if (_status != SubjectFormStatus.editing) return;
    _showErrors = true;
    if (_nameError != null || _examDateError != null) {
      _emitForm();
      return;
    }

    _status = SubjectFormStatus.saving;
    _emitForm();

    final subject = _buildSubject();
    final failure = _original == null
        ? (await _repository.addSubject(subject)).failureOrNull
        : (await _repository.updateSubject(subject)).failureOrNull;
    if (isClosed) return;

    _status = failure == null
        ? SubjectFormStatus.saved
        : SubjectFormStatus.editing;
    _emitForm(failure: failure);
  }

  String? get _nameError {
    final name = _name.trim();
    if (name.isEmpty) return 'Enter a subject name';
    if (name.length > maxNameLength) {
      return 'Use $maxNameLength characters or fewer';
    }
    return null;
  }

  String? get _examDateError {
    final key = _examDateKey;
    if (key == null) return 'Pick the exam date';
    // An old exam date may stay when editing, but a new one cannot be past.
    final changed = !_isEdit || key != _originalExamKey;
    final todayKey = DateKeyUtils.toDateKey(_clock.now(), timezone: _timezone);
    if (changed && key.compareTo(todayKey) < 0) {
      return 'The exam date cannot be in the past';
    }
    return null;
  }

  void _update(void Function() change) {
    if (_status != SubjectFormStatus.editing) return;
    change();
    _emitForm();
  }

  void _fillFrom(Subject subject) {
    _original = subject;
    _name = subject.name;
    _colorValue = subject.colorValue;
    _priority = subject.priority;
    _originalExamKey = DateKeyUtils.toDateKey(
      subject.examDate,
      timezone: _timezone,
    );
    _examDateKey = _originalExamKey;
  }

  Subject _buildSubject() {
    final key = _examDateKey!;
    final original = _original;
    // Keep the original moment when the day did not change.
    final examDate = original != null && key == _originalExamKey
        ? original.examDate
        : DateKeyUtils.dayBounds(key, timezone: _timezone).start;

    return Subject(
      id: original?.id ?? '', // a new subject gets its id from the repository
      name: _name.trim(),
      colorValue: _colorValue!,
      examDate: examDate,
      priority: _priority,
      createdAt: original?.createdAt,
      updatedAt: original?.updatedAt,
    );
  }

  void _emitForm({Failure? failure}) {
    emit(
      SubjectFormState(
        status: _status,
        isEdit: _isEdit,
        name: _name,
        colorValue: _colorValue,
        examDateKey: _examDateKey,
        priority: _priority,
        nameError: _showErrors ? _nameError : null,
        examDateError: _showErrors ? _examDateError : null,
        failure: failure,
      ),
    );
  }
}
