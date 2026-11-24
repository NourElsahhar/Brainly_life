import 'package:brainly_life/features/study_planner/data/models/plan_constraints_model.dart';
import 'package:brainly_life/features/study_planner/data/models/study_enums.dart';
import 'package:brainly_life/features/study_planner/data/models/subject_model.dart';
import 'package:brainly_life/features/study_planner/data/models/topic_model.dart';
import 'package:brainly_life/features/study_planner/logic/study_plan_payload.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

// Friday 2026-11-20, 10:00 UTC = 12:00 in Cairo (UTC+2 in November).
final _clock = Clock.fixed(DateTime.utc(2026, 11, 20, 10));
const _cairo = 'Africa/Cairo';

const _constraints = PlanConstraints(
  minutesPerWeekday: {1: 120, 2: 120, 3: 180, 4: 180, 5: 0, 6: 120, 7: 120},
  daysOff: {5},
  maxSessionMinutes: 45,
  breakMinutes: 10,
);

/// The exam at 09:00 Cairo time on [day] of November 2026.
Subject _subject(String id, int day, {int priority = 2}) => Subject(
  id: id,
  name: 'Subject $id',
  colorValue: 0xFF3F51B5,
  examDate: DateTime.utc(2026, 11, day, 7),
  priority: priority,
);

Topic _topic(
  String id,
  String subjectId, {
  int estimated = 120,
  int completed = 0,
  TopicStatus status = TopicStatus.notStarted,
}) => Topic(
  id: id,
  subjectId: subjectId,
  title: 'Topic $id',
  difficulty: 3,
  estimatedMinutes: estimated,
  status: status,
  completedMinutes: completed,
);

void main() {
  final builder = StudyPlanPayloadBuilder(clock: _clock, timezone: _cairo);

  test('builds the "new" payload with local days and times', () {
    final request = builder.buildNew(
      subjects: [_subject('physics', 26, priority: 3), _subject('math', 30)],
      topics: [
        _topic('waves', 'physics', estimated: 120, completed: 30),
        _topic('algebra', 'math'),
      ],
      constraints: _constraints,
    );

    final p = request.payload;
    expect(p['mode'], 'new');
    expect(p['today'], '2026-11-20');
    expect(p['currentTime'], '12:00');
    expect(p['startDate'], '2026-11-20');
    // The day before the last exam (30 Nov).
    expect(p['endDate'], '2026-11-29');
    expect(p['constraints'], _constraints.toFirestore());
    expect(p['subjects'], [
      {
        'id': 'physics',
        'name': 'Subject physics',
        'examDate': '2026-11-26',
        'priority': 'high',
      },
      {
        'id': 'math',
        'name': 'Subject math',
        'examDate': '2026-11-30',
        'priority': 'medium',
      },
    ]);
    expect(p['topics'], [
      {
        'id': 'waves',
        'subjectId': 'physics',
        'title': 'Topic waves',
        'difficulty': 3,
        'remainingMinutes': 90,
      },
      {
        'id': 'algebra',
        'subjectId': 'math',
        'title': 'Topic algebra',
        'difficulty': 3,
        'remainingMinutes': 120,
      },
    ]);
    expect(p.containsKey('completionRatio'), isFalse);
    expect(request.days.first.dateKey, '2026-11-20');
    expect(request.days.last.dateKey, '2026-11-29');
    expect(request.days.length, 10);
  });

  test('sends no personal data, only the agreed keys', () {
    final request = builder.buildNew(
      subjects: [_subject('physics', 26)],
      topics: [_topic('waves', 'physics')],
      constraints: _constraints,
    );

    expect(request.payload.keys.toSet(), {
      'mode',
      'today',
      'currentTime',
      'startDate',
      'endDate',
      'constraints',
      'subjects',
      'topics',
    });
  });

  test('leaves out done topics, past exams and subjects without work', () {
    final request = builder.buildNew(
      subjects: [
        _subject('physics', 26),
        _subject('today', 20), // exam today: cannot be planned
        _subject('finished', 28), // all its topics are done
      ],
      topics: [
        _topic('waves', 'physics'),
        _topic('optics', 'physics', status: TopicStatus.done),
        _topic('worked', 'physics', estimated: 60, completed: 60),
        _topic('late', 'today'),
        _topic('old', 'finished', status: TopicStatus.done),
      ],
      constraints: _constraints,
    );

    expect(request.subjects.map((s) => s.id), ['physics']);
    expect(request.topics.map((t) => t.id), ['waves']);
    expect(request.payload['endDate'], '2026-11-25');
  });

  test('an exam tomorrow gives a one-day plan', () {
    final request = builder.buildNew(
      subjects: [_subject('physics', 21)],
      topics: [_topic('waves', 'physics')],
      constraints: _constraints,
    );

    expect(request.days.map((d) => d.dateKey), ['2026-11-20']);
  });

  test('a far exam is cut to 60 days', () {
    final request = builder.buildNew(
      subjects: [
        Subject(
          id: 'far',
          name: 'Far',
          colorValue: 0xFF3F51B5,
          examDate: DateTime.utc(2027, 6, 1),
          priority: 1,
        ),
      ],
      topics: [_topic('t', 'far')],
      constraints: _constraints,
    );

    expect(request.days.length, StudyPlanPayloadBuilder.maxPlanDays);
    expect(request.payload['endDate'], '2027-01-18');
  });

  test('adds the previous completion ratio when given', () {
    final request = builder.buildNew(
      subjects: [_subject('physics', 26)],
      topics: [_topic('waves', 'physics')],
      constraints: _constraints,
      previousCompletionRatio: 0.75,
    );

    expect(request.payload['completionRatio'], 0.75);
  });

  test('throws when nothing is left to plan', () {
    expect(
      () => builder.buildNew(
        subjects: [_subject('physics', 26)],
        topics: [_topic('waves', 'physics', status: TopicStatus.done)],
        constraints: _constraints,
      ),
      throwsArgumentError,
    );
  });
}
