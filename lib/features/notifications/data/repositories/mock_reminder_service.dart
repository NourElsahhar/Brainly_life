import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/notifications/data/models/reminder_request_model.dart';
import 'package:brainly_life/features/notifications/data/repositories/reminder_service_port.dart';

/// In-memory [ReminderService] used until the real one is ready,
/// and in tests by any feature.
///
/// It shows no notifications. It only remembers what was scheduled,
/// so tests can check it.
class MockReminderService implements ReminderService {
  final Map<String, ReminderRequest> _reminders = {};

  /// When set, every method returns this failure instead of succeeding.
  /// Use it in tests to check how a Cubit handles errors.
  Failure? failWith;

  /// How many times [rescheduleAll] was called.
  int rescheduleAllCount = 0;

  /// Reminders scheduled right now, by id. Read-only.
  Map<String, ReminderRequest> get scheduled => Map.unmodifiable(_reminders);

  @override
  Future<Result<void>> schedule(ReminderRequest request) async {
    if (failWith != null) return Result.failure(failWith!);
    _reminders[request.id] = request;
    return const Result.success(null);
  }

  @override
  Future<Result<void>> cancel(String reminderId) async {
    if (failWith != null) return Result.failure(failWith!);
    _reminders.remove(reminderId);
    return const Result.success(null);
  }

  @override
  Future<Result<void>> cancelByRef(ReminderType type, String refId) async {
    if (failWith != null) return Result.failure(failWith!);
    _reminders.removeWhere(
      (_, reminder) => reminder.type == type && reminder.refId == refId,
    );
    return const Result.success(null);
  }

  @override
  Future<Result<void>> rescheduleAll() async {
    if (failWith != null) return Result.failure(failWith!);
    rescheduleAllCount++;
    return const Result.success(null);
  }
}
