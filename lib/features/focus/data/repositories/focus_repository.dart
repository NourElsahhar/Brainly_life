import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/focus/data/models/focus_session_model.dart';
import 'package:brainly_life/features/focus/data/models/focus_settings_model.dart';

/// The contract for focus sessions and timer settings.
abstract class FocusRepository {
  /// Saves a finished or stopped block and returns it with its final id.
  Future<Result<FocusSession>> saveSession(FocusSession session);

  /// Returns sessions whose dateKey is between [fromDate] and [toDate]
  /// (both included), oldest first.
  Future<Result<List<FocusSession>>> getSessions({
    required String fromDate,
    required String toDate,
  });

  /// Returns the saved settings, or the defaults if none are saved yet.
  Future<Result<FocusSettings>> getSettings();

  Future<Result<void>> saveSettings(FocusSettings settings);
}
