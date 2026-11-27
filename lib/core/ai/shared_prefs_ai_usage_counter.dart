// Counts the AI calls of each day on this phone (for the daily limits of
// GeminiAiClient). Old days are never read again.

// ignore_for_file: prefer_initializing_formals

import 'package:shared_preferences/shared_preferences.dart';

import 'gemini_ai_client.dart';

class SharedPrefsAiUsageCounter implements AiUsageCounter {
  SharedPrefsAiUsageCounter({
    required SharedPreferencesAsync preferences,
    required String accountKey,
  }) : _preferences = preferences,
       _prefix = 'ai_usage_${accountKey}_';

  final SharedPreferencesAsync _preferences;
  final String _prefix;

  @override
  Future<int> used(String key) async =>
      await _preferences.getInt('$_prefix$key') ?? 0;

  @override
  Future<void> add(String key) async =>
      _preferences.setInt('$_prefix$key', await used(key) + 1);
}
