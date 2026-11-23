import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/study_planner/data/models/study_enums.dart';
import 'package:brainly_life/features/study_planner/data/models/subject_model.dart';
import 'package:brainly_life/features/study_planner/data/models/topic_model.dart';
import 'package:brainly_life/features/study_planner/data/repositories/mock_study_repository.dart';
import 'package:brainly_life/features/study_planner/data/repositories/study_repository.dart';
import 'package:brainly_life/features/study_planner/logic/subject_detail_cubit.dart';
import 'package:brainly_life/features/study_planner/logic/subject_detail_state.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _FailingRepository extends Mock implements StudyRepository {}

// "Now" is Friday 2026-11-20 10:00 UTC in every test.
final _clock = Clock.fixed(DateTime.utc(2026, 11, 20, 10));

Subject _subject(String name) {
  return Subject(
    id: '',
    name: name,
    colorValue: 0xFF3F51B5,
    examDate: DateTime.utc(2026, 11, 26, 9),
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

SubjectDetailCubit _cubit(StudyRepository repository) {
  return SubjectDetailCubit(repository, timezone: 'UTC', clock: _clock);
}

void main() {
  group('with the in-memory repository', () {
    late MockStudyRepository repository;
    late Subject physics;
    late Subject math;

    setUp(() async {
      repository = MockStudyRepository(clock: _clock, withSampleData: false);
      physics = (await repository.addSubject(_subject('Physics'))).dataOrNull!;
      math = (await repository.addSubject(_subject('Math'))).dataOrNull!;
      await repository.addTopic(_topic(physics.id, 'Waves', TopicStatus.done));
      await repository.addTopic(
        _topic(physics.id, 'Optics', TopicStatus.notStarted),
      );
      await repository.addTopic(_topic(math.id, 'Algebra', TopicStatus.done));
    });

    test('starts in SubjectDetailLoading', () {
      expect(_cubit(repository).state, const SubjectDetailLoading());
    });

    test('load shows the subject with only its own topics', () async {
      final cubit = _cubit(repository);
      await cubit.load(physics.id);

      final state = cubit.state as SubjectDetailLoaded;
      expect(state.overview.subject, physics);
      expect(state.topics.map((t) => t.title), ['Optics', 'Waves']);
      expect(state.overview.topicCount, 2);
      expect(state.overview.doneTopicCount, 1);
      expect(state.overview.progress, 0.5);
      expect(state.overview.examDateKey, '2026-11-26');
      expect(state.overview.daysUntilExam, 6);
    });

    test('a subject that does not exist shows NotFound', () async {
      final cubit = _cubit(repository);
      await cubit.load('missing');

      expect(cubit.state, const SubjectDetailNotFound());
    });

    test('deleteTopic removes it and reports its title', () async {
      final cubit = _cubit(repository);
      await cubit.load(physics.id);
      final optics = (cubit.state as SubjectDetailLoaded).topics.first;

      await cubit.deleteTopic(optics);

      final state = cubit.state as SubjectDetailLoaded;
      expect(state.topics.map((t) => t.title), ['Waves']);
      expect(state.deletedTopicTitle, 'Optics');
      expect(state.overview.progress, 1);
    });

    test('reload refreshes the page after an edit', () async {
      final cubit = _cubit(repository);
      await cubit.load(physics.id);
      await repository.addTopic(
        _topic(physics.id, 'Atoms', TopicStatus.inProgress),
      );

      await cubit.reload();

      final state = cubit.state as SubjectDetailLoaded;
      expect(state.topics.map((t) => t.title), ['Atoms', 'Optics', 'Waves']);
      expect(state.deletedTopicTitle, isNull);
    });

    test('deleteSubject emits Deleted and removes the subject', () async {
      final cubit = _cubit(repository);
      await cubit.load(physics.id);

      await cubit.deleteSubject();

      expect(cubit.state, const SubjectDetailDeleted('Physics'));
      final subjects = (await repository.getSubjects()).dataOrNull!;
      expect(subjects.map((s) => s.name), ['Math']);
    });
  });

  group('when the repository fails', () {
    late _FailingRepository repository;
    final physics = _subject('Physics').copyWith(id: 'physics');
    final waves = _topic(
      'physics',
      'Waves',
      TopicStatus.done,
    ).copyWith(id: 'waves');

    setUp(() {
      repository = _FailingRepository();
      when(() => repository.getSubjects())
          .thenAnswer((_) async => Result.success([physics]));
      when(() => repository.getTopics(subjectId: 'physics'))
          .thenAnswer((_) async => Result.success([waves]));
    });

    test('a failed load shows SubjectDetailError', () async {
      when(() => repository.getTopics(subjectId: 'physics'))
          .thenAnswer((_) async => const Result.failure(NetworkFailure()));

      final cubit = _cubit(repository);
      await cubit.load('physics');

      expect(cubit.state, const SubjectDetailError(NetworkFailure()));
    });

    test('a failed topic delete keeps the page and reports it', () async {
      when(() => repository.deleteTopic('waves'))
          .thenAnswer((_) async => const Result.failure(NetworkFailure()));

      final cubit = _cubit(repository);
      await cubit.load('physics');
      await cubit.deleteTopic(waves);

      final state = cubit.state as SubjectDetailLoaded;
      expect(state.topics, [waves]);
      expect(state.actionFailure, const NetworkFailure());
      expect(state.deletedTopicTitle, isNull);
    });

    test('a failed subject delete keeps the page and reports it', () async {
      when(() => repository.deleteSubject('physics'))
          .thenAnswer((_) async => const Result.failure(NetworkFailure()));

      final cubit = _cubit(repository);
      await cubit.load('physics');
      await cubit.deleteSubject();

      final state = cubit.state as SubjectDetailLoaded;
      expect(state.overview.subject, physics);
      expect(state.actionFailure, const NetworkFailure());
    });
  });
}
