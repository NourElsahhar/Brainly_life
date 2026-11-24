import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/study_planner/data/models/plan_constraints_model.dart';
import 'package:brainly_life/features/study_planner/data/models/study_enums.dart';
import 'package:brainly_life/features/study_planner/data/models/study_plan_model.dart';
import 'package:brainly_life/features/study_planner/data/models/subject_model.dart';
import 'package:brainly_life/features/study_planner/data/models/topic_model.dart';
import 'package:brainly_life/features/study_planner/data/repositories/mock_study_repository.dart';
import 'package:brainly_life/features/study_planner/data/repositories/study_repository.dart';
import 'package:brainly_life/features/study_planner/logic/plan_generation_service.dart';
import 'package:brainly_life/features/study_planner/logic/plan_wizard_cubit.dart';
import 'package:brainly_life/features/study_planner/logic/plan_wizard_state.dart';
import 'package:brainly_life/features/study_planner/logic/study_plan_payload.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _FakeGenerator extends Mock implements PlanGenerationService {}

class _FailingRepository extends Mock implements StudyRepository {}

// Friday 2026-11-20, 12:00 in Cairo.
final _clock = Clock.fixed(DateTime.utc(2026, 11, 20, 10));
const _cairo = 'Africa/Cairo';
final _builder = StudyPlanPayloadBuilder(clock: _clock, timezone: _cairo);

final _generated = GeneratedPlan(
  plan: StudyPlan(
    id: 'plan_1',
    title: 'Study plan',
    startDate: DateTime.utc(2026, 11, 20),
    endDate: DateTime.utc(2026, 11, 25),
    generatedBy: PlanGenerator.ai,
    promptVersion: 1,
    constraints: const PlanConstraints(
      minutesPerWeekday: {},
      daysOff: {},
      maxSessionMinutes: 45,
      breakMinutes: 10,
    ),
  ),
  sessions: const [],
);

void main() {
  late MockStudyRepository repository;
  late _FakeGenerator generator;
  late Subject physics;
  late Subject math;

  setUpAll(() {
    registerFallbackValue(
      const StudyPlanRequest(payload: {}, days: [], subjects: [], topics: []),
    );
  });

  Future<Subject> addSubject(String name, int examDay) async =>
      (await repository.addSubject(
        Subject(
          id: '',
          name: name,
          colorValue: 0xFF3F51B5,
          examDate: DateTime.utc(2026, 11, examDay, 7),
          priority: 2,
        ),
      )).dataOrNull!;

  Future<Topic> addTopic(
    Subject subject,
    String title, {
    TopicStatus status = TopicStatus.notStarted,
  }) async => (await repository.addTopic(
    Topic(
      id: '',
      subjectId: subject.id,
      title: title,
      difficulty: 3,
      estimatedMinutes: 120,
      status: status,
      completedMinutes: 0,
    ),
  )).dataOrNull!;

  PlanWizardCubit newCubit([StudyRepository? repo]) =>
      PlanWizardCubit(repo ?? repository, generator, payloadBuilder: _builder);

  setUp(() async {
    repository = MockStudyRepository(clock: _clock, withSampleData: false);
    generator = _FakeGenerator();
    math = await addSubject('Math', 30);
    physics = await addSubject('Physics', 26);
    await addTopic(physics, 'Waves');
    await addTopic(physics, 'Optics');
    await addTopic(physics, 'Old', status: TopicStatus.done);
    await addTopic(math, 'Algebra');
  });

  group('load', () {
    test('lists plannable subjects, soonest exam first, all selected', () async {
      final cubit = newCubit();
      await cubit.load();

      final state = cubit.state;
      expect(state.status, PlanWizardStatus.editing);
      expect(state.step, 1);
      expect(state.subjects.map((s) => s.subject.name), ['Physics', 'Math']);
      // Done topics are not offered.
      expect(state.subjects.first.topics.map((t) => t.title), [
        'Optics',
        'Waves',
      ]);
      expect(state.selectedTopicIds, hasLength(3));
      expect(state.minutesPerWeekday, {
        for (var day = 1; day <= 7; day++)
          day: PlanWizardCubit.defaultDayMinutes,
      });
      expect(state.maxSessionMinutes, 45);
    });

    test('from a subject page only its topics start selected', () async {
      final cubit = newCubit();
      await cubit.load(subjectId: math.id);

      expect(cubit.state.selectedSubjects.map((s) => s.subject.name), [
        'Math',
      ]);
    });

    test('leaves out exams today and subjects with nothing left', () async {
      final today = await addSubject('Today', 20);
      await addTopic(today, 'Late');
      final done = await addSubject('Done', 28);
      await addTopic(done, 'Finished', status: TopicStatus.done);

      final cubit = newCubit();
      await cubit.load();

      expect(cubit.state.subjects.map((s) => s.subject.name), [
        'Physics',
        'Math',
      ]);
    });

    test('nothing to plan', () async {
      repository = MockStudyRepository(clock: _clock, withSampleData: false);
      final cubit = newCubit();
      await cubit.load();

      expect(cubit.state.status, PlanWizardStatus.nothingToPlan);
    });

    test('a failed load shows loadFailed', () async {
      final failing = _FailingRepository();
      when(() => failing.getSubjects()).thenAnswer(
        (_) async => const Result.failure(NetworkFailure()),
      );
      when(
        () => failing.getTopics(),
      ).thenAnswer((_) async => const Result.success([]));

      final cubit = newCubit(failing);
      await cubit.load();

      expect(cubit.state.status, PlanWizardStatus.loadFailed);
      expect(cubit.state.failure, const NetworkFailure());
    });
  });

  group('step 1', () {
    test('toggles topics and whole subjects', () async {
      final cubit = newCubit();
      await cubit.load();
      final waves = cubit.state.subjects.first.topics.last;

      cubit.toggleTopic(waves.id);
      expect(cubit.state.isSelected(waves), isFalse);

      cubit.toggleSubject(physics.id); // some selected -> select all
      expect(cubit.state.isSelected(waves), isTrue);

      cubit.toggleSubject(physics.id); // all selected -> none
      expect(cubit.state.selectedSubjects.map((s) => s.subject.name), [
        'Math',
      ]);
    });

    test('next needs at least one topic', () async {
      final cubit = newCubit();
      await cubit.load();
      cubit
        ..toggleSubject(physics.id)
        ..toggleSubject(math.id)
        ..next();

      expect(cubit.state.canContinue, isFalse);
      expect(cubit.state.step, 1);

      cubit
        ..toggleSubject(math.id)
        ..next();
      expect(cubit.state.step, 2);
      expect(cubit.back(), isTrue);
      expect(cubit.state.step, 1);
      expect(cubit.back(), isFalse);
    });
  });

  group('step 2 and generate', () {
    Future<PlanWizardCubit> atStep2() async {
      final cubit = newCubit();
      await cubit.load();
      cubit.next();
      return cubit;
    }

    test('0 minutes makes a day off; session length is one of 25/45/60', () async {
      final cubit = await atStep2();

      cubit
        ..setDayMinutes(DateTime.friday, 0)
        ..sessionLengthChanged(60)
        ..sessionLengthChanged(50); // not offered: ignored

      expect(cubit.state.daysOff, {DateTime.friday});
      expect(cubit.state.maxSessionMinutes, 60);
    });

    test('without study time nothing is generated', () async {
      final cubit = await atStep2();
      for (var day = 1; day <= 7; day++) {
        cubit.setDayMinutes(day, 0);
      }

      await cubit.generate();

      expect(cubit.state.hasStudyTime, isFalse);
      expect(cubit.state.status, PlanWizardStatus.editing);
      verifyNever(() => generator.generate(any()));
    });

    test('sends only the selected topics and the chosen time', () async {
      when(
        () => generator.generate(any()),
      ).thenAnswer((_) async => Result.success(_generated));
      final cubit = await atStep2();
      final waves = cubit.state.subjects.first.topics.last;
      cubit
        ..back()
        ..toggleTopic(waves.id)
        ..next()
        ..setDayMinutes(DateTime.friday, 0)
        ..sessionLengthChanged(25);

      await cubit.generate();

      expect(cubit.state.status, PlanWizardStatus.generated);
      expect(cubit.state.result, _generated);

      final request =
          verify(() => generator.generate(captureAny())).captured.single
              as StudyPlanRequest;
      expect(request.topics.map((t) => t.title), ['Optics', 'Algebra']);
      final constraints = request.payload['constraints']! as Map;
      expect(constraints['daysOff'], [DateTime.friday]);
      expect(constraints['maxSessionMinutes'], 25);
      expect(constraints['breakMinutes'], PlanWizardCubit.breakMinutes);
    });

    test('an AI failure keeps the choices and allows Try again', () async {
      when(
        () => generator.generate(any()),
      ).thenAnswer((_) async => const Result.failure(AiFailure()));
      final cubit = await atStep2();

      await cubit.generate();

      expect(cubit.state.status, PlanWizardStatus.generateFailed);
      expect(cubit.state.failure, const AiFailure());
      expect(cubit.state.step, 2);
      expect(cubit.state.selectedTopicIds, hasLength(3));
      expect(cubit.state.result, isNull);

      when(
        () => generator.generate(any()),
      ).thenAnswer((_) async => Result.success(_generated));
      await cubit.generate(); // Try again

      expect(cubit.state.status, PlanWizardStatus.generated);
      expect(cubit.state.failure, isNull);
    });

    test('generating does not save anything', () async {
      when(
        () => generator.generate(any()),
      ).thenAnswer((_) async => Result.success(_generated));
      final cubit = await atStep2();

      await cubit.generate();

      expect((await repository.getActivePlan()).dataOrNull, isNull);
    });

    test('after the preview closes the wizard can be edited again', () async {
      when(
        () => generator.generate(any()),
      ).thenAnswer((_) async => Result.success(_generated));
      final cubit = await atStep2();
      await cubit.generate();

      cubit.previewClosed();

      expect(cubit.state.status, PlanWizardStatus.editing);
      expect(cubit.state.step, 2);
      expect(cubit.state.result, isNull);
    });
  });
}