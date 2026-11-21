import 'package:brainly_life/features/study_planner/data/models/study_enums.dart';
import 'package:brainly_life/features/study_planner/data/models/study_session_model.dart';
import 'package:brainly_life/features/study_planner/data/models/topic_model.dart';
import 'package:brainly_life/features/study_planner/logic/plan_adjuster.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

// "Now" is Tuesday 2026-11-17 12:00 UTC in every test, and the user's
// timezone is UTC unless a test says otherwise, so "today" is 2026-11-17.
final _now = DateTime.utc(2026, 11, 17, 12);

Topic _topic({
  String id = 't1',
  int estimated = 300,
  int completed = 60,
  TopicStatus status = TopicStatus.inProgress,
}) {
  return Topic(
    id: id,
    subjectId: 's1',
    title: id,
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
    // Happening right now (11:30 to 12:30): left alone, booked time.
    _session('p3', '2026-11-17', DateTime.utc(2026, 11, 17, 11, 30)),
    // Not started yet: removed, the AI plans this work again.
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

PlanAdjustment _adjust({
  List<StudySession>? sessions,
  List<Topic>? topics,
  DateTime? now,
  String timezone = 'UTC',
}) {
  return PlanAdjuster(
    clock: Clock.fixed(now ?? _now),
    timezone: timezone,
  ).adjust(sessions: sessions ?? _planSessions(), topics: topics ?? [_topic()]);
}

void main() {
  group('PlanAdjuster sessions', () {
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

    test('a session happening right now is left alone as booked time', () {
      final result = _adjust();

      expect(result.missedSessions.any((s) => s.id == 'p3'), isFalse);
      expect(result.removedSessionIds.contains('p3'), isFalse);
      expect(result.bookedSessions.map((s) => s.id), ['p3']);
      expect(result.bookedMinutesByDate, {'2026-11-17': 60});
    });

    test('done, skipped and already missed sessions are never touched', () {
      final result = _adjust();
      const history = ['done1', 'skip1', 'miss0'];

      expect(result.missedSessions.any((s) => history.contains(s.id)), isFalse);
      expect(
        result.removedSessionIds.any((id) => history.contains(id)),
        isFalse,
      );
      expect(result.bookedSessions.any((s) => history.contains(s.id)), isFalse);
    });

    test('a session that ends exactly now is missed', () {
      final result = _adjust(
        sessions: [_session('a', '2026-11-17', DateTime.utc(2026, 11, 17, 11))],
      );

      expect(result.missedSessions.map((s) => s.id), ['a']);
    });

    test('a session that starts exactly now is removed', () {
      final result = _adjust(
        sessions: [_session('a', '2026-11-17', DateTime.utc(2026, 11, 17, 12))],
      );

      expect(result.removedSessionIds, ['a']);
      expect(result.bookedSessions, isEmpty);
    });

    test('a session done today is booked time', () {
      final result = _adjust(
        sessions: [
          _session(
            'd',
            '2026-11-17',
            DateTime.utc(2026, 11, 17, 8),
            status: SessionStatus.done,
          ),
        ],
      );

      expect(result.bookedSessions.map((s) => s.id), ['d']);
      expect(result.bookedMinutesByDate, {'2026-11-17': 60});
    });

    test('"today" follows the user timezone', () {
      // 23:30 UTC on the 17th is already 01:30 on the 18th in Cairo (UTC+2).
      final lateNow = DateTime.utc(2026, 11, 17, 23, 30);
      final doneOnThe17th = _session(
        'd',
        '2026-11-17',
        DateTime.utc(2026, 11, 17, 15),
        status: SessionStatus.done,
      );

      final inUtc = _adjust(sessions: [doneOnThe17th], now: lateNow);
      final inCairo = _adjust(
        sessions: [doneOnThe17th],
        now: lateNow,
        timezone: 'Africa/Cairo',
      );

      expect(inUtc.bookedSessions, hasLength(1));
      expect(inCairo.bookedSessions, isEmpty);
    });
  });

  group('PlanAdjuster remaining work', () {
    test('comes from the topic, minus the session happening now', () {
      // 300 estimated - 60 completed - 60 of p3 running now = 180. The two
      // missed sessions did not reduce it, so the AI plans them again.
      final result = _adjust();

      expect(result.remainingMinutesByTopic, {'t1': 180});
      expect(result.hasRemainingWork, isTrue);
    });

    test('is the whole topic when nothing is running', () {
      final missedOnly = _session(
        'p1',
        '2026-11-16',
        DateTime.utc(2026, 11, 16, 17),
      );
      final result = _adjust(sessions: [missedOnly]);

      expect(result.remainingMinutesByTopic, {'t1': 240});
    });

    test('is empty for a finished topic', () {
      final result = _adjust(
        topics: [_topic(completed: 300, status: TopicStatus.done)],
      );

      expect(result.remainingMinutesByTopic, isEmpty);
      expect(result.hasRemainingWork, isFalse);
      expect(result.missedSessions, hasLength(2));
    });

    test('is empty when the running session covers the rest', () {
      // 300 - 240 completed = 60 left, all of it running right now.
      final result = _adjust(topics: [_topic(completed: 240)]);

      expect(result.remainingMinutesByTopic, isEmpty);
    });

    test('ignores topics that are not in the plan', () {
      final result = _adjust(
        topics: [
          _topic(),
          _topic(id: 't9'),
        ],
      );

      expect(result.remainingMinutesByTopic.keys, ['t1']);
    });
  });

  group('PlanAdjuster completion ratio', () {
    test('is done minutes over due minutes', () {
      // Done: done1 (60). Not done: skip1, miss0, p1, p2 (240).
      final result = _adjust();

      expect(result.completionRatio, closeTo(0.2, 1e-9));
    });

    test('is 1 when nothing was due yet', () {
      final result = _adjust(
        sessions: [
          _session('p4', '2026-11-17', DateTime.utc(2026, 11, 17, 17)),
          _session('p5', '2026-11-18', DateTime.utc(2026, 11, 18, 17)),
        ],
      );

      expect(result.completionRatio, 1.0);
    });
  });

  group('PlanAdjuster edge cases', () {
    test('an empty plan has nothing to adjust', () {
      final result = _adjust(sessions: const []);

      expect(result.missedSessions, isEmpty);
      expect(result.removedSessionIds, isEmpty);
      expect(result.bookedSessions, isEmpty);
      expect(result.remainingMinutesByTopic, isEmpty);
      expect(result.completionRatio, 1.0);
    });

    test('adjusting again right after saving changes nothing else', () {
      final first = _adjust();

      // What the plan looks like after the user accepted the AI preview:
      // missed sessions saved, removed ones deleted, two new AI sessions.
      final missedById = {for (final s in first.missedSessions) s.id: s};
      final saved = [
        for (final s in _planSessions())
          if (!first.removedSessionIds.contains(s.id)) missedById[s.id] ?? s,
        _session('ai1', '2026-11-18', DateTime.utc(2026, 11, 18, 17)),
        _session('ai2', '2026-11-19', DateTime.utc(2026, 11, 19, 17)),
      ];

      final second = _adjust(sessions: saved);

      expect(second.missedSessions, isEmpty);
      expect(second.removedSessionIds, unorderedEquals(['ai1', 'ai2']));
      expect(second.remainingMinutesByTopic, first.remainingMinutesByTopic);
      expect(second.completionRatio, closeTo(first.completionRatio, 1e-9));
    });
  });
}
