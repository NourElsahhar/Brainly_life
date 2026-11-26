import 'package:brainly_life/core/ai/ai_client.dart';
import 'package:brainly_life/core/ai/ai_failures.dart';
import 'package:brainly_life/core/ai/ai_models.dart';
import 'package:brainly_life/core/ai/mock_ai_client.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/study_planner/data/models/plan_constraints_model.dart';
import 'package:brainly_life/features/study_planner/data/models/study_enums.dart';
import 'package:brainly_life/features/study_planner/data/models/subject_model.dart';
import 'package:brainly_life/features/study_planner/data/models/topic_model.dart';
import 'package:brainly_life/features/study_planner/data/repositories/mock_study_repository.dart';
import 'package:brainly_life/features/study_planner/logic/ai_plan_generation_service.dart';
import 'package:brainly_life/features/study_planner/logic/study_plan_payload.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

// Friday 2026-11-20, 10:00 UTC = 12:00 in Cairo.
final _clock = Clock.fixed(DateTime.utc(2026, 11, 20, 10));
const _cairo = 'Africa/Cairo';

/// Remembers the request, then answers like [inner].
class _RecordingAiClient implements AiClient {
  _RecordingAiClient(this.inner);

  final AiClient inner;
  AiRequest? last;

  @override
  Future<Result<AiResponse>> generate(AiRequest request) {
    last = request;
    return inner.generate(request);
  }
}

void main() {
  late MockStudyRepository repository;
  late StudyPlanRequest request;
  late Subject physics;
  late Topic waves;

  setUp(() async {
    repository = MockStudyRepository(clock: _clock, withSampleData: false);
    physics = (await repository.addSubject(
      Subject(
        id: '',
        name: 'Physics',
        colorValue: 0xFF3F51B5,
        examDate: DateTime.utc(2026, 11, 26, 7),
        priority: 3,
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
    request = StudyPlanPayloadBuilder(clock: _clock, timezone: _cairo).buildNew(
      subjects: [physics],
      topics: [waves],
      constraints: const PlanConstraints(
        minutesPerWeekday: {
          1: 120,
          2: 120,
          3: 120,
          4: 120,
          5: 120,
          6: 120,
          7: 120,
        },
        daysOff: {},
        maxSessionMinutes: 45,
        breakMinutes: 10,
      ),
    );
  });

  Map<String, Object?> answer(List<Map<String, Object?>> sessions) => {
    'sessions': sessions,
  };

  Map<String, Object?> session(
    String date,
    String startTime, {
    String? topicId,
    int minutes = 45,
  }) => {
    'subjectId': physics.id,
    'topicId': topicId ?? waves.id,
    'date': date,
    'startTime': startTime,
    'plannedMinutes': minutes,
  };

  AiPlanGenerationService service(AiClient client) => AiPlanGenerationService(
    aiClient: client,
    repository: repository,
    timezone: _cairo,
    clock: _clock,
  );

  MockAiClient answering(Map<String, Object?> data) =>
      MockAiClient(delay: Duration.zero, fixtures: {AiFeature.studyPlan: data});

  test('sends the payload to the studyPlan feature', () async {
    final client = _RecordingAiClient(
      answering(answer([session('2026-11-21', '16:00')])),
    );

    await service(client).generate(request);

    expect(client.last?.feature, AiFeature.studyPlan);
    expect(client.last?.payload, request.payload);
    expect(client.last?.promptVersion, StudyPlanPayloadBuilder.promptVersion);
  });

  test('turns a valid answer into a plan, sessions sorted by time', () async {
    final result = await service(
      answering(
        answer([
          session('2026-11-21', '16:00'),
          session('2026-11-20', '18:00'),
        ]),
      ),
    ).generate(request);

    final generated = result.dataOrNull!;
    final plan = generated.plan;
    expect(plan.id, isNotEmpty);
    expect(plan.generatedBy, PlanGenerator.ai);
    expect(plan.promptVersion, StudyPlanPayloadBuilder.promptVersion);
    expect(plan.status, PlanStatus.active);
    expect(plan.constraints, request.constraints);
    // Midnight in Cairo (UTC+2) is 22:00 UTC the day before.
    expect(plan.startDate, DateTime.utc(2026, 11, 19, 22));
    expect(plan.endDate, DateTime.utc(2026, 11, 24, 22));

    final sessions = generated.sessions;
    expect(sessions.map((s) => s.dateKey), ['2026-11-20', '2026-11-21']);
    expect(sessions.first.startAt, DateTime.utc(2026, 11, 20, 16));
    expect(sessions.every((s) => s.planId == plan.id), isTrue);
    expect(sessions.map((s) => s.id).toSet(), hasLength(2));
  });

  test('passes AI errors on, for example AI turned off', () async {
    final result = await service(
      MockAiClient(enabled: false, delay: Duration.zero),
    ).generate(request);

    expect(
      (result.failureOrNull! as AiGatewayFailure).kind,
      AiErrorCode.disabled,
    );
  });

  test('an answer with the wrong shape is an invalid response', () async {
    final result = await service(
      MockAiClient(invalidOutput: true, delay: Duration.zero),
    ).generate(request);

    expect(
      (result.failureOrNull! as AiGatewayFailure).kind,
      AiErrorCode.invalidResponse,
    );
  });

  test('a plan that breaks the rules is rejected', () async {
    final bad = {
      'invented topic': session('2026-11-21', '16:00', topicId: 'invented'),
      'in the past': session('2026-11-20', '08:00'),
      'exam day': session('2026-11-26', '10:00'),
      'too long': session('2026-11-21', '16:00', minutes: 90),
    };

    for (final entry in bad.entries) {
      final result = await service(answering(answer([entry.value])))
          .generate(request);

      expect(
        (result.failureOrNull! as AiGatewayFailure).kind,
        AiErrorCode.invalidResponse,
        reason: entry.key,
      );
    }
  });

  test('never saves anything', () async {
    await service(answering(answer([session('2026-11-21', '16:00')])))
        .generate(request);

    expect((await repository.getActivePlan()).dataOrNull, isNull);
  });
}
