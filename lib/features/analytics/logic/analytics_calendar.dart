import '../data/models/analytics_models.dart';

abstract interface class AnalyticsCalendar {
  AnalyticsWeek weekContaining(DateTime instant);
  AnalyticsWeek shift(AnalyticsWeek week, int weeks);
  String dateKey(DateTime instant);
}

class ZonedAnalyticsCalendar implements AnalyticsCalendar {
  ZonedAnalyticsCalendar({
    required this.weekStartDay,
    required this._toLocal,
    required this._midnightUtc,
  }) {
    RangeError.checkValueInInterval(
      weekStartDay,
      DateTime.monday,
      DateTime.sunday,
    );
  }

  final int weekStartDay;
  final DateTime Function(DateTime) _toLocal;
  final DateTime Function(int, int, int) _midnightUtc;

  @override
  String dateKey(DateTime instant) => dayKey(_toLocal(instant));

  @override
  AnalyticsWeek weekContaining(DateTime instant) {
    final local = _toLocal(instant);
    return _build(_start(DateTime.utc(local.year, local.month, local.day)));
  }

  @override
  AnalyticsWeek shift(AnalyticsWeek week, int weeks) =>
      _build(week.start.add(Duration(days: 7 * weeks)));

  DateTime _start(DateTime day) =>
      day.subtract(Duration(days: (day.weekday - weekStartDay) % 7));

  AnalyticsWeek _build(DateTime start) {
    final end = start.add(const Duration(days: 7));
    final year = start.add(const Duration(days: 3)).year;
    final first = _start(DateTime.utc(year, 1, 4));
    final number = 1 + start.difference(first).inDays ~/ 7;
    return AnalyticsWeek(
      key: '$year-W${number.toString().padLeft(2, '0')}',
      start: start,
      startUtc: _midnightUtc(start.year, start.month, start.day),
      endUtc: _midnightUtc(end.year, end.month, end.day),
    );
  }
}
