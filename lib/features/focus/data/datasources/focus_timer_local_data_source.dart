// FocusTimerLocalDataSource keeps the running timer on the phone, so it
// survives closing the app. It stores a plain map (the timer as JSON).
// SharedPrefsFocusTimerLocalDataSource is the real one. The Mock keeps the
// map in memory, for tests.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

abstract class FocusTimerLocalDataSource {
  /// The saved timer, or null if nothing is saved.
  Future<Map<String, dynamic>?> read();

  Future<void> write(Map<String, dynamic> timer);

  Future<void> clear();
}

class SharedPrefsFocusTimerLocalDataSource
    implements FocusTimerLocalDataSource {
  static const String _key = 'focus_timer_state';

  @override
  Future<Map<String, dynamic>?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  @override
  Future<void> write(Map<String, dynamic> timer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(timer));
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

class MockFocusTimerLocalDataSource implements FocusTimerLocalDataSource {
  Map<String, dynamic>? _saved;

  @override
  Future<Map<String, dynamic>?> read() async => _saved;

  @override
  Future<void> write(Map<String, dynamic> timer) async => _saved = timer;

  @override
  Future<void> clear() async => _saved = null;
}
