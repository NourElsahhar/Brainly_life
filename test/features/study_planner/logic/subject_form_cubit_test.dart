import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/study_planner/data/models/subject_model.dart';
import 'package:brainly_life/features/study_planner/data/repositories/mock_study_repository.dart';
import 'package:brainly_life/features/study_planner/data/repositories/study_repository.dart';
import 'package:brainly_life/features/study_planner/logic/subject_form_cubit.dart';
import 'package:brainly_life/features/study_planner/logic/subject_form_state.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _FailingRepository extends Mock implements StudyRepository {}

// "Now" is Friday 2026-11-20 10:00 UTC (12:00 in Cairo) in every test.
final _clock = Clock.fixed(DateTime.utc(2026, 11, 20, 10));
const _timezone = 'Africa/Cairo';
const _blue = 0xFF3F51B5;

MockStudyRepository _emptyRepository() {
  return MockStudyRepository(clock: _clock, withSampleData: false);
}

SubjectFormCubit _cubit(StudyRepository repository) {
  return SubjectFormCubit(repository, timezone: _timezone, clock: _clock);
}

/// A new-subject form with every field filled correctly.
SubjectFormCubit _filledNewForm(StudyRepository repository) {
  return _cubit(repository)
    ..startCreate(defaultColorValue: _blue)
    ..nameChanged('  Physics  ')
    ..examDateChanged(DateTime(2026, 11, 26))
    ..priorityChanged(SubjectPriority.high);
}

Future<Subject> _savedPhysics(MockStudyRepository repository) async {
  final result = await repository.addSubject(
    Subject(
      id: '',
      name: 'Physics',
      colorValue: _blue,
      examDate: DateTime.utc(2026, 11, 26, 7), // 09:00 in Cairo
      priority: SubjectPriority.medium,
    ),
  );
  return result.dataOrNull!;
}

void main() {
  setUpAll(() {
    // mocktail needs an example Subject to match `any()`.
    registerFallbackValue(
      Subject(
        id: '',
        name: '',
        colorValue: 0,
        examDate: DateTime.utc(2026),
        priority: SubjectPriority.medium,
      ),
    );
  });

  group('new subject', () {
    test('starts empty with the default colour and medium priority', () {
      final cubit = _cubit(_emptyRepository())
        ..startCreate(defaultColorValue: _blue);

      expect(cubit.state.status, SubjectFormStatus.editing);
      expect(cubit.state.isEdit, isFalse);
      expect(cubit.state.colorValue, _blue);
      expect(cubit.state.priority, SubjectPriority.medium);
      expect(cubit.state.examDateKey, isNull);
    });

    test('saves a valid subject', () async {
      final repository = _emptyRepository();
      final cubit = _filledNewForm(repository);

      await cubit.save();

      expect(cubit.state.status, SubjectFormStatus.saved);
      final saved = (await repository.getSubjects()).dataOrNull!.single;
      expect(saved.name, 'Physics');
      expect(saved.colorValue, _blue);
      expect(saved.priority, SubjectPriority.high);
      // The start of 26 Nov in Cairo (UTC+2) is 22:00 UTC the day before.
      expect(saved.examDate, DateTime.utc(2026, 11, 25, 22));
    });

    test('shows field errors only after the first save', () async {
      final cubit = _cubit(_emptyRepository())
        ..startCreate(defaultColorValue: _blue);

      expect(cubit.state.nameError, isNull);
      expect(cubit.state.examDateError, isNull);

      await cubit.save();

      expect(cubit.state.status, SubjectFormStatus.editing);
      expect(cubit.state.nameError, 'Enter a subject name');
      expect(cubit.state.examDateError, 'Pick the exam date');
    });

    test('rejects a name longer than 60 characters', () async {
      final cubit = _filledNewForm(_emptyRepository())..nameChanged('n' * 61);

      await cubit.save();

      expect(cubit.state.nameError, 'Use 60 characters or fewer');
      expect(cubit.state.status, SubjectFormStatus.editing);
    });

    test('rejects an exam date in the past but allows today', () async {
      final cubit = _filledNewForm(_emptyRepository())
        ..examDateChanged(DateTime(2026, 11, 19));

      await cubit.save();
      expect(cubit.state.examDateError, 'The exam date cannot be in the past');

      cubit.examDateChanged(DateTime(2026, 11, 20));
      expect(cubit.state.examDateError, isNull);
    });

    test('a failed save keeps the form and reports the failure', () async {
      final repository = _FailingRepository();
      when(() => repository.addSubject(any()))
          .thenAnswer((_) async => const Result.failure(NetworkFailure()));
      final cubit = _filledNewForm(repository);

      await cubit.save();

      expect(cubit.state.status, SubjectFormStatus.editing);
      expect(cubit.state.failure, const NetworkFailure());
      expect(cubit.state.name, '  Physics  ');
    });
  });

  group('edit subject', () {
    test('loads the subject into the form', () async {
      final repository = _emptyRepository();
      final physics = await _savedPhysics(repository);
      final cubit = _cubit(repository);

      await cubit.startEdit(physics.id);

      expect(cubit.state.status, SubjectFormStatus.editing);
      expect(cubit.state.isEdit, isTrue);
      expect(cubit.state.name, 'Physics');
      expect(cubit.state.examDateKey, '2026-11-26');
      expect(cubit.state.priority, SubjectPriority.medium);
    });

    test('saves the changes and keeps the exam time', () async {
      final repository = _emptyRepository();
      final physics = await _savedPhysics(repository);
      final cubit = _cubit(repository);
      await cubit.startEdit(physics.id);

      cubit.nameChanged('Physics II');
      await cubit.save();

      expect(cubit.state.status, SubjectFormStatus.saved);
      final saved = (await repository.getSubjects()).dataOrNull!.single;
      expect(saved.id, physics.id);
      expect(saved.name, 'Physics II');
      expect(saved.examDate, physics.examDate);
      expect(saved.createdAt, physics.createdAt);
    });

    test('an exam that is already over may stay as it is', () async {
      final repository = _emptyRepository();
      final old = await repository.addSubject(
        Subject(
          id: '',
          name: 'History',
          colorValue: _blue,
          examDate: DateTime.utc(2026, 11, 10, 7),
          priority: SubjectPriority.low,
        ),
      );
      final cubit = _cubit(repository);
      await cubit.startEdit(old.dataOrNull!.id);

      cubit.nameChanged('History I');
      await cubit.save();

      expect(cubit.state.status, SubjectFormStatus.saved);
    });

    test('an unknown id gives notFound', () async {
      final cubit = _cubit(_emptyRepository());

      await cubit.startEdit('missing');

      expect(cubit.state.status, SubjectFormStatus.notFound);
    });

    test('a failed load gives loadFailed', () async {
      final repository = _FailingRepository();
      when(() => repository.getSubjects())
          .thenAnswer((_) async => const Result.failure(NetworkFailure()));
      final cubit = _cubit(repository);

      await cubit.startEdit('physics');

      expect(cubit.state.status, SubjectFormStatus.loadFailed);
      expect(cubit.state.failure, const NetworkFailure());
    });
  });
}
