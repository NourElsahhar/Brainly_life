import 'package:brainly_life/features/focus/data/models/focus_session_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final session = FocusSession(
    id: 'f1',
    type: FocusSessionType.focus,
    startedAt: DateTime.utc(2026, 11, 14, 9),
    endedAt: DateTime.utc(2026, 11, 14, 9, 25),
    plannedMinutes: 25,
    actualMinutes: 25,
    completed: true,
    dateKey: '2026-11-14',
    taskId: 't1',
    createdAt: DateTime.utc(2026, 11, 14, 9, 25),
    updatedAt: DateTime.utc(2026, 11, 14, 9, 25),
  );

  test('toFirestore then fromMap gives the same session', () {
    expect(FocusSession.fromMap('f1', session.toFirestore()), session);
  });

  test('copyWith changes only the given fields', () {
    final copy = session.copyWith(actualMinutes: 10, completed: false);
    expect(copy.actualMinutes, 10);
    expect(copy.completed, isFalse);
    expect(copy.taskId, 't1');
  });

  test('clearTaskId sets taskId to null', () {
    expect(session.copyWith(clearTaskId: true).taskId, isNull);
  });
}
