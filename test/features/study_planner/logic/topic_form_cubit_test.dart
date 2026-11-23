import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/study_planner/data/models/study_enums.dart';
import 'package:brainly_life/features/study_planner/data/models/subject_model.dart';
import 'package:brainly_life/features/study_planner/data/models/topic_model.dart';
import 'package:brainly_life/features/study_planner/data/repositories/mock_study_repository.dart';
import 'package:brainly_life/features/study_planner/data/repositories/study_repository.dart';
import 'package:brainly_life/features/study_planner/logic/topic_form_cubit.dart';
import 'package:brainly_life/features/study_planner/logic/topic_form_state.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _FailingRepository extends Mock implements StudyRepository {}

final _clock = Clock.fixed(DateTime.utc(2026, 11, 20, 10));

void main() {
  late MockStudyRepository repository;
  late Subject physics;
  late Topic waves;

  setUp(() async {
    repository = MockStudyRepository(clock: _clock, withSampleData: false);
    physics = (await repository.addSubject(
      Subject(
        id: '',
        name: 'Physics',
        colorValue: 0xFF3F51B5,
        examDate: DateTime.utc(2026, 11, 26),
        priority: 2,
      ),
    )).dataOrNull!;
    waves = (await repository.addTopic(
      Topic(
        id: '',
        subjectId: physics.id,
        title: 'Waves',
        difficulty: 3,
        estimatedMinutes: 100,
        status: TopicStatus.inProgress,
        completedMinutes: 40,
      ),
    )).dataOrNull!;
  });

  Future<List<Topic>> topics() async =>
      (await repository.getTopics()).dataOrNull!;

  group('hoursTextOf', () {
    test('shows hours without extra zeros', () {
      expect(TopicFormCubit.hoursTextOf(120), '2');
      expect(TopicFormCubit.hoursTextOf(90), '1.5');
      expect(TopicFormCubit.hoursTextOf(100), '1.67');
      expect(TopicFormCubit.hoursTextOf(6000), '100');
    });
  });

  group('new topic', () {
    test('starts empty with no errors', () {
      final cubit = TopicFormCubit(repository)..startCreate(physics.id);

      expect(
        cubit.state,
        const TopicFormState(status: TopicFormStatus.editing, isEdit: false),
      );
    });

    test('save with empty fields shows all errors and saves nothing', () async {
      final cubit = TopicFormCubit(repository)..startCreate(physics.id);

      await cubit.save();

      expect(cubit.state.status, TopicFormStatus.editing);
      expect(cubit.state.titleError, 'Enter a topic title');
      expect(cubit.state.difficultyError, 'Pick a difficulty');
      expect(cubit.state.hoursError, 'Enter the estimated hours');
      expect(await topics(), [waves]);
    });

    test('rejects a long title and hours out of range', () async {
      final cubit = TopicFormCubit(repository)
        ..startCreate(physics.id)
        ..titleChanged('x' * 101)
        ..difficultyChanged(2);

      for (final text in ['0.4', '200.5', 'abc']) {
        cubit.hoursChanged(text);
        await cubit.save();
        expect(cubit.state.hoursError, isNotNull, reason: text);
      }
      expect(cubit.state.titleError, 'Use 100 characters or fewer');
      expect(await topics(), [waves]);
    });

    test('saves a valid topic, with hours as minutes', () async {
      final cubit = TopicFormCubit(repository)
        ..startCreate(physics.id)
        ..titleChanged('  Optics  ')
        ..difficultyChanged(4)
        ..hoursChanged('1,5')
        ..statusChanged(TopicStatus.notStarted);

      await cubit.save();

      expect(cubit.state.status, TopicFormStatus.saved);
      final optics = (await topics()).firstWhere((t) => t.title == 'Optics');
      expect(optics.subjectId, physics.id);
      expect(optics.difficulty, 4);
      expect(optics.estimatedMinutes, 90);
      expect(optics.completedMinutes, 0);
    });

    test('accepts the limits 0.5 and 200 hours', () async {
      final cubit = TopicFormCubit(repository)
        ..startCreate(physics.id)
        ..titleChanged('Short')
        ..difficultyChanged(1)
        ..hoursChanged('0.5');
      await cubit.save();
      expect(cubit.state.status, TopicFormStatus.saved);

      final second = TopicFormCubit(repository)
        ..startCreate(physics.id)
        ..titleChanged('Long')
        ..difficultyChanged(5)
        ..hoursChanged('200');
      await second.save();
      expect(second.state.status, TopicFormStatus.saved);
    });
  });

  group('edit topic', () {
    test('fills the form from the saved topic', () async {
      final cubit = TopicFormCubit(repository);
      await cubit.startEdit(waves.id);

      final state = cubit.state;
      expect(state.status, TopicFormStatus.editing);
      expect(state.isEdit, isTrue);
      expect(state.title, 'Waves');
      expect(state.difficulty, 3);
      expect(state.hoursText, '1.67');
      expect(state.topicStatus, TopicStatus.inProgress);
    });

    test('keeps the exact minutes and studied time when hours stay', () async {
      final cubit = TopicFormCubit(repository);
      await cubit.startEdit(waves.id);
      cubit
        ..titleChanged('Waves and sound')
        ..statusChanged(TopicStatus.done);

      await cubit.save();

      expect(cubit.state.status, TopicFormStatus.saved);
      final saved = (await topics()).single;
      expect(saved.id, waves.id);
      expect(saved.title, 'Waves and sound');
      expect(saved.status, TopicStatus.done);
      expect(saved.estimatedMinutes, 100);
      expect(saved.completedMinutes, 40);
    });

    test('a missing topic shows notFound', () async {
      final cubit = TopicFormCubit(repository);
      await cubit.startEdit('missing');

      expect(cubit.state.status, TopicFormStatus.notFound);
    });

    test('delete removes the topic', () async {
      final cubit = TopicFormCubit(repository);
      await cubit.startEdit(waves.id);

      await cubit.delete();

      expect(cubit.state.status, TopicFormStatus.deleted);
      expect(await topics(), isEmpty);
    });
  });

  group('when the repository fails', () {
    late _FailingRepository failing;

    setUpAll(() {
      // any() needs an example Topic. setUpAll runs before setUp, so it
      // cannot use `waves` here.
      registerFallbackValue(
        const Topic(
          id: 'fallback',
          subjectId: 'fallback',
          title: 'fallback',
          difficulty: 1,
          estimatedMinutes: 30,
          status: TopicStatus.notStarted,
          completedMinutes: 0,
        ),
      );
    });

    setUp(() {
      failing = _FailingRepository();
      when(() => failing.getTopics())
          .thenAnswer((_) async => Result.success([waves]));
    });

    test('a failed load shows loadFailed', () async {
      when(() => failing.getTopics())
          .thenAnswer((_) async => const Result.failure(NetworkFailure()));

      final cubit = TopicFormCubit(failing);
      await cubit.startEdit(waves.id);

      expect(cubit.state.status, TopicFormStatus.loadFailed);
      expect(cubit.state.failure, const NetworkFailure());
    });

    test('a failed save keeps the form and reports it', () async {
      when(() => failing.updateTopic(any()))
          .thenAnswer((_) async => const Result.failure(NetworkFailure()));

      final cubit = TopicFormCubit(failing);
      await cubit.startEdit(waves.id);
      await cubit.save();

      expect(cubit.state.status, TopicFormStatus.editing);
      expect(cubit.state.failure, const NetworkFailure());
      expect(cubit.state.title, 'Waves');
    });

    test('a failed delete keeps the form and reports it', () async {
      when(() => failing.deleteTopic(waves.id))
          .thenAnswer((_) async => const Result.failure(NetworkFailure()));

      final cubit = TopicFormCubit(failing);
      await cubit.startEdit(waves.id);
      await cubit.delete();

      expect(cubit.state.status, TopicFormStatus.editing);
      expect(cubit.state.failure, const NetworkFailure());
    });
  });
}
