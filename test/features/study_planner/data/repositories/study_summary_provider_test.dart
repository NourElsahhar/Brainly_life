import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/home/data/repositories/home_summary_port.dart';
import 'package:brainly_life/features/study_planner/data/models/plan_constraints_model.dart';
import 'package:brainly_life/features/study_planner/data/models/study_enums.dart';
import 'package:brainly_life/features/study_planner/data/models/study_plan_model.dart';
import 'package:brainly_life/features/study_planner/data/models/study_session_model.dart';
import 'package:brainly_life/features/study_planner/data/models/subject_model.dart';
import 'package:brainly_life/features/study_planner/data/models/topic_model.dart';
import 'package:brainly_life/features/study_planner/data/repositories/mock_study_repository.dart';
import 'package:brainly_life/features/study_planner/data/repositories/study_repository.dart';
import 'package:brainly_life/features/study_planner/data/repositories/study_summary_provider.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _FailingRepository extends Mock implements StudyRepository {}

// "Now" is 2026-11-20 at 14:00 UTC.
final _now = DateTime.utc(2026, 11, 20, 14);
final _clock = Clock.fixed(_now);

void main() {
  late MockStudyRepository repository;
  late Subject physics;
  late Topic waves;

  final plan = StudyPlan(
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
  );

  StudySession session(
    String id,
    DateTime startAt, {
    SessionStatus status = SessionStatus.planned,
    int minutes = 45,
  }) => StudySession(
    id: id,
    planId: plan.id,
    subjectId: physics.id,
    topicId: waves.id,
    dateKey: '2026-11-20',
    startAt: startAt,
    plannedMinutes: minutes,
    status: status,
  );

  DefaultStudySummaryProvider provider([StudyRepository? repo]) =>
      DefaultStudySummaryProvider(
        repository: repo ?? repository,
        clock: _clock,
      );

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
        estimatedMinutes: 120,
        status: TopicStatus.notStarted,
        completedMinutes: 0,
      ),
    )).dataOrNull!;
  });

  test('no active plan gives null', () async {
    expect((await provider().nextSession()).dataOrNull, isNull);
  });

  test('gives the earliest planned session that has not ended', () async {
    await repository.savePlan(plan, [
      session(
        'done',
        _now.subtract(const Duration(hours: 2)),
        status: SessionStatus.done,
      ),
      session('ended', _now.subtract(const Duration(hours: 1))),
      session('later', _now.add(const Duration(hours: 3))),
      session('running', _now.subtract(const Duration(minutes: 10))),
      session(
        'skipped',
        _now.add(const Duration(hours: 1)),
        status: SessionStatus.skipped,
      ),
    ]);

    final summary = (await provider().nextSession()).dataOrNull;

    expect(
      summary,
      StudySummary(
        sessionId: 'running',
        subjectName: 'Physics',
        topicTitle: 'Waves',
        startAt: _now.subtract(const Duration(minutes: 10)),
        plannedMinutes: 45,
      ),
    );
  });

  test('null when every session is over', () async {
    await repository.savePlan(plan, [
      session('ended', _now.subtract(const Duration(hours: 1))),
    ]);

    expect((await provider().nextSession()).dataOrNull, isNull);
  });

  test('passes a repository failure on', () async {
    final failing = _FailingRepository();
    when(() => failing.getActivePlan())
        .thenAnswer((_) async => const Result.failure(NetworkFailure()));

    final result = await provider(failing).nextSession();

    expect(result.failureOrNull, const NetworkFailure());
  });
}
