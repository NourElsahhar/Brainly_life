import 'dart:async';

import 'package:clock/clock.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../models/study_enums.dart';
import '../models/study_plan_model.dart';
import '../models/study_session_model.dart';
import '../models/subject_model.dart';
import '../models/topic_model.dart';
import 'study_repository.dart';
import 'study_sample_data.dart';
import 'study_session_completion_port.dart';

/// An in-memory [StudyRepository] with realistic sample data.
///
/// Use it while Firestore is not ready, in tests, and from other features
/// (Home dashboard, Analytics) that need study data:
/// `--dart-define=USE_MOCKS=true`.
///
/// It behaves like the real repository: it returns Results (never throws),
/// fails with a NotFoundFailure for unknown ids, deletes in cascade, keeps
/// only one active plan and pushes a new list to every `watchSessions`
/// listener after each change.
class MockStudyRepository
    implements StudyRepository, StudySessionCompletionPort {
  MockStudyRepository({
    this.clock = const Clock(),
    this.timezone = 'Africa/Cairo',
    bool withSampleData = true,
  }) {
    if (withSampleData) {
      _loadSampleData();
    }
  }

  /// Source of "now". Tests pass `Clock.fixed(...)`.
  final Clock clock;

  /// The user's IANA timezone, used to build the sample days.
  final String timezone;

  final Map<String, Subject> _subjects = {};
  final Map<String, Topic> _topics = {};
  final Map<String, StudyPlan> _plans = {};
  final Map<String, StudySession> _sessions = {};
  final StreamController<void> _changes = StreamController<void>.broadcast(
    sync: true,
  );
  int _idCounter = 0;

  DateTime _now() => clock.now().toUtc();

  String _nextId(String prefix) => '${prefix}_${++_idCounter}';

  void _notifyChanged() => _changes.add(null);

  void _loadSampleData() {
    final data = StudySampleData.build(now: _now(), timezone: timezone);
    for (final subject in data.subjects) {
      _subjects[subject.id] = subject;
    }
    for (final topic in data.topics) {
      _topics[topic.id] = topic;
    }
    _plans[data.plan.id] = data.plan;
    for (final session in data.sessions) {
      _sessions[session.id] = session;
    }
  }

  @override
  String newPlanId() => _nextId('plan');

  @override
  String newSessionId() => _nextId('session');

  // ---------------------------------------------------------------- subjects

  @override
  Future<Result<List<Subject>>> getSubjects() async {
    final subjects = _subjects.values.toList()
      ..sort((a, b) {
        final byExam = a.examDate.compareTo(b.examDate);
        return byExam != 0 ? byExam : a.name.compareTo(b.name);
      });
    return Result.success(subjects);
  }

  @override
  Future<Result<Subject>> addSubject(Subject subject) async {
    final now = _now();
    final saved = subject.copyWith(
      id: _nextId('subject'),
      createdAt: now,
      updatedAt: now,
    );
    _subjects[saved.id] = saved;
    return Result.success(saved);
  }

  @override
  Future<Result<Subject>> updateSubject(Subject subject) async {
    final existing = _subjects[subject.id];
    if (existing == null) {
      return const Result.failure(NotFoundFailure());
    }
    final saved = subject.copyWith(
      createdAt: existing.createdAt,
      updatedAt: _now(),
    );
    _subjects[saved.id] = saved;
    return Result.success(saved);
  }

  @override
  Future<Result<void>> deleteSubject(String subjectId) async {
    if (!_subjects.containsKey(subjectId)) {
      return const Result.failure(NotFoundFailure());
    }
    _subjects.remove(subjectId);
    _topics.removeWhere((_, topic) => topic.subjectId == subjectId);
    _sessions.removeWhere((_, session) => session.subjectId == subjectId);
    _notifyChanged();
    return const Result<void>.success(null);
  }

  // ------------------------------------------------------------------ topics

  @override
  Future<Result<List<Topic>>> getTopics({String? subjectId}) async {
    final topics =
        _topics.values
            .where((topic) => subjectId == null || topic.subjectId == subjectId)
            .toList()
          ..sort((a, b) {
            final byTitle = a.title.compareTo(b.title);
            return byTitle != 0 ? byTitle : a.id.compareTo(b.id);
          });
    return Result.success(topics);
  }

  @override
  Future<Result<Topic>> addTopic(Topic topic) async {
    if (!_subjects.containsKey(topic.subjectId)) {
      return const Result.failure(NotFoundFailure());
    }
    final now = _now();
    final saved = topic.copyWith(
      id: _nextId('topic'),
      createdAt: now,
      updatedAt: now,
    );
    _topics[saved.id] = saved;
    return Result.success(saved);
  }

  @override
  Future<Result<Topic>> updateTopic(Topic topic) async {
    final existing = _topics[topic.id];
    if (existing == null) {
      return const Result.failure(NotFoundFailure());
    }
    final saved = topic.copyWith(
      createdAt: existing.createdAt,
      updatedAt: _now(),
    );
    _topics[saved.id] = saved;
    return Result.success(saved);
  }

  @override
  Future<Result<void>> deleteTopic(String topicId) async {
    if (!_topics.containsKey(topicId)) {
      return const Result.failure(NotFoundFailure());
    }
    _topics.remove(topicId);
    _sessions.removeWhere((_, session) => session.topicId == topicId);
    _notifyChanged();
    return const Result<void>.success(null);
  }

  // ---------------------------------------------------------- plans/sessions

  @override
  Future<Result<void>> savePlan(
    StudyPlan plan,
    List<StudySession> sessions,
  ) async {
    if (sessions.any((session) => session.planId != plan.id)) {
      return const Result.failure(
        ValidationFailure(
          userMessage: 'Every session must belong to the plan being saved.',
        ),
      );
    }

    final now = _now();
    if (plan.status == PlanStatus.active) {
      _archiveActivePlans(now);
    }
    _plans[plan.id] = plan.copyWith(createdAt: now, updatedAt: now);
    for (final session in sessions) {
      _sessions[session.id] = session.copyWith(createdAt: now, updatedAt: now);
    }
    _notifyChanged();
    return const Result<void>.success(null);
  }

  /// Archives the active plan and removes its sessions that are still planned.
  void _archiveActivePlans(DateTime now) {
    for (final entry in _plans.entries.toList()) {
      if (entry.value.status != PlanStatus.active) {
        continue;
      }
      _plans[entry.key] = entry.value.copyWith(
        status: PlanStatus.archived,
        updatedAt: now,
      );
      _sessions.removeWhere(
        (_, session) =>
            session.planId == entry.key &&
            session.status == SessionStatus.planned,
      );
    }
  }

  @override
  Future<Result<StudyPlan?>> getActivePlan() async {
    for (final plan in _plans.values) {
      if (plan.status == PlanStatus.active) {
        return Result.success(plan);
      }
    }
    return const Result<StudyPlan?>.success(null);
  }

  @override
  Future<Result<List<StudySession>>> getSessionsForPlan(String planId) async {
    final sessions =
        _sessions.values.where((session) => session.planId == planId).toList()
          ..sort(_byStartThenId);
    return Result.success(sessions);
  }

  @override
  Stream<Result<List<StudySession>>> watchSessions({
    required String fromDateKey,
    required String toDateKey,
  }) {
    late final StreamController<Result<List<StudySession>>> controller;
    StreamSubscription<void>? subscription;

    controller = StreamController<Result<List<StudySession>>>(
      onListen: () {
        controller.add(_sessionsBetween(fromDateKey, toDateKey));
        subscription = _changes.stream.listen((_) {
          controller.add(_sessionsBetween(fromDateKey, toDateKey));
        });
      },
      onCancel: () => subscription?.cancel(),
    );
    return controller.stream;
  }

  /// `yyyy-MM-dd` strings sort in date order, so comparing them is enough.
  Result<List<StudySession>> _sessionsBetween(String from, String to) {
    final sessions =
        _sessions.values
            .where(
              (session) =>
                  session.dateKey.compareTo(from) >= 0 &&
                  session.dateKey.compareTo(to) <= 0,
            )
            .toList()
          ..sort(_byStartThenId);
    return Result.success(sessions);
  }

  int _byStartThenId(StudySession a, StudySession b) {
    final byStart = a.startAt.compareTo(b.startAt);
    return byStart != 0 ? byStart : a.id.compareTo(b.id);
  }

  @override
  Future<Result<StudySession>> updateSession(StudySession session) async {
    final existing = _sessions[session.id];
    if (existing == null) {
      return const Result.failure(NotFoundFailure());
    }
    final saved = session.copyWith(
      createdAt: existing.createdAt,
      updatedAt: _now(),
    );
    _sessions[saved.id] = saved;
    _notifyChanged();
    return Result.success(saved);
  }

  @override
  Future<Result<void>> deleteSession(String sessionId) async {
    if (_sessions.remove(sessionId) == null) {
      return const Result.failure(NotFoundFailure());
    }
    _notifyChanged();
    return const Result<void>.success(null);
  }

  // -------------------------------------------------- StudySessionCompletion

  @override
  Future<Result<void>> addActualMinutes({
    required String studySessionId,
    required int minutes,
  }) async {
    final existing = _sessions[studySessionId];
    if (existing == null) {
      return const Result.failure(NotFoundFailure());
    }
    if (minutes <= 0) {
      return const Result.failure(
        ValidationFailure(userMessage: 'Minutes must be greater than zero.'),
      );
    }
    _sessions[studySessionId] = existing.copyWith(
      actualMinutes: existing.actualMinutes + minutes,
      updatedAt: _now(),
    );
    _notifyChanged();
    return const Result<void>.success(null);
  }
}
