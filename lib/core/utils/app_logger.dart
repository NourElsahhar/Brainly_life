// AppLogger = the only way to write logs in the app. Never use print().
//
// Usage:
//   AppLogger.debug('Loaded 12 tasks', tag: 'Tasks');
//   AppLogger.info('Sync finished');
//   AppLogger.warning('Retrying request', tag: 'Network');
//   AppLogger.error('Could not save task', tag: 'Tasks', error: e, stackTrace: s);
//
// Rules:
//   - Logs are written in DEBUG mode only. In release builds nothing is logged.
//   - NEVER log personal data: email, name, uid, tokens, task or note text,
//     chat messages, AI prompts or answers. Log counts, ids of things, and
//     short technical messages only.
//   - Do not put personal data inside the [error] object either.

import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

/// One log line. Used by tests to read what was logged.
class LogEntry {
  const LogEntry({
    required this.level,
    required this.tag,
    required this.message,
    this.error,
    this.stackTrace,
  });

  final LogLevel level;
  final String tag;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;
}

class AppLogger {
  const AppLogger._();

  /// Only for tests. Real code must never change it.
  @visibleForTesting
  static bool enabled = kDebugMode;

  /// Only for tests: receives the log lines instead of the console.
  @visibleForTesting
  static void Function(LogEntry entry)? sink;

  static void debug(String message, {String tag = 'App'}) =>
      _log(LogLevel.debug, tag, message);

  static void info(String message, {String tag = 'App'}) =>
      _log(LogLevel.info, tag, message);

  static void warning(String message, {String tag = 'App'}) =>
      _log(LogLevel.warning, tag, message);

  static void error(
    String message, {
    String tag = 'App',
    Object? error,
    StackTrace? stackTrace,
  }) =>
      _log(LogLevel.error, tag, message, error: error, stackTrace: stackTrace);

  static void _log(
    LogLevel level,
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!enabled) return;

    final entry = LogEntry(
      level: level,
      tag: tag,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );

    final testSink = sink;
    if (testSink != null) {
      testSink(entry);
      return;
    }

    developer.log(
      message,
      name: tag,
      level: switch (level) {
        LogLevel.debug => 500,
        LogLevel.info => 800,
        LogLevel.warning => 900,
        LogLevel.error => 1000,
      },
      error: error,
      stackTrace: stackTrace,
    );
  }
}