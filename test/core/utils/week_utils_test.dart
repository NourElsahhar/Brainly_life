// Tests for WeekUtils.
// Run with: fvm flutter test test/core/utils/week_utils_test.dart

import 'package:brainly_life/core/utils/week_utils.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 2026-11-16 is a Monday.
  group('week start and end', () {
    test('Monday start (default)', () {
      expect(WeekUtils.weekStartDateKey('2026-11-16'), '2026-11-16');
      expect(WeekUtils.weekStartDateKey('2026-11-19'), '2026-11-16');
      expect(WeekUtils.weekStartDateKey('2026-11-22'), '2026-11-16');
      expect(WeekUtils.weekStartDateKey('2026-11-23'), '2026-11-23');
      expect(WeekUtils.weekEndDateKey('2026-11-18'), '2026-11-22');
    });

    test('Sunday start', () {
      expect(
        WeekUtils.weekStartDateKey('2026-11-16', weekStartDay: DateTime.sunday),
        '2026-11-15',
      );
      expect(
        WeekUtils.weekEndDateKey('2026-11-16', weekStartDay: DateTime.sunday),
        '2026-11-21',
      );
    });

    test('Saturday start', () {
      expect(
        WeekUtils.weekStartDateKey(
          '2026-11-16',
          weekStartDay: DateTime.saturday,
        ),
        '2026-11-14',
      );
      expect(
        WeekUtils.weekEndDateKey('2026-11-16', weekStartDay: DateTime.saturday),
        '2026-11-20',
      );
      expect(
        WeekUtils.weekStartDateKey(
          '2026-11-14',
          weekStartDay: DateTime.saturday,
        ),
        '2026-11-14',
      );
      expect(
        WeekUtils.weekStartDateKey(
          '2026-11-13',
          weekStartDay: DateTime.saturday,
        ),
        '2026-11-07',
      );
    });

    test('an invalid weekStartDay is rejected', () {
      expect(
        () => WeekUtils.weekStartDateKey('2026-11-16', weekStartDay: 0),
        throwsArgumentError,
      );
      expect(
        () => WeekUtils.weekStartDateKey('2026-11-16', weekStartDay: 8),
        throwsArgumentError,
      );
    });
  });

  group('weekDateKeys', () {
    test('gives the 7 days of the week', () {
      expect(WeekUtils.weekDateKeys('2026-11-18'), [
        '2026-11-16',
        '2026-11-17',
        '2026-11-18',
        '2026-11-19',
        '2026-11-20',
        '2026-11-21',
        '2026-11-22',
      ]);
    });

    test('works across a month and year boundary', () {
      expect(WeekUtils.weekDateKeys('2026-12-31'), [
        '2026-12-28',
        '2026-12-29',
        '2026-12-30',
        '2026-12-31',
        '2027-01-01',
        '2027-01-02',
        '2027-01-03',
      ]);
    });
  });

  group('weekKey', () {
    test('Monday start gives the ISO week', () {
      expect(WeekUtils.weekKey('2026-11-16'), '2026-W47');
      expect(WeekUtils.weekKey('2026-11-22'), '2026-W47');
      expect(WeekUtils.weekKey('2026-11-23'), '2026-W48');
      expect(WeekUtils.weekKey('2026-01-05'), '2026-W02');
    });

    test('year boundaries follow the ISO rules', () {
      expect(WeekUtils.weekKey('2026-01-01'), '2026-W01');
      expect(WeekUtils.weekKey('2025-12-29'), '2026-W01');
      expect(WeekUtils.weekKey('2024-12-30'), '2025-W01');
      expect(WeekUtils.weekKey('2027-01-01'), '2026-W53');
    });

    test('every day of one week has the same key', () {
      final keys = WeekUtils.weekDateKeys('2026-11-18')
          .map(WeekUtils.weekKey)
          .toSet();

      expect(keys, {'2026-W47'});
    });

    test('Sunday start', () {
      String key(String dateKey) =>
          WeekUtils.weekKey(dateKey, weekStartDay: DateTime.sunday);

      expect(key('2026-11-15'), '2026-W46');
      expect(key('2026-11-21'), '2026-W46');
      expect(key('2026-11-22'), '2026-W47');
    });

    test('Saturday start', () {
      String key(String dateKey) =>
          WeekUtils.weekKey(dateKey, weekStartDay: DateTime.saturday);

      expect(key('2026-11-14'), '2026-W46');
      expect(key('2026-11-16'), '2026-W46');
      expect(key('2026-11-20'), '2026-W46');
      expect(key('2026-11-21'), '2026-W47');
    });
  });

  group('weekKeyForMoment and currentWeekKey', () {
    test('use the user timezone', () {
      // 2026-11-22 22:30 UTC is already Monday 2026-11-23 in Cairo.
      final moment = DateTime.utc(2026, 11, 22, 22, 30);

      expect(WeekUtils.weekKeyForMoment(moment, timezone: 'UTC'), '2026-W47');
      expect(
        WeekUtils.weekKeyForMoment(moment, timezone: 'Africa/Cairo'),
        '2026-W48',
      );
    });

    test('currentWeekKey uses the injected clock', () {
      withClock(Clock.fixed(DateTime.utc(2026, 11, 22, 22, 30)), () {
        expect(WeekUtils.currentWeekKey(timezone: 'Africa/Cairo'), '2026-W48');
      });
    });
  });

  group('weekBounds', () {
    test('Cairo, Monday start', () {
      final range = WeekUtils.weekBounds(
        '2026-11-18',
        timezone: 'Africa/Cairo',
      );

      expect(range.start, DateTime.utc(2026, 11, 15, 22));
      expect(range.end, DateTime.utc(2026, 11, 22, 22));
    });

    test('the end of a week is the start of the next week', () {
      final thisWeek = WeekUtils.weekBounds('2026-11-18', timezone: 'UTC');
      final nextWeek = WeekUtils.weekBounds('2026-11-25', timezone: 'UTC');

      expect(thisWeek.end, nextWeek.start);
    });
  });
}
