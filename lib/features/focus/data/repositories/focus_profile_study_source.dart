// FocusProfileStudySource = the focus side of the Profile "hours studied".
// It is every focus minute (breaks are not counted) up to today.

// ignore_for_file: prefer_initializing_formals

import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/core/utils/utils.dart';
import 'package:brainly_life/features/auth/data/repositories/profile_stats_provider.dart';
import 'package:brainly_life/features/focus/data/repositories/focus_repository.dart';
import 'package:brainly_life/features/focus/logic/focus_stats_calculator.dart';

class FocusProfileStudySource implements ProfileStudySource {
  FocusProfileStudySource({
    required FocusRepository repository,
    required String Function() timezone,
  }) : _repository = repository,
       _timezone = timezone;

  /// Earlier than any real session.
  static const String firstDay = '2000-01-01';

  final FocusRepository _repository;
  final String Function() _timezone;

  @override
  Future<Result<int>> studiedMinutes() async {
    final timezone = _timezone();
    final result = await _repository.getSessions(
      fromDate: firstDay,
      toDate: DateKeyUtils.todayKey(timezone: timezone),
    );
    return result.fold(
      onSuccess: (sessions) => Result.success(
        FocusStatsCalculator(timezone: timezone).totalMinutes(sessions),
      ),
      onFailure: (failure) => Result.failure(failure),
    );
  }
}
