import 'package:brainly_life/features/notifications/data/models/reminder_request_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final scheduledAt = DateTime.utc(2026, 11, 20, 8);

  ReminderRequest buildRequest() => ReminderRequest(
    id: 'task_abc123',
    type: ReminderType.task,
    refId: 'abc123',
    title: 'Task reminder',
    body: 'Finish the report',
    scheduledAt: scheduledAt,
    route: '/tasks/abc123',
  );

  group('ReminderRequest', () {
    test('uses no repeat and no weekdays by default', () {
      final request = buildRequest();

      expect(request.repeat, ReminderRepeat.none);
      expect(request.weekdays, isEmpty);
    });

    test('two requests with the same values are equal', () {
      expect(buildRequest(), equals(buildRequest()));
    });

    test('copyWith changes only the given field', () {
      final original = buildRequest();
      final later = DateTime.utc(2026, 11, 21, 9);

      final copy = original.copyWith(scheduledAt: later);

      expect(copy.scheduledAt, later);
      expect(copy.id, original.id);
      expect(copy.title, original.title);
      expect(original.scheduledAt, scheduledAt);
    });

    test('toFirestore stores enums as names and the time as a Timestamp', () {
      final map = buildRequest().toFirestore();

      expect(map['type'], 'task');
      expect(map['repeat'], 'none');
      expect(map['scheduledAt'], Timestamp.fromDate(scheduledAt));
      expect(map.containsKey('id'), isFalse);
    });

    test('fromMap(toFirestore()) gives back the same request', () {
      final weekly = buildRequest().copyWith(
        repeat: ReminderRepeat.weekly,
        weekdays: [1, 3, 5],
      );

      final restored = ReminderRequest.fromMap(weekly.id, weekly.toFirestore());

      expect(restored, equals(weekly));
    });
  });
}
