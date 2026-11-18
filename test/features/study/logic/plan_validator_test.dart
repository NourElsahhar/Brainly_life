import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

// Replace brainly_life with the `name:` value from pubspec.yaml.
import 'package:brainly_life/features/study/data/models/plan_constraints_model.dart';
import 'package:brainly_life/features/study/data/models/study_enums.dart';
import 'package:brainly_life/features/study/data/models/study_session_model.dart';
import 'package:brainly_life/features/study/data/models/topic_model.dart';
import 'package:brainly_life/features/study/logic/plan_validator.dart';
import 'package:brainly_life/features/study/logic/planner_types.dart';
import 'package:brainly_life/features/study/logic/rule_based_planner.dart';

// "Now" is Monday 2026-11-16 08:00 UTC in every test.
final _now = DateTime.utc(2026, 11, 16, 8);
final _firstDay = DateTime.utc(2026, 11, 16);

/// Test fixture only: consecutive days as the caller would build them.
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
}) {
  return PlanValidator(clock: Clock.fixed(_now)).validate(
    sessions: sessions,
    subjectIds: subjectIds,
    topics: topics ?? [_topic('t1', 's1'), _topic('t2', 's1')],
    examDateKeys: exams,
    constraints: constraints ?? _constraints(),
    days: _days(15),
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

      expect(result.types, {PlanViolationType.afterExamDay});
    });

    test('a session on the exam day itself is allowed by the validator', () {
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

  group('PlanValidator with RuleBasedPlanner output', () {
    String Function() ids() {
      var counter = 0;
      return () => 'session_${++counter}';
    }

    test('a plan made by the planner is always valid', () {
      final topics = [
        for (var i = 0; i < 12; i++)
          Topic(
            id: 't$i',
            subjectId: i.isEven ? 's1' : 's2',
            title: 't$i',
            difficulty: 1 + i % 5,
            estimatedMinutes: 40 + i * 25,
            status: TopicStatus.notStarted,
            completedMinutes: 0,
          ),
      ];
      final exams = {'s1': '2026-11-27', 's2': '2026-11-22'};
      final constraints = _constraints(daysOff: {7});

      final planned = const RuleBasedPlanner().plan(
        planId: 'plan_1',
        topics: topics,
        examDateKeys: exams,
        constraints: constraints,
        days: _days(15),
        newSessionId: ids(),
      );
      final result = PlanValidator(clock: Clock.fixed(_now)).validate(
        sessions: planned.sessions,
        subjectIds: const {'s1', 's2'},
        topics: topics,
        examDateKeys: exams,
        constraints: constraints,
        days: _days(15),
      );

      expect(planned.sessions, isNotEmpty);
      expect(result.isValid, isTrue);
    });

    test('a partial plan (not everything fits) is still valid', () {
      final topics = [for (var i = 0; i < 40; i++) _topic('t$i', 's1')];
      final exams = {'s1': '2026-12-01'};

      final planned = const RuleBasedPlanner().plan(
        planId: 'plan_1',
        topics: topics,
        examDateKeys: exams,
        constraints: _constraints(),
        days: _days(15),
        newSessionId: ids(),
      );
      final result = PlanValidator(clock: Clock.fixed(_now)).validate(
        sessions: planned.sessions,
        subjectIds: const {'s1'},
        topics: topics,
        examDateKeys: exams,
        constraints: _constraints(),
        days: _days(15),
      );

      expect(planned.isComplete, isFalse);
      expect(result.isValid, isTrue);
    });
  });
}
