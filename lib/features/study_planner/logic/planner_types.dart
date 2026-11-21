import '../../../core/utils/date_key_utils.dart';

/// One calendar day that a study plan may use.
///
/// Build the days with [PlannerDay.range]. It uses M1's `DateKeyUtils`, so
/// this feature never does its own calendar math (Master Document E.8).
class PlannerDay {
  const PlannerDay({required this.dateKey, required this.weekday});

  /// The day of [dateKey], with its weekday.
  factory PlannerDay.of(String dateKey) {
    return PlannerDay(
      dateKey: dateKey,
      weekday: DateKeyUtils.parse(dateKey).weekday,
    );
  }

  /// Every day from [firstDateKey] to [lastDateKey], both included.
  /// Empty when [lastDateKey] is before [firstDateKey].
  static List<PlannerDay> range(String firstDateKey, String lastDateKey) {
    final count = DateKeyUtils.daysBetween(firstDateKey, lastDateKey) + 1;
    return [
      for (var i = 0; i < count; i++)
        PlannerDay.of(DateKeyUtils.addDays(firstDateKey, i)),
    ];
  }

  /// `yyyy-MM-dd` in the user's timezone.
  final String dateKey;

  /// 1 = Monday ... 7 = Sunday.
  final int weekday;
}
