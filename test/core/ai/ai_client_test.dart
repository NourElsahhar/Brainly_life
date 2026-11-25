import 'package:brainly_life/core/ai/ai.dart';
import 'package:flutter_test/flutter_test.dart';

final request = AiRequest(feature: AiFeature.dailyTip, payload: const {});

Map<String, Object?> error(String code) => {
  'ok': false,
  'error': {'code': code},
};
Map<String, Object?> success() => {
  'ok': true,
  'data': {'tip': 'Start small.'},
  'usage': {'remainingToday': 28, 'feature': 'dailyTip'},
};

void main() {
  test('Retries provider_unavailable only once', () async {
    var calls = 0;
    final client = CloudFunctionsAiClient(
      isEnabled: () async => true,
      call: (_) async =>
          ++calls == 1 ? error('provider_unavailable') : success(),
    );
    expect(
      (await client.generate(request)).dataOrNull?.data['tip'],
      'Start small.',
    );
    expect(calls, 2);
  });

  test('Rate limit does not retry and uses a safe error', () async {
    var calls = 0;
    final client = CloudFunctionsAiClient(
      isEnabled: () async => true,
      call: (_) async {
        calls++;
        return error('rate_limited');
      },
    );
    final failure =
        (await client.generate(request)).failureOrNull as AiGatewayFailure;
    expect(failure.kind, AiErrorCode.rateLimited);
    expect(failure.canRetry, isFalse);
    expect(calls, 1);
  });

  test('AI off and oversized payload never reach the gateway', () async {
    Future<Object?> shouldNotCall(Map<String, Object?> _) async =>
        fail('Gateway was contacted');
    final disabled = CloudFunctionsAiClient(
      call: shouldNotCall,
      isEnabled: () async => false,
    );
    final enabled = CloudFunctionsAiClient(
      call: shouldNotCall,
      isEnabled: () async => true,
    );
    final large = AiRequest(
      feature: AiFeature.chat,
      payload: {'text': 'ي' * 11000},
    );
    expect(
      (await disabled.generate(request)).failureOrNull?.code,
      'ai_disabled',
    );
    expect(
      (await enabled.generate(large)).failureOrNull?.code,
      'payload_too_large',
    );
  });

  test('Mock supports all five calls and invalid fixture output', () async {
    final client = MockAiClient(delay: Duration.zero);
    for (final feature in AiFeature.values) {
      final result = await client.generate(
        AiRequest(feature: feature, payload: const {}),
      );
      expect(result.dataOrNull?.usage.feature, feature);
      expect(result.dataOrNull?.data, isNotEmpty);
    }
    final invalid = MockAiClient(delay: Duration.zero, invalidOutput: true);
    expect((await invalid.generate(request)).dataOrNull?.data, {
      'unexpected': true,
    });
  });
}
