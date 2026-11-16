// Tests for AppLogger.
// Run with: fvm flutter test test/core/utils/app_logger_test.dart

import 'package:brainly_life/core/utils/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<LogEntry> entries;

  setUp(() {
    entries = [];
    AppLogger.enabled = true;
    AppLogger.sink = entries.add;
  });

  tearDown(() {
    AppLogger.sink = null;
    AppLogger.enabled = kDebugMode;
  });

  group('AppLogger', () {
    test('writes each level with its tag and message', () {
      AppLogger.debug('d', tag: 'Tasks');
      AppLogger.info('i');
      AppLogger.warning('w');
      AppLogger.error('e');

      expect(entries.map((e) => e.level), [
        LogLevel.debug,
        LogLevel.info,
        LogLevel.warning,
        LogLevel.error,
      ]);
      expect(entries.first.tag, 'Tasks');
      expect(entries.first.message, 'd');
      expect(entries[1].tag, 'App');
    });

    test('error keeps the error object and the stack trace', () {
      final problem = Exception('boom');
      final stack = StackTrace.current;

      AppLogger.error('failed', error: problem, stackTrace: stack);

      expect(entries.single.error, problem);
      expect(entries.single.stackTrace, stack);
    });

    test('writes nothing when logging is turned off', () {
      AppLogger.enabled = false;

      AppLogger.error('hidden');

      expect(entries, isEmpty);
    });

    test('works without a test sink (goes to the console)', () {
      AppLogger.sink = null;

      expect(() => AppLogger.info('hello'), returnsNormally);
    });
  });
}