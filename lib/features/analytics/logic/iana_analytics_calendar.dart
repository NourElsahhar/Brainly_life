import 'package:timezone/timezone.dart' as tz;

import 'analytics_calendar.dart';

AnalyticsCalendar ianaAnalyticsCalendar({
  required String timezone,
  required int weekStartDay,
}) {
  final location = timezone == 'UTC' ? tz.UTC : tz.getLocation(timezone);
  return ZonedAnalyticsCalendar(
    weekStartDay: weekStartDay,
    toLocal: (instant) => tz.TZDateTime.from(instant, location),
    midnightUtc: (year, month, day) =>
        tz.TZDateTime(location, year, month, day).toUtc(),
  );
}
