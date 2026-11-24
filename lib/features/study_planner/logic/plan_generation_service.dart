import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/study_planner/data/models/study_plan_model.dart';
import 'package:brainly_life/features/study_planner/data/models/study_session_model.dart';
import 'package:brainly_life/features/study_planner/logic/study_plan_payload.dart';
import 'package:equatable/equatable.dart';

/// A plan the AI made and `PlanValidator` accepted. Nothing is saved yet:
/// the user sees it in the preview first.
class GeneratedPlan extends Equatable {
  const GeneratedPlan({required this.plan, required this.sessions});

  final StudyPlan plan;
  final List<StudySession> sessions;

  @override
  List<Object?> get props => [plan, sessions];
}

/// Makes a study plan with AI (Master Document B.2, task 13).
///
/// The real implementation sends `request.payload` through M5's `AiClient`
/// (feature `studyPlan`), turns the answer into sessions with
/// `StudyPlanResponseParser` and checks them with `PlanValidator`.
///
/// It returns `Failed(AiFailure)` when the AI is off, unavailable, or its
/// answer is invalid. It never saves anything and never falls back to a
/// local planner: the screen shows the error with "Try again".
abstract interface class PlanGenerationService {
  Future<Result<GeneratedPlan>> generate(StudyPlanRequest request);
}