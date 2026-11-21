import 'package:brainly_life/core/routes/app_routes.dart';

/// Paths of the study planner screens inside the Plan tab.
/// (They can move to AppRoutes when M1 adds them there.)
abstract final class StudyPlannerPaths {
  static const String newSubject = '${AppRoutes.plan}/subjects/new';

  static String editSubject(String subjectId) =>
      '${AppRoutes.plan}/subjects/$subjectId/edit';
}
