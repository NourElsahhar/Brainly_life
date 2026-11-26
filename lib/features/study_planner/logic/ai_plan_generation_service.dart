import 'package:brainly_life/core/ai/ai_client.dart';
import 'package:brainly_life/core/ai/ai_failures.dart';
import 'package:brainly_life/core/ai/ai_models.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/core/utils/date_key_utils.dart';
import 'package:brainly_life/features/study_planner/data/models/study_enums.dart';
import 'package:brainly_life/features/study_planner/data/models/study_plan_model.dart';
import 'package:brainly_life/features/study_planner/data/models/study_session_model.dart';
import 'package:brainly_life/features/study_planner/data/repositories/study_repository.dart';
import 'package:brainly_life/features/study_planner/logic/plan_generation_service.dart';
import 'package:brainly_life/features/study_planner/logic/plan_validator.dart';
import 'package:brainly_life/features/study_planner/logic/study_plan_payload.dart';
import 'package:brainly_life/features/study_planner/logic/study_plan_response_parser.dart';
import 'package:clock/clock.dart';

/// Makes a study plan through M5's [AiClient] and M1's gateway
/// (feature `studyPlan`, prompt module `functions/src/ai/features/studyPlan.ts`).
///
/// Pure Dart (only the AI contracts, no Flutter or Firebase), so it lives
/// in `logic/` and is tested with a fake AiClient.
///
/// Steps: send the payload, turn the answer into sessions, check them with
/// [PlanValidator]. Any problem gives `Failed(AiFailure)`; nothing is saved
/// here (the preview saves after the user accepts).
///
/// `settings.aiEnabled` is checked by the AiClient itself, which fails with
/// `AiErrorCode.disabled` when AI is off.
class AiPlanGenerationService implements PlanGenerationService {
  AiPlanGenerationService({
    required this._aiClient,
    required this._repository,
    required this._timezone,
    this._clock = const Clock(),
  });

  /// Saved as the plan title. The user does not type one in the wizard.
  static const String defaultPlanTitle = 'Study plan';

  final AiClient _aiClient;
  final StudyRepository _repository;
  final String _timezone;
  final Clock _clock;

  @override
  Future<Result<GeneratedPlan>> generate(StudyPlanRequest request) async {
    final aiResult = await _aiClient.generate(
      AiRequest(
        feature: AiFeature.studyPlan,
        payload: request.payload,
        promptVersion: StudyPlanPayloadBuilder.promptVersion,
      ),
    );
    if (aiResult case Failed(:final failure)) {
      return Result.failure(failure);
    }
    final data = aiResult.dataOrNull!.data;

    final planId = _repository.newPlanId();
    final List<StudySession> sessions;
    try {
      sessions = StudyPlanResponseParser(timezone: _timezone)
          .parse(data, planId: planId, newSessionId: _repository.newSessionId);
    } on FormatException {
      return Result.failure(AiGatewayFailure(AiErrorCode.invalidResponse));
    }

    final validation = PlanValidator(clock: _clock).validate(
      sessions: sessions,
      subjectIds: {for (final s in request.subjects) s.id},
      topics: request.topics,
      examDateKeys: {
        for (final s in request.subjects)
          s.id: DateKeyUtils.toDateKey(s.examDate, timezone: _timezone),
      },
      constraints: request.constraints,
      days: request.days,
    );
    if (!validation.isValid) {
      return Result.failure(AiGatewayFailure(AiErrorCode.invalidResponse));
    }

    sessions.sort((a, b) => a.startAt.compareTo(b.startAt));
    final plan = StudyPlan(
      id: planId,
      title: defaultPlanTitle,
      startDate: _dayStart(request.days.first.dateKey),
      endDate: _dayStart(request.days.last.dateKey),
      generatedBy: PlanGenerator.ai,
      promptVersion: StudyPlanPayloadBuilder.promptVersion,
      constraints: request.constraints,
    );
    return Result.success(GeneratedPlan(plan: plan, sessions: sessions));
  }

  DateTime _dayStart(String dateKey) =>
      DateKeyUtils.dayBounds(dateKey, timezone: _timezone).start;
}
