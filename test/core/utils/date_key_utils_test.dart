// Tests for DateKeyUtils.
// Run with: fvm flutter test test/core/utils/date_key_utils_test.dart

import 'package:brainly_life/core/utils/date_key_utils.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cairo = 'Africa/Cairo';

  group('toDateKey', () {
    test('uses the day of the user timezone, not UTC', () {
      final moment = DateTime.utc(2026, 11, 15, 22, 30);

      expect(DateKeyUtils.toDateKey(moment, timezone: 'UTC'), '2026-11-15');
      expect(DateKeyUtils.toDateKey(moment, timezone: cairo), '2026-11-16');
      expect(
        DateKeyUtils.toDateKey(moment, timezone: 'Asia/Tokyo'),
        '2026-11-16',
      );
      expect(
        DateKeyUtils.toDateKey(moment, timezone: 'America/New_York'),
        '2026-11-15',
      );
    });

    test('changes exactly at midnight of the user timezone', () {
      expect(
        DateKeyUtils.toDateKey(
          DateTime.utc(2026, 11, 15, 21, 59, 59),
          timezone: cairo,
        ),
        '2026-11-15',
      );
      expect(
        DateKeyUtils.toDateKey(DateTime.utc(2026, 11, 15, 22), timezone: cairo),
        '2026-11-16',
      );
    });

    test('an unknown timezone falls back to UTC', () {
      expect(
        DateKeyUtils.toDateKey(
          DateTime.utc(2026, 11, 15, 23),
          timezone: 'Mars/Olympus',
        ),
        '2026-11-15',
      );
    });
  });

  group('todayKey', () {
    test('uses the injected clock', () {
      withClock(Clock.fixed(DateTime.utc(2026, 11, 15, 22, 30)), () {
        expect(DateKeyUtils.todayKey(timezone: cairo), '2026-11-16');
        expect(DateKeyUtils.todayKey(timezone: 'UTC'), '2026-11-15');
      });
    });
  });

  group('isKnownTimezone', () {
    test('accepts real names and rejects fake ones', () {
      expect(DateKeyUtils.isKnownTimezone('Africa/Cairo'), isTrue);
      expect(DateKeyUtils.isKnownTimezone('Mars/Olympus'), isFalse);
    });
  });

  group('parse', () {
    test('a valid dateKey becomes a UTC date', () {
      expect(DateKeyUtils.tryParse('2026-11-16'), DateTime.utc(2026, 11, 16));
      expect(DateKeyUtils.isValid('2028-02-29'), isTrue);
    });

    test('bad text is rejected', () {
      for (final text in [
        '',
        'abc',
        '2026-2-3',
        '2026-13-01',
        '2026-02-30',
        '2026-11-16T10:00',
      ]) {
        expect(DateKeyUtils.tryParse(text), isNull, reason: text);
        expect(DateKeyUtils.isValid(text), isFalse, reason: text);
      }
    });

    test('parse throws a FormatException for a bad dateKey', () {
      expect(() => DateKeyUtils.parse('nope'), throwsFormatException);
    });
  });

  group('fromCalendarDate', () {
    test('pads month and day with zeros', () {
      expect(
        DateKeyUtils.fromCalendarDate(DateTime.utc(2026, 1, 5)),
        '2026-01-05',
      );
    });
  });

  group('addDays and daysBetween', () {
    test('moves across month, year and leap days', () {
      expect(DateKeyUtils.addDays('2026-11-30', 1), '2026-12-01');
      expect(DateKeyUtils.addDays('2026-12-31', 1), '2027-01-01');
      expect(DateKeyUtils.addDays('2026-03-01', -1), '2026-02-28');
      expect(DateKeyUtils.addDays('2028-02-28', 1), '2028-02-29');
      expect(DateKeyUtils.addDays('2026-11-16', 0), '2026-11-16');
    });

    test('counts the days between two dateKeys', () {
      expect(DateKeyUtils.daysBetween('2026-11-10', '2026-11-16'), 6);
      expect(DateKeyUtils.daysBetween('2026-11-16', '2026-11-10'), -6);
      expect(DateKeyUtils.daysBetween('2026-11-16', '2026-11-16'), 0);
    });
  });

  group('dayBounds', () {
    test('Cairo (UTC+2 in winter)', () {
      final range = DateKeyUtils.dayBounds('2026-11-16', timezone: cairo);

      expect(range.start, DateTime.utc(2026, 11, 15, 22));
      expect(range.end, DateTime.utc(2026, 11, 16, 22));
    });

    test('Tokyo (UTC+9, no daylight saving)', () {
      final range = DateKeyUtils.dayBounds(
        '2026-11-16',
        timezone: 'Asia/Tokyo',
      );

      expect(range.start, DateTime.utc(2026, 11, 15, 15));
      expect(range.end, DateTime.utc(2026, 11, 16, 15));
    });

    test('a daylight saving day has 23 hours', () {
      // New York clocks go forward on 2026-03-08.
      final range = DateKeyUtils.dayBounds(
        '2026-03-08',
        timezone: 'America/New_York',
      );

      expect(range.start, DateTime.utc(2026, 3, 8, 5));
      expect(range.end, DateTime.utc(2026, 3, 9, 4));
      expect(range.end.difference(range.start), const Duration(hours: 23));
    });

    test('the end of one day is the start of the next day', () {
      final today = DateKeyUtils.dayBounds('2026-11-16', timezone: cairo);
      final tomorrow = DateKeyUtils.dayBounds('2026-11-17', timezone: cairo);

      expect(today.end, tomorrow.start);
    });
  });
}
