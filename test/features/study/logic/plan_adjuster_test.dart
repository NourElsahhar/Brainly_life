import 'package:brainly_life/features/study/data/models/plan_constraints_model.dart';
import 'package:brainly_life/features/study/data/models/study_enums.dart';
import 'package:brainly_life/features/study/data/models/study_session_model.dart';
import 'package:brainly_life/features/study/data/models/topic_model.dart';
import 'package:brainly_life/features/study/logic/plan_adjuster.dart';
import 'package:brainly_life/features/study/logic/plan_validator.dart';
import 'package:brainly_life/features/study/logic/planner_types.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

// "Now" is Tuesday 2026-11-17 12:00 UTC in every test.
final _now = DateTime.utc(2026, 11, 17, 12);
final _firstDay = DateTime.utc(2026, 11, 17);
const _exams = {'s1': '2026-11-25'};

/// Test fixture only: consecutive days starting today, as the caller would
/// build them with DateKeyUtils.
List<PlannerDay> _days(int count) {
  return [
    for (var i = 0; i < count; i++)
      () {
        final date = _firstDay.add(Duration(days: i));
        final month = date.month.toString().padLeft(2, '0');
        final day = date.day.toString().padLeft(2, '0');
        return PlannerDay(
          dateKey: '${date.year}-$month-$day',
          weekday: date.weekday,
          startAt: DateTime.utc(date.year, date.month, date.day, 17),
        );
      }(),
  ];
}

PlanConstraints _constraints({int minutesPerDay = 120}) {
  return PlanConstraints(
    minutesPerWeekday: {for (var d = 1; d <= 7; d++) d: minutesPerDay},
    daysOff: const {},
    maxSessionMinutes: 60,
    breakMinutes: 10,
  );
}

Topic _topic({
  int estimated = 300,
  int completed = 60,
  TopicStatus status = TopicStatus.inProgress,
}) {
  return Topic(
    id: 't1',
    subjectId: 's1',
    title: 't1',
    difficulty: 3,
    estimatedMinutes: estimated,
    status: status,
    completedMinutes: completed,
  );
}

StudySession _session(
  String id,
  String dateKey,
  DateTime startAt, {
  SessionStatus status = SessionStatus.planned,
}) {
  return StudySession(
    id: id,
    planId: 'plan_1',
    subjectId: 's1',
    topicId: 't1',
    dateKey: dateKey,
    startAt: startAt,
    plannedMinutes: 60,
    status: status,
  );
}

/// A plan the user fell behind on.
List<StudySession> _planSessions() {
  return [
    // Over, never done: will be marked missed.
    _session('p1', '2026-11-16', DateTime.utc(2026, 11, 16, 17)),
    _session('p2', '2026-11-17', DateTime.utc(2026, 11, 17, 9)),
    // Happening right now (11:30 to 12:30): left alone.
    _session('p3', '2026-11-17', DateTime.utc(2026, 11, 17, 11, 30)),
    // Not started yet: removed and planned again.
    _session('p4', '2026-11-17', DateTime.utc(2026, 11, 17, 17)),
    _session('p5', '2026-11-18', DateTime.utc(2026, 11, 18, 17)),
    // History: never touched.
    _session(
      'done1',
      '2026-11-16',
      DateTime.utc(2026, 11, 16, 15),
      status: SessionStatus.done,
    ),
    _session(
      'skip1',
      '2026-11-16',
      DateTime.utc(2026, 11, 16, 16),
      status: SessionStatus.skipped,
    ),
    _session(
      'miss0',
      '2026-11-15',
      DateTime.utc(2026, 11, 15, 17),
      status: SessionStatus.missed,
    ),
  ];
}

String Function() _ids(String prefix) {
  var counter = 0;
  return () => '${prefix}_${++counter}';
}

AdjustmentResult _adjust({
  List<StudySession>? sessions,
  Topic? topic,
  PlanConstraints? constraints,
  String Function()? ids,
}) {
  return PlanAdjuster(clock: Clock.fixed(_now)).adjust(
    planId: 'plan_1',
    sessions: sessions ?? _planSessions(),
    topics: [topic ?? _topic()],
    examDateKeys: _exams,
    constraints: constraints ?? _constraints(),
    days: _days(10),
    newSessionId: ids ?? _ids('new'),
  );
}

int _sum(Iterable<StudySession> sessions) {
  return sessions.fold(0, (total, s) => total + s.plannedMinutes);
}

void main() {
  group('PlanAdjuster', () {
    test('planned sessions whose time is over become missed', () {
      final result = _adjust();

      expect(
        result.missedSessions.map((s) => s.id),
        unorderedEquals(['p1', 'p2']),
      );
      expect(
        result.missedSessions.every((s) => s.status == SessionStatus.missed),
        isTrue,
      );
    });

    test('a missed session keeps all its other fields', () {
      final result = _adjust();
      final original = _planSessions().firstWhere((s) => s.id == 'p1');
      final missed = result.missedSessions.firstWhere((s) => s.id == 'p1');

      expect(missed, original.copyWith(status: SessionStatus.missed));
    });

    test('planned sessions that have not started are removed', () {
      final result = _adjust();

      expect(result.removedSessionIds, unorderedEquals(['p4', 'p5']));
    });

    test('a session happening right now is left alone', () {
      final result = _adjust();

      expect(result.missedSessions.any((s) => s.id == 'p3'), isFalse);
      expect(result.removedSessionIds.contains('p3'), isFalse);
    });

    test('done, skipped and already missed sessions are never touched', () {
      final result = _adjust();
      const history = ['done1', 'skip1', 'miss0'];

      expect(result.missedSessions.any((s) => history.contains(s.id)), isFalse);
      expect(
        result.removedSessionIds.any((id) => history.contains(id)),
        isFalse,
      );
    });

    test('all remaining minutes are planned again, missed ones included', () {
      // 300 estimated, 60 completed: 240 left. The two missed sessions did
      // not reduce it, so they are planned again.
      final result = _adjust();

      expect(_sum(result.newSessions), 240);
      expect(result.isComplete, isTrue);
      expect(
        result.newSessions.every((s) => s.dateKey.compareTo('2026-11-17') >= 0),
        isTrue,
      );
    });

    test('new sessions use the given ids and belong to the plan', () {
      final result = _adjust();

      expect(result.newSessions.map((s) => s.id).toSet(), hasLength(4));
      expect(result.newSessions.every((s) => s.id.startsWith('new_')), isTrue);
      expect(result.newSessions.every((s) => s.planId == 'plan_1'), isTrue);
    });

    test('with no available time everything is reported as unscheduled', () {
      final result = _adjust(constraints: _constraints(minutesPerDay: 0));

      expect(result.newSessions, isEmpty);
      expect(result.unscheduledMinutes, {'t1': 240});
      expect(result.missedSessions, hasLength(2));
      expect(result.removedSessionIds, hasLength(2));
    });

    test('when the topic is finished nothing new is planned', () {
      final result = _adjust(
        topic: _topic(completed: 300, status: TopicStatus.done),
      );

      expect(result.newSessions, isEmpty);
      expect(result.isComplete, isTrue);
      expect(result.missedSessions, hasLength(2));
    });

    test(
      'a plan with nothing to repair only gets its remaining work planned',
      () {
        final result = _adjust(
          sessions: [
            _session(
              'd',
              '2026-11-16',
              DateTime.utc(2026, 11, 16, 15),
              status: SessionStatus.done,
            ),
          ],
        );

        expect(result.missedSessions, isEmpty);
        expect(result.removedSessionIds, isEmpty);
        expect(_sum(result.newSessions), 240);
      },
    );

    test('the new sessions are accepted by the validator', () {
      final result = _adjust();

      final validation = PlanValidator(clock: Clock.fixed(_now)).validate(
        sessions: result.newSessions,
        subjectIds: const {'s1'},
        topics: [_topic()],
        examDateKeys: _exams,
        constraints: _constraints(),
        days: _days(10),
      );

      expect(validation.isValid, isTrue);
    });

    test('adjusting again right after changes nothing else', () {
      final first = _adjust();
      final missedById = {for (final s in first.missedSessions) s.id: s};
      final afterFirst = [
        for (final s in _planSessions())
          if (!first.removedSessionIds.contains(s.id)) missedById[s.id] ?? s,
        ...first.newSessions,
      ];

      final second = _adjust(sessions: afterFirst, ids: _ids('again'));

      expect(second.missedSessions, isEmpty);
      expect(
        second.removedSessionIds,
        unorderedEquals(first.newSessions.map((s) => s.id)),
      );
      expect(_sum(second.newSessions), 240);
    });
  });
}
