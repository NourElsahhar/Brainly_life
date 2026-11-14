import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/features/notifications/data/models/reminder_request_model.dart';
import 'package:brainly_life/features/notifications/data/repositories/mock_reminder_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockReminderService service;

  ReminderRequest buildRequest({
    String id = 'task_abc123',
    ReminderType type = ReminderType.task,
    String refId = 'abc123',
    DateTime? scheduledAt,
  }) {
    return ReminderRequest(
      id: id,
      type: type,
      refId: refId,
      title: 'Reminder',
      body: 'Reminder body',
      scheduledAt: scheduledAt ?? DateTime.utc(2026, 11, 20, 8),
      route: '/tasks/$refId',
    );
  }

  setUp(() {
    service = MockReminderService();
  });

  group('MockReminderService', () {
    test('schedule stores the reminder', () async {
      final request = buildRequest();

      final result = await service.schedule(request);

      expect(result.isSuccess, isTrue);
      expect(service.scheduled['task_abc123'], request);
    });

    test('schedule with the same id replaces the old reminder', () async {
      await service.schedule(buildRequest());
      final later = buildRequest(scheduledAt: DateTime.utc(2026, 11, 21, 9));

      await service.schedule(later);

      expect(service.scheduled, hasLength(1));
      expect(service.scheduled['task_abc123'], later);
    });

    test('cancel removes the reminder', () async {
      await service.schedule(buildRequest());

      final result = await service.cancel('task_abc123');

      expect(result.isSuccess, isTrue);
      expect(service.scheduled, isEmpty);
    });

    test('cancelByRef removes only reminders of that type and ref', () async {
      await service.schedule(
        buildRequest(id: 'habit_h1_am', type: ReminderType.habit, refId: 'h1'),
      );
      await service.schedule(
        buildRequest(id: 'habit_h1_pm', type: ReminderType.habit, refId: 'h1'),
      );
      await service.schedule(
        buildRequest(id: 'task_h1', type: ReminderType.task, refId: 'h1'),
      );

      await service.cancelByRef(ReminderType.habit, 'h1');

      expect(service.scheduled.keys.toList(), ['task_h1']);
    });

    test('rescheduleAll counts its calls', () async {
      await service.rescheduleAll();
      await service.rescheduleAll();

      expect(service.rescheduleAllCount, 2);
    });

    test('returns the failure from failWith and changes nothing', () async {
      service.failWith = const PermissionFailure();

      final result = await service.schedule(buildRequest());

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, const PermissionFailure());
      expect(service.scheduled, isEmpty);
    });

    test('scheduled cannot be changed from outside', () {
      expect(
        () => service.scheduled['other'] = buildRequest(),
        throwsUnsupportedError,
      );
    });
  });
}
