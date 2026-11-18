import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/features/study/data/models/plan_constraints_model.dart';
import 'package:brainly_life/features/study/data/models/study_enums.dart';
import 'package:brainly_life/features/study/data/models/study_plan_model.dart';
import 'package:brainly_life/features/study/data/models/study_session_model.dart';
import 'package:brainly_life/features/study/data/models/subject_model.dart';
import 'package:brainly_life/features/study/data/models/topic_model.dart';
import 'package:brainly_life/features/study/data/repositories/mock_study_repository.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

// "Now" is Monday 2026-11-16 08:00 UTC. With the UTC timezone, today is
// '2026-11-16' and tomorrow is '2026-11-17'.
final _now = DateTime.utc(2026, 11, 16, 8);

MockStudyRepository _sampleRepository() {
  return MockStudyRepository(clock: Clock.fixed(_now), timezone: 'UTC');
}

MockStudyRepository _emptyRepository({Clock? clock}) {
  return MockStudyRepository(
    clock: clock ?? Clock.fixed(_now),
    timezone: 'UTC',
    withSampleData: false,
  );
}

Subject _newSubject() {
  return Subject(
    id: 'ignored',
    name: 'Networks',
    colorValue: 0xFF123456,
    examDate: DateTime.utc(2026, 12, 1, 9),
    priority: 2,
  );
}

Topic _newTopic(String subjectId) {
  return Topic(
    id: 'ignored',
    subjectId: subjectId,
    title: 'TCP',
    difficulty: 3,
    estimatedMinutes: 90,
    status: TopicStatus.notStarted,
    completedMinutes: 0,
  );
}

PlanConstraints _constraints() {
  return PlanConstraints(
    minutesPerWeekday: {for (var d = 1; d <= 7; d++) d: 120},
    daysOff: const {},
    maxSessionMinutes: 60,
    breakMinutes: 10,
  );
}

StudyPlan _plan(String id) {
  return StudyPlan(
    id: id,
    title: 'New plan',
    startDate: DateTime.utc(2026, 11, 16),
    endDate: DateTime.utc(2026, 11, 30),
    generatedBy: PlanGenerator.rules,
    constraints: _constraints(),
  );
}

StudySession _session(String id, String planId) {
  return StudySession(
    id: id,
    planId: planId,
    subjectId: 'subject_os',
    topicId: 'topic_os_memory',
    dateKey: '2026-11-20',
    startAt: DateTime.utc(2026, 11, 20, 17),
    plannedMinutes: 60,
  );
}

void main() {
  group('sample data', () {
    test('has three subjects ordered by exam date', () async {
      final result = await _sampleRepository().getSubjects();

      expect(result.dataOrNull!.map((s) => s.id), [
        'subject_os',
        'subject_db',
        'subject_la',
      ]);
    });

    test('has an active plan with eight sessions of every status', () async {
      final repository = _sampleRepository();

      final plan = (await repository.getActivePlan()).dataOrNull;
      final sessions = (await repository.getSessionsForPlan('plan_sample'))
          .dataOrNull!;

      expect(plan?.id, 'plan_sample');
      expect(sessions, hasLength(8));
      expect(
        sessions.map((s) => s.status).toSet(),
        SessionStatus.values.toSet(),
      );
    });

    test('an empty repository has nothing and no active plan', () async {
      final repository = _emptyRepository();

      expect((await repository.getSubjects()).dataOrNull, isEmpty);
      expect((await repository.getTopics()).dataOrNull, isEmpty);
      expect((await repository.getActivePlan()).isSuccess, isTrue);
      expect((await repository.getActivePlan()).dataOrNull, isNull);
    });
  });

  group('ids', () {
    test('new ids are different every time', () {
      final repository = _emptyRepository();

      expect(repository.newSessionId(), isNot(repository.newSessionId()));
      expect(repository.newPlanId(), isNot(repository.newPlanId()));
    });
  });

  group('subjects', () {
    test('addSubject gives a new id and server-like timestamps', () async {
      final repository = _emptyRepository();

      final saved = (await repository.addSubject(_newSubject())).dataOrNull!;

      expect(saved.id, isNot('ignored'));
      expect(saved.createdAt, _now);
      expect(saved.updatedAt, _now);
      expect((await repository.getSubjects()).dataOrNull, [saved]);
    });

    test('updateSubject keeps createdAt and refreshes updatedAt', () async {
      var current = _now;
      final repository = _emptyRepository(clock: Clock(() => current));
      final saved = (await repository.addSubject(_newSubject())).dataOrNull!;

      current = DateTime.utc(2026, 11, 16, 9);
      final updated = (await repository.updateSubject(
        saved.copyWith(name: 'Computer Networks'),
      )).dataOrNull!;

      expect(updated.name, 'Computer Networks');
      expect(updated.createdAt, _now);
      expect(updated.updatedAt, DateTime.utc(2026, 11, 16, 9));
    });

    test(
      'updateSubject fails with NotFoundFailure for an unknown id',
      () async {
        final result = await _emptyRepository().updateSubject(_newSubject());

        expect(result.failureOrNull, isA<NotFoundFailure>());
      },
    );

    test('deleteSubject also deletes its topics and sessions', () async {
      final repository = _sampleRepository();

      final result = await repository.deleteSubject('subject_os');

      expect(result.isSuccess, isTrue);
      expect((await repository.getSubjects()).dataOrNull, hasLength(2));
      expect(
        (await repository.getTopics(subjectId: 'subject_os')).dataOrNull,
        isEmpty,
      );
      expect(
        (await repository.getSessionsForPlan('plan_sample')).dataOrNull,
        hasLength(5),
      );
    });

    test(
      'deleteSubject fails with NotFoundFailure for an unknown id',
      () async {
        final result = await _emptyRepository().deleteSubject('missing');

        expect(result.failureOrNull, isA<NotFoundFailure>());
      },
    );
  });

  group('topics', () {
    test('addTopic fails when the subject does not exist', () async {
      final result = await _emptyRepository().addTopic(_newTopic('missing'));

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test('addTopic stores the topic under its subject', () async {
      final repository = _sampleRepository();

      final saved = (await repository.addTopic(_newTopic('subject_db')))
          .dataOrNull!;
      final topics = (await repository.getTopics(subjectId: 'subject_db'))
          .dataOrNull!;

      expect(topics.map((t) => t.id), contains(saved.id));
      expect(topics, hasLength(4));
    });

    test('updateTopic changes the topic and fails for an unknown id', () async {
      final repository = _sampleRepository();
      final topics = (await repository.getTopics()).dataOrNull!;
      final topic = topics.firstWhere((t) => t.id == 'topic_os_memory');

      final updated = (await repository.updateTopic(
        topic.copyWith(status: TopicStatus.inProgress, completedMinutes: 30),
      )).dataOrNull!;
      final missing = await repository.updateTopic(_newTopic('subject_os'));

      expect(updated.status, TopicStatus.inProgress);
      expect(updated.completedMinutes, 30);
      expect(missing.failureOrNull, isA<NotFoundFailure>());
    });

    test('deleteTopic also deletes the sessions of that topic', () async {
      final repository = _sampleRepository();

      final result = await repository.deleteTopic('topic_os_deadlocks');

      expect(result.isSuccess, isTrue);
      expect(
        (await repository.getSessionsForPlan('plan_sample')).dataOrNull,
        hasLength(6),
      );
    });
  });

  group('plans', () {
    test(
      'saving an active plan archives the old one and its planned sessions',
      () async {
        final repository = _sampleRepository();

        final result = await repository.savePlan(_plan('plan_new'), [
          _session('session_a', 'plan_new'),
          _session('session_b', 'plan_new'),
        ]);

        expect(result.isSuccess, isTrue);
        expect((await repository.getActivePlan()).dataOrNull?.id, 'plan_new');

        final oldSessions = (await repository.getSessionsForPlan('plan_sample'))
            .dataOrNull!;
        expect(oldSessions.map((s) => s.status).toSet(), {
          SessionStatus.skipped,
          SessionStatus.done,
          SessionStatus.missed,
        });
        expect(
          (await repository.getSessionsForPlan('plan_new')).dataOrNull,
          hasLength(2),
        );
      },
    );

    test('savePlan rejects a session that belongs to another plan', () async {
      final repository = _sampleRepository();

      final result = await repository.savePlan(_plan('plan_new'), [
        _session('session_a', 'another_plan'),
      ]);

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect((await repository.getActivePlan()).dataOrNull?.id, 'plan_sample');
    });
  });

  group('sessions', () {
    test(
      'updateSession changes the status and fails for an unknown id',
      () async {
        final repository = _sampleRepository();
        final sessions = (await repository.getSessionsForPlan('plan_sample'))
            .dataOrNull!;
        final session = sessions.firstWhere((s) => s.id == 'session_today_1');

        final updated = (await repository.updateSession(
          session.copyWith(status: SessionStatus.done),
        )).dataOrNull!;
        final missing = await repository.updateSession(_session('x', 'plan_x'));

        expect(updated.status, SessionStatus.done);
        expect(missing.failureOrNull, isA<NotFoundFailure>());
      },
    );

    test('deleteSession removes it and fails for an unknown id', () async {
      final repository = _sampleRepository();

      final deleted = await repository.deleteSession('session_day2');
      final missing = await repository.deleteSession('session_day2');

      expect(deleted.isSuccess, isTrue);
      expect(missing.failureOrNull, isA<NotFoundFailure>());
    });

    test('addActualMinutes adds to the minutes already studied', () async {
      final repository = _sampleRepository();

      final result = await repository.addActualMinutes(
        studySessionId: 'session_done',
        minutes: 20,
      );
      final sessions = (await repository.getSessionsForPlan('plan_sample'))
          .dataOrNull!;

      expect(result.isSuccess, isTrue);
      expect(
        sessions.firstWhere((s) => s.id == 'session_done').actualMinutes,
        75,
      );
    });

    test('addActualMinutes rejects bad input', () async {
      final repository = _sampleRepository();

      final zero = await repository.addActualMinutes(
        studySessionId: 'session_done',
        minutes: 0,
      );
      final missing = await repository.addActualMinutes(
        studySessionId: 'missing',
        minutes: 10,
      );

      expect(zero.failureOrNull, isA<ValidationFailure>());
      expect(missing.failureOrNull, isA<NotFoundFailure>());
    });
  });

  group('watchSessions', () {
    test('emits the range first, then a new list after every change', () async {
      final repository = _sampleRepository();
      final emitted = <int>[];

      // Today and tomorrow: 2 + 2 sessions, both days included.
      final subscription = repository
          .watchSessions(fromDateKey: '2026-11-16', toDateKey: '2026-11-17')
          .listen((result) => emitted.add(result.dataOrNull!.length));
      await Future<void>.delayed(Duration.zero);

      await repository.deleteSession('session_today_1');
      await Future<void>.delayed(Duration.zero);

      expect(emitted, [4, 3]);
      await subscription.cancel();
    });

    test('only includes sessions inside the date range', () async {
      final repository = _sampleRepository();

      final first = await repository
          .watchSessions(fromDateKey: '2026-11-15', toDateKey: '2026-11-15')
          .first;

      expect(first.dataOrNull!.map((s) => s.id), [
        'session_done',
        'session_missed',
      ]);
    });

    test('stops listening after cancel', () async {
      final repository = _sampleRepository();
      final emitted = <int>[];

      final subscription = repository
          .watchSessions(fromDateKey: '2026-11-16', toDateKey: '2026-11-17')
          .listen((result) => emitted.add(result.dataOrNull!.length));
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      await repository.deleteSession('session_today_1');
      await Future<void>.delayed(Duration.zero);

      expect(emitted, [4]);
    });
  });
}
