import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/home/data/repositories/home_summary_port.dart';
import 'package:brainly_life/features/study_planner/data/models/study_enums.dart';
import 'package:brainly_life/features/study_planner/data/models/study_session_model.dart';
import 'package:brainly_life/features/study_planner/data/repositories/study_repository.dart';
import 'package:clock/clock.dart';

/// Feeds the "Next study session" card on Home (M3's contract).
///
/// The next session is the earliest planned session of the active plan
/// that has not ended yet, so a session that is running now still shows.
class DefaultStudySummaryProvider implements StudySummaryProvider {
  DefaultStudySummaryProvider({
    required this._repository,
    this._clock = const Clock(),
  });

  final StudyRepository _repository;
  final Clock _clock;

  @override
  Future<Result<StudySummary?>> nextSession() async {
    final planResult = await _repository.getActivePlan();
    if (planResult case Failed(:final failure)) {
      return Result.failure(failure);
    }
    final plan = planResult.dataOrNull;
    if (plan == null) return const Result.success(null);

    final sessionsResult = await _repository.getSessionsForPlan(plan.id);
    if (sessionsResult case Failed(:final failure)) {
      return Result.failure(failure);
    }
    final sessions = sessionsResult.dataOrNull ?? const <StudySession>[];

    final now = _clock.now().toUtc();
    StudySession? next;
    for (final session in sessions) {
      if (session.status != SessionStatus.planned) continue;
      final endsAt = session.startAt.add(
        Duration(minutes: session.plannedMinutes),
      );
      if (!endsAt.isAfter(now)) continue;
      if (next == null || session.startAt.isBefore(next.startAt)) {
        next = session;
      }
    }
    if (next == null) return const Result.success(null);

    final subjectsResult = await _repository.getSubjects();
    final topicsResult = await _repository.getTopics(subjectId: next.subjectId);
    final failure = subjectsResult.failureOrNull ?? topicsResult.failureOrNull;
    if (failure != null) return Result.failure(failure);

    final session = next;
    final subject = subjectsResult.dataOrNull
        ?.where((s) => s.id == session.subjectId)
        .firstOrNull;
    final topic = topicsResult.dataOrNull
        ?.where((t) => t.id == session.topicId)
        .firstOrNull;

    return Result.success(
      StudySummary(
        sessionId: session.id,
        // Deleting a subject or topic deletes its sessions, so these are
        // only empty for a moment while that happens.
        subjectName: subject?.name ?? '',
        topicTitle: topic?.title ?? '',
        startAt: session.startAt,
        plannedMinutes: session.plannedMinutes,
      ),
    );
  }
}
