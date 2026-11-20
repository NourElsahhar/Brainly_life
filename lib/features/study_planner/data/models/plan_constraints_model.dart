import 'package:freezed_annotation/freezed_annotation.dart';

import 'firestore_mapping.dart';

part 'plan_constraints_model.freezed.dart';

@freezed
abstract class PlanConstraints with _$PlanConstraints {
  const PlanConstraints._();

  const factory PlanConstraints({
    required Map<int, int> minutesPerWeekday,
    required Set<int> daysOff,
    required int maxSessionMinutes,
    required int breakMinutes,
  }) = _PlanConstraints;

  /// Builds the constraints from the nested map of a plan document.
  factory PlanConstraints.fromFirestore(Map<String, dynamic> data) {
    final rawMinutes = requireMap(data, 'minutesPerWeekday');
    final rawDaysOff = requireField<List<dynamic>>(data, 'daysOff');

    return PlanConstraints(
      minutesPerWeekday: {
        for (final entry in rawMinutes.entries)
          _parseWeekday(entry.key): _parseMinutes(entry.value),
      },
      daysOff: {for (final day in rawDaysOff) _parseWeekday(day)},
      maxSessionMinutes: requireField<int>(data, 'maxSessionMinutes'),
      breakMinutes: requireField<int>(data, 'breakMinutes'),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'minutesPerWeekday': {
        for (final entry in minutesPerWeekday.entries)
          '${entry.key}': entry.value,
      },
      'daysOff': (daysOff.toList()..sort()),
      'maxSessionMinutes': maxSessionMinutes,
      'breakMinutes': breakMinutes,
    };
  }
}

int _parseWeekday(Object? raw) {
  final weekday = raw is int ? raw : int.tryParse('$raw');
  if (weekday == null || weekday < 1 || weekday > 7) {
    throw FormatException('"$raw" is not a weekday between 1 and 7.');
  }
  return weekday;
}

int _parseMinutes(Object? raw) {
  if (raw is int) {
    return raw;
  }
  throw FormatException('Minutes value "$raw" is not an int.');
}
