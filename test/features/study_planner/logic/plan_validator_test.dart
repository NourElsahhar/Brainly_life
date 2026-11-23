import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brainly_life/features/study_planner/data/models/plan_constraints_model.dart';
import 'package:brainly_life/features/study_planner/data/models/study_enums.dart';
import 'package:brainly_life/features/study_planner/data/models/study_session_model.dart';
import 'package:brainly_life/features/study_planner/data/models/topic_model.dart';
import 'package:brainly_life/features/study_planner/logic/plan_validator.dart';
import 'package:brainly_life/features/study_planner/logic/planner_types.dart';

// "Now" is Monday 2026-11-16 08:00 UTC in every test.
final _now = DateTime.utc(2026, 11, 16, 8);

/// The plan may use Monday 16 to Monday 30 November 2026.
final _days = PlannerDay.range('2026-11-16', '2026-11-30');

PlanConstraints _constraints({
  int minutesPerDay = 120,
  Set<int> daysOff = const {},
  int maxSession = 60,
}) {
  return PlanConstraints(
    minutesPerWeekday: {for (var d = 1; d <= 7; d++) d: minutesPerDay},
    daysOff: daysOff,
    maxSessionMinutes: maxSession,
    breakMinutes: 10,
  );
}

Topic _topic(String id, String subjectId) {
  return Topic(
    id: id,
    subjectId: subjectId,
    title: id,
    difficulty: 3,
    estimatedMinutes: 120,
    status: TopicStatus.notStarted,
    completedMinutes: 0,
  );
}

/// Tuesday 2026-11-17 at 17:00 unless told otherwise.
StudySession _session(
  String id, {
  String subjectId = 's1',
  String topicId = 't1',
  String dateKey = '2026-11-17',
  DateTime? startAt,
  int minutes = 60,
  SessionStatus status = SessionStatus.planned,
}) {
  return StudySession(
    id: id,
    planId: 'plan_1',
    subjectId: subjectId,
    topicId: topicId,
    dateKey: dateKey,
    startAt: startAt ?? DateTime.utc(2026, 11, 17, 17),
    plannedMinutes: minutes,
    status: status,
  );
}

PlanValidationResult _validate(
  List<StudySession> sessions, {
  Set<String> subjectIds = const {'s1'},
  List<Topic>? topics,
  Map<String, String> exams = const {'s1': '2026-11-25'},
  PlanConstraints? constraints,
  List<StudySession> existing = const [],
}) {
  return PlanValidator(clock: Clock.fixed(_now)).validate(
    sessions: sessions,
    subjectIds: subjectIds,
    topics: topics ?? [_topic('t1', 's1'), _topic('t2', 's1')],
    examDateKeys: exams,
    constraints: constraints ?? _constraints(),
    days: _days,
    existingSessions: existing,
  );
}

void main() {
  group('PlanValidator', () {
    test('an empty plan is valid', () {
      expect(_validate([]).isValid, isTrue);
    });

    test('a correct plan is valid', () {
      final result = _validate([
        _session('a'),
        _session('b', startAt: DateTime.utc(2026, 11, 17, 18, 10)),
      ]);

      expect(result.isValid, isTrue);
    });

    test('a planned session in the past is rejected', () {
      final result = _validate([
        _session(
          'a',
          dateKey: '2026-11-16',
          startAt: DateTime.utc(2026, 11, 16, 7),
        ),
      ]);

      expect(result.types, {PlanViolationType.sessionInPast});
    });

    test('a finished session in the past is not a problem', () {
      final result = _validate([
        _session(
          'a',
          dateKey: '2026-11-16',
          startAt: DateTime.utc(2026, 11, 16, 7),
          status: SessionStatus.done,
        ),
      ]);

      expect(result.isValid, isTrue);
    });

    test('overlapping sessions are rejected', () {
      final result = _validate([
        _session('a'),
        _session('b', startAt: DateTime.utc(2026, 11, 17, 17, 30)),
      ]);

      expect(result.types, {PlanViolationType.overlappingSessions});
      expect(result.violations.single.sessionId, 'b');
    });

    test('back to back sessions are allowed', () {
      final result = _validate([
        _session('a'),
        _session('b', startAt: DateTime.utc(2026, 11, 17, 18)),
      ]);

      expect(result.isValid, isTrue);
    });

    test('a day above its daily limit is rejected', () {
      final result = _validate([
        _session('a'),
        _session('b', startAt: DateTime.utc(2026, 11, 17, 18, 10)),
        _session('c', startAt: DateTime.utc(2026, 11, 17, 19, 20)),
      ]);

      expect(result.types, {PlanViolationType.dailyLimitExceeded});
      expect(result.violations.single.dateKey, '2026-11-17');
    });

    test('a session on a day off is rejected', () {
      // 2026-11-17 is a Tuesday, weekday 2.
      final result = _validate([
        _session('a'),
      ], constraints: _constraints(daysOff: {2}));

      expect(result.types, {PlanViolationType.dayOff});
    });

    test('a session on a day outside the plan is rejected', () {
      final result = _validate([
        _session(
          'a',
          dateKey: '2026-12-31',
          startAt: DateTime.utc(2026, 12, 31, 17),
        ),
      ], exams: const {});

      expect(result.types, {PlanViolationType.dateOutsidePlanDays});
    });

    test('a session shorter than 10 minutes is rejected', () {
      final result = _validate([_session('a', minutes: 9)]);

      expect(result.types, {PlanViolationType.durationOutOfRange});
    });

    test('a session longer than 180 minutes is rejected', () {
      final result = _validate([
        _session('a', minutes: 181),
      ], constraints: _constraints(minutesPerDay: 300, maxSession: 300));

      expect(result.types, {PlanViolationType.durationOutOfRange});
    });

    test('a session longer than the user max session is rejected', () {
      final result = _validate([
        _session('a', minutes: 60),
      ], constraints: _constraints(maxSession: 45));

      expect(result.types, {PlanViolationType.exceedsMaxSession});
    });

    test('a session for an unknown subject is rejected', () {
      final result = _validate(
        [_session('a', subjectId: 'ghost', topicId: 'tg')],
        topics: [_topic('tg', 'ghost')],
      );

      expect(result.types, {PlanViolationType.unknownSubject});
    });

    test('a session for an unknown topic is rejected', () {
      final result = _validate([_session('a', topicId: 'ghost')]);

      expect(result.types, {PlanViolationType.unknownTopic});
    });

    test('a topic that belongs to another subject is rejected', () {
      final result = _validate(
        [_session('a', subjectId: 's2', topicId: 't1')],
        subjectIds: const {'s1', 's2'},
      );

      expect(result.types, {PlanViolationType.topicSubjectMismatch});
    });

    test('a session after the exam day is rejected', () {
      // 2026-11-21 is a Saturday.
      final result = _validate(
        [
          _session(
            'a',
            dateKey: '2026-11-21',
            startAt: DateTime.utc(2026, 11, 21, 17),
          ),
        ],
        exams: const {'s1': '2026-11-20'},
      );

      expect(result.types, {PlanViolationType.onOrAfterExamDay});
    });

    test('a session on the exam day itself is rejected', () {
      // Only the exam day is known, not its time.
      final result = _validate(
        [
          _session(
            'a',
            dateKey: '2026-11-20',
            startAt: DateTime.utc(2026, 11, 20, 17),
          ),
        ],
        exams: const {'s1': '2026-11-20'},
      );

      expect(result.types, {PlanViolationType.onOrAfterExamDay});
    });

    test('a session the day before the exam is allowed', () {
      final result = _validate(
        [
          _session(
            'a',
            dateKey: '2026-11-19',
            startAt: DateTime.utc(2026, 11, 19, 17),
          ),
        ],
        exams: const {'s1': '2026-11-20'},
      );

      expect(result.isValid, isTrue);
    });

    test('every problem is reported, not only the first', () {
      final result = _validate([
        _session(
          'a',
          minutes: 5,
          dateKey: '2026-11-16',
          startAt: DateTime.utc(2026, 11, 16, 7),
        ),
      ]);

      expect(result.types, {
        PlanViolationType.durationOutOfRange,
        PlanViolationType.sessionInPast,
      });
    });
  });

  group('PlanValidator with existing sessions', () {
    StudySession kept(
      String id, {
      int hour = 9,
      int minutes = 60,
      SessionStatus status = SessionStatus.done,
      String topicId = 't1',
    }) {
      return _session(
        id,
        topicId: topicId,
        startAt: DateTime.utc(2026, 11, 17, hour),
        minutes: minutes,
        status: status,
      );
    }

    test('their minutes count for the daily limit', () {
      final newSessions = [
        _session('a'),
        _session('b', startAt: DateTime.utc(2026, 11, 17, 18, 10)),
      ];

      // 120 minutes fit the 120-minute day on their own...
      expect(_validate(newSessions).isValid, isTrue);

      // ...but not after a 60-minute session done earlier that day.
      final result = _validate(newSessions, existing: [kept('kept')]);

      expect(result.types, {PlanViolationType.dailyLimitExceeded});
      expect(result.violations.single.dateKey, '2026-11-17');
    });

    test('a new session overlapping one of them is reported', () {
      final later = _validate(
        [_session('a', startAt: DateTime.utc(2026, 11, 17, 17, 30))],
        existing: [kept('kept', hour: 17)],
      );
      final earlier = _validate(
        [_session('a', startAt: DateTime.utc(2026, 11, 17, 16, 30))],
        existing: [kept('kept', hour: 17)],
      );

      for (final result in [later, earlier]) {
        expect(result.types, {PlanViolationType.overlappingSessions});
        expect(result.violations.single.sessionId, 'a');
      }
    });

    test('they are not checked themselves', () {
      // A planned session in the past, with an unknown topic.
      final result = _validate(
        [_session('a')],
        existing: [
          _session(
            'old',
            topicId: 'ghost',
            dateKey: '2026-11-16',
            startAt: DateTime.utc(2026, 11, 16, 7),
          ),
        ],
      );

      expect(result.isValid, isTrue);
    });

    test('skipped and missed sessions take no time', () {
      final result = _validate(
        [_session('a'), _session('b', startAt: DateTime.utc(2026, 11, 17, 18))],
        existing: [
          kept('skipped', hour: 17, status: SessionStatus.skipped),
          kept('missed', hour: 17, minutes: 120, status: SessionStatus.missed),
        ],
      );

      expect(result.isValid, isTrue);
    });
  });

  group('PlannerDay.range', () {
    test('lists every day with its weekday, both ends included', () {
      final days = PlannerDay.range('2026-11-16', '2026-11-22');

      expect(days.map((d) => d.dateKey), [
        '2026-11-16',
        '2026-11-17',
        '2026-11-18',
        '2026-11-19',
        '2026-11-20',
        '2026-11-21',
        '2026-11-22',
      ]);
      // Monday 16 to Sunday 22.
      expect(days.map((d) => d.weekday), [1, 2, 3, 4, 5, 6, 7]);
    });

    test('crosses the end of a month and a year', () {
      final days = PlannerDay.range('2026-12-30', '2027-01-02');

      expect(days.map((d) => d.dateKey), [
        '2026-12-30',
        '2026-12-31',
        '2027-01-01',
        '2027-01-02',
      ]);
    });

    test('one day, and nothing when the end is before the start', () {
      expect(PlannerDay.range('2026-11-16', '2026-11-16'), hasLength(1));
      expect(PlannerDay.range('2026-11-16', '2026-11-15'), isEmpty);
    });
  });
}
