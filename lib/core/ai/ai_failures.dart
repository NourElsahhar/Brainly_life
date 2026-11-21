import '../errors/failure.dart';

enum AiErrorCode {
  unauthenticated('unauthenticated', 'Sign in again to use Brainly AI.'),
  invalidFeature('invalid_feature', 'This AI feature is unavailable.'),
  payloadTooLarge(
    'payload_too_large',
    'This request is too long. Try a shorter request.',
  ),
  rateLimited(
    'rate_limited',
    'You reached your AI limit for today. Try again tomorrow.',
  ),
  providerUnavailable(
    'provider_unavailable',
    'Brainly AI is temporarily unavailable. Please try again.',
  ),
  invalidResponse(
    'invalid_response',
    'Brainly AI returned an unexpected answer. Please try again.',
  ),
  internal(
    'internal',
    'Something went wrong with Brainly AI. Please try again.',
  ),
  disabled('ai_disabled', 'Enable AI in Settings to use this feature.');

  const AiErrorCode(this.wireName, this.message);
  final String wireName;
  final String message;

  static AiErrorCode fromWire(String? code) => values.firstWhere(
    (value) => value.wireName == code?.replaceAll('-', '_'),
    orElse: () => switch (code) {
      'unavailable' => providerUnavailable,
      'resource-exhausted' => rateLimited,
      _ => internal,
    },
  );
}

final class AiGatewayFailure extends AiFailure {
  AiGatewayFailure(this.kind)
    : super(code: kind.wireName, userMessage: kind.message);

  final AiErrorCode kind;

  bool get canRetry => switch (kind) {
    AiErrorCode.providerUnavailable ||
    AiErrorCode.invalidResponse ||
    AiErrorCode.internal => true,
    _ => false,
  };
}
