import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/notifications/data/models/reminder_request_model.dart';

/// Contract every feature uses to schedule, cancel and restore reminders.
///
/// Owned by M3 (notifications). Other features depend on this port only,
/// never on its implementations.
abstract class ReminderService {
  /// Schedules [request].
  /// If a reminder with the same id already exists, it is replaced.
  Future<Result<void>> schedule(ReminderRequest request);

  /// Cancels the reminder with [reminderId].
  /// Does nothing if it does not exist.
  Future<Result<void>> cancel(String reminderId);

  /// Cancels every reminder of [type] that belongs to [refId].
  Future<Result<void>> cancelByRef(ReminderType type, String refId);

  /// Schedules again every saved reminder that is still in the future.
  /// Called after sign-in, reinstall or a time-zone change.
  Future<Result<void>> rescheduleAll();
}
