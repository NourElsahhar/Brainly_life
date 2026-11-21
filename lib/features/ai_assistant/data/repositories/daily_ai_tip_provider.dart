import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/ai/ai.dart';
import '../../../../core/errors/result.dart';
import 'ai_tip_repository.dart';

class DailyAiTipProvider implements AiTipProvider {
  DailyAiTipProvider({
    required this._client,
    required this._preferences,
    required String accountKey,
    required this._today,
    required this._isEnabled,
  }) : _key = 'brainly.dailyTip.$accountKey';

  static const _tips = [
    'Choose one small task you can finish in five minutes.',
    'Write down your next step before taking a break.',
    'Set aside one uninterrupted block for your most important task.',
  ];
  final AiClient _client;
  final SharedPreferencesAsync _preferences;
  final String _key;
  final String Function() _today;
  final Future<bool> Function() _isEnabled;
  Future<Result<String>>? _pending;
  String? _cachedDay;
  String? _cachedTip;

  @override
  Future<Result<String>> dailyTip() =>
      _pending ??= _readToday().whenComplete(() => _pending = null);

  Future<Result<String>> _readToday() async {
    final day = _today();
    final fallback =
        _tips[DateTime.parse(day).difference(DateTime.utc(2020)).inDays %
            _tips.length];
    try {
      if (!await _isEnabled()) return Result.success(fallback);
    } catch (_) {
      return Result.success(fallback);
    }
    if (_cachedDay == day && _cachedTip != null) {
      return Result.success(_cachedTip!);
    }
    try {
      final saved = await _preferences.getString(_key);
      final decoded = saved == null ? null : jsonDecode(saved);
      if (decoded case {'day': final String date, 'tip': final String tip}) {
        if (date == day && tip.trim().isNotEmpty) return Result.success(tip);
      }
    } catch (_) {}
    final result = await _client.generate(
      AiRequest(feature: AiFeature.dailyTip, payload: const {}),
    );
    final value = result.dataOrNull?.data['tip'];
    final tip =
        value is String && value.trim().isNotEmpty && value.length <= 240
        ? value.trim()
        : fallback;
    _cachedDay = day;
    _cachedTip = tip;
    try {
      await _preferences.setString(_key, jsonEncode({'day': day, 'tip': tip}));
    } catch (_) {}
    return Result.success(tip);
  }
}

class MockAiTipProvider implements AiTipProvider {
  const MockAiTipProvider();

  @override
  Future<Result<String>> dailyTip() async => const Result.success(
    'Pick one task you can finish before checking your inbox.',
  );
}
