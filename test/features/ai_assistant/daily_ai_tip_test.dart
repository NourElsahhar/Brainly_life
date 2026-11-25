import 'package:brainly_life/core/ai/ai.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/ai_assistant/data/repositories/daily_ai_tip_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Preferences extends Mock implements SharedPreferencesAsync {}

class _RecordingClient implements AiClient {
  var calls = 0;
  AiErrorCode? error;

  @override
  Future<Result<AiResponse>> generate(AiRequest request) {
    calls++;
    return MockAiClient(delay: Duration.zero, error: error).generate(request);
  }
}

void main() {
  late _Preferences preferences;
  late Map<String, String> cache;

  setUp(() {
    preferences = _Preferences();
    cache = {};
    when(() => preferences.getString(any())).thenAnswer(
      (invocation) async => cache[invocation.positionalArguments.single],
    );
    when(() => preferences.setString(any(), any()))
        .thenAnswer((invocation) async {
          final [key, value] = invocation.positionalArguments;
          cache[key as String] = value as String;
        });
  });

  test(
    'Calls AI once per account and day, including concurrent reads',
    () async {
      final client = _RecordingClient();
      var date = '2026-11-15';
      DailyAiTipProvider provider([String uid = 'a']) => DailyAiTipProvider(
        client: client,
        preferences: preferences,
        accountKey: uid,
        today: () => date,
        isEnabled: () async => true,
      );

      final tip = provider();
      final values = await Future.wait([tip.dailyTip(), tip.dailyTip()]);
      expect(values.first.dataOrNull, equals(values.last.dataOrNull));
      expect(client.calls, 1);
      expect((await provider().dailyTip()).dataOrNull, values.first.dataOrNull);
      expect(client.calls, 1);
      await provider('b').dailyTip();
      expect(client.calls, 2);
      date = '2026-11-16';
      await tip.dailyTip();
      expect(client.calls, 3);
    },
  );

  test('Shows a fallback when AI is off or unavailable', () async {
    final client = _RecordingClient()..error = AiErrorCode.providerUnavailable;
    var isEnabled = false;
    final tip = DailyAiTipProvider(
      client: client,
      preferences: preferences,
      accountKey: 'a',
      today: () => '2026-11-15',
      isEnabled: () async => isEnabled,
    );
    final off = await tip.dailyTip();
    expect(off.dataOrNull, isNotEmpty);
    expect(client.calls, 0);
    isEnabled = true;
    final unavailable = await tip.dailyTip();
    expect(unavailable.dataOrNull, off.dataOrNull);
    expect(client.calls, 1);
    expect((await tip.dailyTip()).dataOrNull, off.dataOrNull);
    expect(client.calls, 1);
  });
}
