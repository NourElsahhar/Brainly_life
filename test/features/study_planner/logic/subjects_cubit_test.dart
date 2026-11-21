import 'package:bloc_test/bloc_test.dart';
import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/study_planner/data/models/study_enums.dart';
import 'package:brainly_life/features/study_planner/data/models/subject_model.dart';
import 'package:brainly_life/features/study_planner/data/models/topic_model.dart';
import 'package:brainly_life/features/study_planner/data/repositories/mock_study_repository.dart';
import 'package:brainly_life/features/study_planner/data/repositories/study_repository.dart';
import 'package:brainly_life/features/study_planner/logic/subjects_cubit.dart';
import 'package:brainly_life/features/study_planner/logic/subjects_state.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _FailingRepository extends Mock implements StudyRepository {}

// "Now" is Friday 2026-11-20 10:00 UTC in every test.
final _clock = Clock.fixed(DateTime.utc(2026, 11, 20, 10));

Subject _subject(String name, DateTime examDate) {
  return Subject(
    id: '',
    name: name,
    colorValue: 0xFF3F51B5,
    examDate: examDate,
    priority: 2,
  );
}

Topic _topic(String subjectId, String title, TopicStatus status) {
  return Topic(
    id: '',
    subjectId: subjectId,
    title: title,
    difficulty: 3,
    estimatedMinutes: 60,
    status: status,
    completedMinutes: status == TopicStatus.done ? 60 : 0,
  );
}

/// An empty in-memory repository with the same clock as the tests.
MockStudyRepository _emptyRepository() {
  return MockStudyRepository(clock: _clock, withSampleData: false);
}

SubjectsCubit _cubit(StudyRepository repository, {String timezone = 'UTC'}) {
  return SubjectsCubit(repository, timezone: timezone, clock: _clock);
}

Future<Subject> _add(MockStudyRepository repository, Subject subject) async {
  return (await repository.addSubject(subject)).dataOrNull!;
}

void main() {
  test('starts in SubjectsInitial', () {
    expect(_cubit(_emptyRepository()).state, const SubjectsInitial());
  });

  blocTest<SubjectsCubit, SubjectsState>(
    'no subjects gives SubjectsEmpty',
    build: () => _cubit(_emptyRepository()),
    act: (cubit) => cubit.load(),
    expect: () => [const SubjectsLoading(), const SubjectsEmpty()],
  );

  test('loads every subject with its topics and days until the exam', () async {
    final repository = _emptyRepository();
    final physics = await _add(
      repository,
      _subject('Physics', DateTime.utc(2026, 11, 26, 9)),
    );
    final math = await _add(
      repository,
      _subject('Mathematics', DateTime.utc(2026, 12, 3, 9)),
    );
    await repository.addTopic(_topic(physics.id, 'Forces', TopicStatus.done));
    await repository.addTopic(
      _topic(physics.id, 'Energy', TopicStatus.inProgress),
    );

    final cubit = _cubit(repository);
    await cubit.load();

    final state = cubit.state as SubjectsLoaded;
    expect(state.subjects.map((o) => o.subject.name), [
      'Physics',
      'Mathematics',
    ]);

    final physicsCard = state.subjects[0];
    expect(physicsCard.topicCount, 2);
    expect(physicsCard.doneTopicCount, 1);
    expect(physicsCard.examDateKey, '2026-11-26');
    expect(physicsCard.progress, 0.5);
    expect(physicsCard.daysUntilExam, 6);

    final mathCard = state.subjects[1];
    expect(mathCard.subject.id, math.id);
    expect(mathCard.topicCount, 0);
    expect(mathCard.progress, 0);
    expect(mathCard.daysUntilExam, 13);
  });

  test('an exam that is over has a negative day count', () async {
    final repository = _emptyRepository();
    await _add(repository, _subject('History', DateTime.utc(2026, 11, 18, 9)));

    final cubit = _cubit(repository);
    await cubit.load();

    final card = (cubit.state as SubjectsLoaded).subjects.single;
    expect(card.daysUntilExam, -2);
    expect(card.isExamOver, isTrue);
  });

  test('days until the exam follow the user timezone', () async {
    // 23:30 UTC on the 25th is already the 26th in Cairo (UTC+2).
    final repository = _emptyRepository();
    await _add(
      repository,
      _subject('Physics', DateTime.utc(2026, 11, 25, 23, 30)),
    );

    final inUtc = _cubit(repository);
    final inCairo = _cubit(repository, timezone: 'Africa/Cairo');
    await inUtc.load();
    await inCairo.load();

    expect((inUtc.state as SubjectsLoaded).subjects.single.daysUntilExam, 5);
    expect((inCairo.state as SubjectsLoaded).subjects.single.daysUntilExam, 6);
  });

  test('deleting a subject removes it and its topics', () async {
    final repository = _emptyRepository();
    final physics = await _add(
      repository,
      _subject('Physics', DateTime.utc(2026, 11, 26, 9)),
    );
    await _add(repository, _subject('Mathematics', DateTime.utc(2026, 12, 3)));
    await repository.addTopic(_topic(physics.id, 'Forces', TopicStatus.done));

    final cubit = _cubit(repository);
    await cubit.load();
    await cubit.deleteSubject(physics);

    final state = cubit.state as SubjectsLoaded;
    expect(state.subjects.map((o) => o.subject.name), ['Mathematics']);
    expect(state.deletedName, 'Physics');
    expect((await repository.getTopics()).dataOrNull, isEmpty);
  });

  test('deleting the last subject gives SubjectsEmpty', () async {
    final repository = _emptyRepository();
    final physics = await _add(
      repository,
      _subject('Physics', DateTime.utc(2026, 11, 26, 9)),
    );

    final cubit = _cubit(repository);
    await cubit.load();
    await cubit.deleteSubject(physics);

    expect(cubit.state, const SubjectsEmpty(deletedName: 'Physics'));
  });

  group('when the repository fails', () {
    late _FailingRepository repository;
    final physics = _subject(
      'Physics',
      DateTime.utc(2026, 11, 26, 9),
    ).copyWith(id: 'physics');

    setUp(() {
      repository = _FailingRepository();
      when(() => repository.getSubjects())
          .thenAnswer((_) async => Result.success([physics]));
      when(() => repository.getTopics())
          .thenAnswer((_) async => const Result.success(<Topic>[]));
    });

    test('a failed load shows SubjectsError', () async {
      when(() => repository.getSubjects())
          .thenAnswer((_) async => const Result.failure(NetworkFailure()));

      final cubit = _cubit(repository);
      await cubit.load();

      expect(cubit.state, const SubjectsError(NetworkFailure()));
    });

    test('a failed delete keeps the list and reports the failure', () async {
      when(() => repository.deleteSubject('physics'))
          .thenAnswer((_) async => const Result.failure(NetworkFailure()));

      final cubit = _cubit(repository);
      await cubit.load();
      await cubit.deleteSubject(physics);

      final state = cubit.state as SubjectsLoaded;
      expect(state.subjects.single.subject, physics);
      expect(state.actionFailure, const NetworkFailure());
      expect(state.deletedName, isNull);
    });
  });
}
