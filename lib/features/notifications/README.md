# notifications feature

**Owner:** M3

The shared reminder system. Every feature schedules, cancels and restores
its reminders through `ReminderService`. Later this feature also handles
push notifications (FCM), notification settings and the notification centre.

## Public contract

Other features import only these files:

- `data/models/reminder_request_model.dart`: `ReminderRequest`, `ReminderType`, `ReminderRepeat`
- `data/repositories/reminder_service_port.dart`: `ReminderService`

Implementations:

- `MockReminderService`: in-memory, available now. Use it in tests.
- `LocalReminderService`: real local notifications (coming soon).

## Rules

- `id` must be deterministic: `<type>_<refId>`, e.g. `task_abc123`.
  Scheduling the same id again replaces the old reminder.
- `scheduledAt` is always in UTC.
- `route` is the deep link opened when the user taps the notification.
- Every method returns `Future<Result<void>>`. Handle the failure,
  e.g. `PermissionFailure` when notifications are not allowed.

## Usage

```dart
final result = await reminderService.schedule(ReminderRequest(
  id: 'study_${session.id}',
  type: ReminderType.study,
  refId: session.id,
  title: 'Study session',
  body: session.topicName,
  scheduledAt: session.startAt.subtract(const Duration(minutes: 10)).toUtc(),
  route: '/study/${session.id}', // example route
));
result.fold(
  onSuccess: (_) {},
  onFailure: (failure) => emit(StudyError(failure)),
);

await reminderService.cancel('study_${session.id}');
```

## Testing with the mock

```dart
final reminders = MockReminderService();
// ... run your cubit
expect(reminders.scheduled.containsKey('study_s1'), isTrue);

reminders.failWith = const PermissionFailure(); // simulate an error
```