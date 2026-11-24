import 'package:brainly_life/features/study_planner/data/models/study_enums.dart';
import 'package:brainly_life/features/study_planner/logic/local_time.dart';
import 'package:brainly_life/features/study_planner/logic/study_plan_response_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = StudyPlanResponseParser(timezone: 'Africa/Cairo');
  var counter = 0;
  String nextId() => 'session_${++counter}';

  setUp(() => counter = 0);

  Map<String, Object?> session({
    Object? date = '2026-11-21',
    Object? startTime = '16:30',
    Object? plannedMinutes = 45,
  }) => {
    'subjectId': 'physics',
    'topicId': 'waves',
    'date': date,
    'startTime': startTime,
    'plannedMinutes': plannedMinutes,
  };

  test('turns the AI sessions into planned StudySessions', () {
    final sessions = parser.parse(
      {
        'sessions': [session(), session(startTime: '18:00')],
      },
      planId: 'plan_1',
      newSessionId: nextId,
    );

    expect(sessions, hasLength(2));
    final first = sessions.first;
    expect(first.id, 'session_1');
    expect(first.planId, 'plan_1');
    expect(first.subjectId, 'physics');
    expect(first.topicId, 'waves');
    expect(first.dateKey, '2026-11-21');
    // 16:30 in Cairo (UTC+2) is 14:30 UTC.
    expect(first.startAt, DateTime.utc(2026, 11, 21, 14, 30));
    expect(first.plannedMinutes, 45);
    expect(first.status, SessionStatus.planned);
    expect(sessions.last.id, 'session_2');
  });

  test('rejects answers with the wrong shape', () {
    final bad = <Map<String, Object?>>[
      {},
      {'sessions': <Object?>[]},
      {'sessions': 'none'},
      {
        'sessions': [42],
      },
      {
        'sessions': [session(date: '2026-02-30')],
      },
      {
        'sessions': [session(date: null)],
      },
      {
        'sessions': [session(startTime: '25:00')],
      },
      {
        'sessions': [session(plannedMinutes: '45')],
      },
    ];

    for (final data in bad) {
      expect(
        () => parser.parse(data, planId: 'p', newSessionId: nextId),
        throwsFormatException,
        reason: '$data',
      );
    }
  });

  group('LocalTime', () {
    test('parses and formats HH:mm', () {
      expect(LocalTime.parseTime('00:00'), 0);
      expect(LocalTime.parseTime('23:59'), 1439);
      expect(LocalTime.parseTime('7:00'), isNull);
      expect(LocalTime.formatTime(16 * 60 + 5), '16:05');
    });

    test('minuteOfDay is the local time of a moment', () {
      expect(
        LocalTime.minuteOfDay(
          DateTime.utc(2026, 11, 20, 22, 30),
          timezone: 'Africa/Cairo',
        ),
        30, // 00:30 on 21 Nov in Cairo
      );
    });
  });
}