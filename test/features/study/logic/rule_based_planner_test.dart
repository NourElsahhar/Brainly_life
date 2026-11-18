import 'package:flutter_test/flutter_test.dart';

// Replace brainly_life with the `name:` value from pubspec.yaml.
import 'package:brainly_life/features/study/data/models/plan_constraints_model.dart';
import 'package:brainly_life/features/study/data/models/study_enums.dart';
import 'package:brainly_life/features/study/data/models/study_session_model.dart';
import 'package:brainly_life/features/study/data/models/topic_model.dart';
import 'package:brainly_life/features/study/logic/planner_types.dart';
import 'package:brainly_life/features/study/logic/rule_based_planner.dart';

// Monday 2026-11-16 is "today" in every test.
final _firstDay = DateTime.utc(2026, 11, 16);

/// Test fixture only: builds consecutive days the way the caller would with
/// DateKeyUtils. The planner itself never does this.
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
  int breakMinutes = 10,
}) {
  return PlanConstraints(
    minutesPerWeekday: {for (var d = 1; d <= 7; d++) d: minutesPerDay},
    daysOff: daysOff,
    maxSessionMinutes: maxSession,
    breakMinutes: breakMinutes,
  );
}

Topic _topic(
  String id, {
  String subjectId = 's1',
  int difficulty = 3,
  int estimated = 120,
  int completed = 0,
  TopicStatus status = TopicStatus.notStarted,
}) {
  return Topic(
    id: id,
    subjectId: subjectId,
    title: id,
    difficulty: difficulty,
    estimatedMinutes: estimated,
    status: status,
    completedMinutes: completed,
  );
}

String Function() _idGenerator() {
  var counter = 0;
  return () => 'session_${++counter}';
}

PlannerResult _plan({
  required List<Topic> topics,
  required Map<String, String> exams,
  required PlanConstraints constraints,
  required int dayCount,
}) {
  return const RuleBasedPlanner().plan(
    planId: 'plan_1',
    topics: topics,
    examDateKeys: exams,
    constraints: constraints,
    days: _days(dayCount),
    newSessionId: _idGenerator(),
  );
}

int _sum(Iterable<StudySession> sessions) {
  return sessions.fold(0, (total, s) => total + s.plannedMinutes);
}

void main() {
  group('RuleBasedPlanner', () {
    test(
      'exam tomorrow: everything goes into today, never on the exam day',
      () {
        final result = _plan(
          topics: [_topic('t1', estimated: 120)],
          exams: {'s1': '2026-11-17'},
          constraints: _constraints(),
          dayCount: 2,
        );

        expect(result.sessions.map((s) => s.dateKey).toSet(), {'2026-11-16'});
        expect(_sum(result.sessions), 120);
        expect(result.isComplete, isTrue);
      },
    );

    test('exam tomorrow with too much work reports what did not fit', () {
      final result = _plan(
        topics: [_topic('t1', estimated: 300)],
        exams: {'s1': '2026-11-17'},
        constraints: _constraints(),
        dayCount: 2,
      );

      expect(_sum(result.sessions), 120);
      expect(result.unscheduledMinutes, {'t1': 180});
      expect(result.isComplete, isFalse);
    });

    test('zero available hours creates no sessions', () {
      final result = _plan(
        topics: [_topic('t1')],
        exams: {'s1': '2026-11-25'},
        constraints: _constraints(minutesPerDay: 0),
        dayCount: 10,
      );

      expect(result.sessions, isEmpty);
      expect(result.unscheduledMinutes, {'t1': 120});
    });

    test('all days off creates no sessions', () {
      final result = _plan(
        topics: [_topic('t1')],
        exams: {'s1': '2026-11-25'},
        constraints: _constraints(daysOff: {1, 2, 3, 4, 5, 6, 7}),
        dayCount: 10,
      );

      expect(result.sessions, isEmpty);
      expect(result.unscheduledMinutes, {'t1': 120});
    });

    test('a day off is skipped even when it has minutes', () {
      final result = _plan(
        topics: [_topic('t1', estimated: 240)],
        exams: {'s1': '2026-11-30'},
        // Monday 2026-11-16 is weekday 1.
        constraints: _constraints(daysOff: {1}),
        dayCount: 10,
      );

      expect(result.sessions.any((s) => s.dateKey == '2026-11-16'), isFalse);
      expect(_sum(result.sessions), 240);
    });

    test('done topics and finished topics are ignored', () {
      final result = _plan(
        topics: [
          _topic('done', status: TopicStatus.done),
          _topic('finished', estimated: 90, completed: 90),
        ],
        exams: {'s1': '2026-11-25'},
        constraints: _constraints(),
        dayCount: 10,
      );

      expect(result.sessions, isEmpty);
      expect(result.isComplete, isTrue);
    });

    test('only the remaining minutes of a started topic are planned', () {
      final result = _plan(
        topics: [
          _topic(
            't1',
            estimated: 120,
            completed: 60,
            status: TopicStatus.inProgress,
          ),
        ],
        exams: {'s1': '2026-11-25'},
        constraints: _constraints(),
        dayCount: 10,
      );

      expect(_sum(result.sessions), 60);
    });

    test('nothing is scheduled on or after the exam day', () {
      final result = _plan(
        topics: [_topic('t1', estimated: 600)],
        exams: {'s1': '2026-11-20'},
        constraints: _constraints(),
        dayCount: 10,
      );

      expect(
        result.sessions.every((s) => s.dateKey.compareTo('2026-11-20') < 0),
        isTrue,
      );
    });

    test('the buffer day before the exam stays free when the work fits', () {
      final result = _plan(
        topics: [_topic('t1', estimated: 240)],
        exams: {'s1': '2026-11-20'},
        constraints: _constraints(),
        dayCount: 7,
      );

      expect(
        result.sessions.every((s) => s.dateKey.compareTo('2026-11-19') < 0),
        isTrue,
      );
      expect(result.isComplete, isTrue);
    });

    test('the buffer day is used only for work that does not fit earlier', () {
      final result = _plan(
        topics: [_topic('t1', estimated: 500)],
        exams: {'s1': '2026-11-20'},
        constraints: _constraints(),
        dayCount: 7,
      );

      final bufferDay = result.sessions.where((s) => s.dateKey == '2026-11-19');
      expect(_sum(bufferDay), 120);
      expect(result.sessions.any((s) => s.dateKey == '2026-11-20'), isFalse);
      expect(result.unscheduledMinutes, {'t1': 20});
    });

    test('a day never gets more minutes than its daily limit', () {
      final result = _plan(
        topics: [for (var i = 0; i < 10; i++) _topic('t$i', estimated: 90)],
        exams: {'s1': '2026-12-01'},
        constraints: _constraints(),
        dayCount: 15,
      );

      final perDay = <String, int>{};
      for (final s in result.sessions) {
        perDay[s.dateKey] = (perDay[s.dateKey] ?? 0) + s.plannedMinutes;
      }
      expect(perDay.values.every((minutes) => minutes <= 120), isTrue);
      expect(_sum(result.sessions), 900);
      expect(result.isComplete, isTrue);
    });

    test(
      'very many topics: scheduled plus unscheduled equals the workload',
      () {
        final result = _plan(
          topics: [
            for (var i = 0; i < 40; i++)
              _topic('t${i.toString().padLeft(2, '0')}', estimated: 60),
          ],
          exams: {'s1': '2026-12-01'},
          constraints: _constraints(),
          dayCount: 15,
        );

        final unscheduled = result.unscheduledMinutes.values.fold<int>(
          0,
          (total, minutes) => total + minutes,
        );
        expect(_sum(result.sessions), 1800);
        expect(unscheduled, 600);
        expect(_sum(result.sessions) + unscheduled, 2400);
      },
    );

    test('sessions respect maxSessionMinutes and the 10 minute minimum', () {
      final result = _plan(
        topics: [_topic('t1', estimated: 200)],
        exams: {'s1': '2026-11-30'},
        constraints: _constraints(maxSession: 45),
        dayCount: 10,
      );

      expect(
        result.sessions.every(
          (s) => s.plannedMinutes >= 10 && s.plannedMinutes <= 45,
        ),
        isTrue,
      );
      expect(_sum(result.sessions), 200);
    });

    test(
      'a leftover below 10 minutes is rounded up to a 10 minute session',
      () {
        final result = _plan(
          topics: [_topic('t1', estimated: 125, completed: 120)],
          exams: {'s1': '2026-11-25'},
          constraints: _constraints(),
          dayCount: 10,
        );

        expect(result.sessions.single.plannedMinutes, 10);
        expect(result.isComplete, isTrue);
      },
    );

    test('the topic with the nearer exam is planned first', () {
      final result = _plan(
        topics: [
          _topic('far', subjectId: 'sA'),
          _topic('near', subjectId: 'sB'),
        ],
        exams: {'sA': '2026-11-25', 'sB': '2026-11-19'},
        constraints: _constraints(minutesPerDay: 60),
        dayCount: 15,
      );

      expect(result.sessions.first.topicId, 'near');
    });

    test('with the same exam, the harder topic is planned first', () {
      final result = _plan(
        topics: [
          _topic('easy', difficulty: 2, estimated: 60),
          _topic('hard', difficulty: 5, estimated: 60),
        ],
        exams: {'s1': '2026-11-30'},
        constraints: _constraints(minutesPerDay: 60),
        dayCount: 15,
      );

      expect(result.sessions.first.topicId, 'hard');
    });

    test('sessions on the same day are separated by the break', () {
      final result = _plan(
        topics: [_topic('t1', estimated: 120)],
        exams: {'s1': '2026-11-25'},
        constraints: _constraints(breakMinutes: 10),
        dayCount: 10,
      );

      expect(result.sessions[0].startAt, DateTime.utc(2026, 11, 16, 17));
      expect(result.sessions[1].startAt, DateTime.utc(2026, 11, 16, 18, 10));
    });

    test('a topic whose exam is today or unknown cannot be scheduled', () {
      final result = _plan(
        topics: [
          _topic('today', subjectId: 'sA'),
          _topic('unknown', subjectId: 'sB'),
        ],
        exams: {'sA': '2026-11-16'},
        constraints: _constraints(),
        dayCount: 10,
      );

      expect(result.sessions, isEmpty);
      expect(result.unscheduledMinutes, {'today': 120, 'unknown': 120});
    });

    test('new sessions are planned, unique and linked to the plan', () {
      final result = _plan(
        topics: [_topic('t1', estimated: 240)],
        exams: {'s1': '2026-11-25'},
        constraints: _constraints(),
        dayCount: 10,
      );

      expect(result.sessions.every((s) => s.planId == 'plan_1'), isTrue);
      expect(
        result.sessions.every((s) => s.status == SessionStatus.planned),
        isTrue,
      );
      expect(result.sessions.every((s) => s.actualMinutes == 0), isTrue);
      expect(
        result.sessions.map((s) => s.id).toSet().length,
        result.sessions.length,
      );
    });

    test('the same input always gives the same plan', () {
      List<StudySession> run() => _plan(
        topics: [
          _topic('a', difficulty: 4, estimated: 150),
          _topic('b', difficulty: 2, estimated: 90),
          _topic('c', subjectId: 's2', estimated: 200),
        ],
        exams: {'s1': '2026-11-27', 's2': '2026-11-22'},
        constraints: _constraints(),
        dayCount: 15,
      ).sessions;

      expect(run(), run());
    });
  });
}
