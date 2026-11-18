import '../../../../core/errors/result.dart';
import '../models/study_plan_model.dart';
import '../models/study_session_model.dart';
import '../models/subject_model.dart';
import '../models/topic_model.dart';

/// The contract between the Study Planner Cubits and the data behind them
/// (Firestore in the app, memory in the mock).
///
/// Every method returns a [Result] instead of throwing: the implementation
/// catches exceptions and turns them into a Failure (Master Document E.7).
/// Cubits never import Firebase and never use try/catch.
abstract class StudyRepository {
  /// New ids are created on the device (Firestore can do this without the
  /// network), so a plan and its sessions already have their final ids while
  /// the user is still previewing them. Reminder ids (`study_<sessionId>`)
  /// can then be built before saving.
  String newPlanId();
  String newSessionId();

  // ---------------------------------------------------------------- subjects

  /// Ordered by exam date, soonest first.
  Future<Result<List<Subject>>> getSubjects();

  /// The id of [subject] is ignored: the saved subject gets a new one.
  Future<Result<Subject>> addSubject(Subject subject);

  /// Fails with a NotFoundFailure when the subject does not exist.
  Future<Result<Subject>> updateSubject(Subject subject);

  /// Also deletes the topics and the sessions of this subject.
  Future<Result<void>> deleteSubject(String subjectId);

  // ------------------------------------------------------------------ topics

  /// All topics, or only those of [subjectId].
  Future<Result<List<Topic>>> getTopics({String? subjectId});

  /// The id of [topic] is ignored. Fails with a NotFoundFailure when the
  /// subject of the topic does not exist.
  Future<Result<Topic>> addTopic(Topic topic);

  Future<Result<Topic>> updateTopic(Topic topic);

  /// Also deletes the sessions of this topic.
  Future<Result<void>> deleteTopic(String topicId);

  // ---------------------------------------------------------- plans/sessions

  /// Saves a whole plan with its sessions in one operation.
  ///
  /// Only one plan is active at a time: saving an active plan archives the
  /// previous one and removes its sessions that are still `planned`
  /// (finished, skipped and missed sessions stay as history).
  /// Every session must have `planId == plan.id`.
  ///
  /// The Firestore implementation writes in batches of at most 500
  /// operations.
  Future<Result<void>> savePlan(StudyPlan plan, List<StudySession> sessions);

  /// The active plan, or null when there is none.
  Future<Result<StudyPlan?>> getActivePlan();

  Future<Result<List<StudySession>>> getSessionsForPlan(String planId);

  /// Live sessions whose day is between [fromDateKey] and [toDateKey], both
  /// included (`yyyy-MM-dd` strings). A new list is emitted after every
  /// change. Cancel the subscription in the Cubit's `close()`.
  Stream<Result<List<StudySession>>> watchSessions({
    required String fromDateKey,
    required String toDateKey,
  });

  Future<Result<StudySession>> updateSession(StudySession session);

  Future<Result<void>> deleteSession(String sessionId);
}
