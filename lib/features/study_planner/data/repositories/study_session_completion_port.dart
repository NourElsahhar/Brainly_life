import '../../../../core/errors/result.dart';

/// Called by the Focus feature (M4) when a focus session that was started
/// from a study session finishes.
///
/// Focus only knows the id it received in the route
/// (`/focus?studySessionId=`). It never imports Study Planner Cubits or data
/// sources, only this contract.
abstract class StudySessionCompletionPort {
  /// Adds [minutes] to `actualMinutes` of the study session.
  ///
  /// Fails with a NotFoundFailure when the session does not exist and with a
  /// ValidationFailure when [minutes] is not positive.
  Future<Result<void>> addActualMinutes({
    required String studySessionId,
    required int minutes,
  });
}
