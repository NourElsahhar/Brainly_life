# core/ai — the Flutter AI client (owner: M5)

Every AI call in the app goes through **one** interface, `AiClient`. It talks
to the `aiGateway` Cloud Function (M1). The Gemini key lives only on the
server — never in the app.

```dart
import 'package:brainly_life/core/ai/ai.dart';
```

## Files

| File | What it has |
|---|---|
| `ai_client.dart` | `AiClient` — `Future<Result<AiResponse>> generate(AiRequest request)` |
| `ai_models.dart` | `AiFeature`, `AiRequest`, `AiResponse`, `AiUsage` |
| `ai_failures.dart` | `AiErrorCode` (the gateway codes) and `AiGatewayFailure` |
| `cloud_functions_ai_client.dart` | the real client (calls `aiGateway`) |
| `mock_ai_client.dart` | the fake client for development and tests |
| `ai_widgets.dart` | `AiLoadingBubble`, `AiErrorCard`, `AiDisclaimer`, `AiSuggestionCard` |

## Calling the AI

```dart
final result = await getIt<AiClient>().generate(
  AiRequest(feature: AiFeature.studyPlan, payload: {...}),
);
result.fold(
  onSuccess: (response) => use(response.data), // the validated JSON
  onFailure: (failure) => emit(MyError(failure)), // show AiErrorCard
);
```

- `AiFeature`: `studyPlan` (M2), `habitSuggest` (M4), `chat`,
  `dailyTip`, `weeklyInsight` (M5). Each one has a module on the server
  in `functions/src/ai/features/`.
- `response.data` is already checked by the server against the feature's
  `responseSchema`. `response.usage.remainingToday` = calls left today.
- **Never put the uid, name, e-mail or photo in the payload.** The server
  knows the user from the sign-in and reads what it needs from Firestore.
- The payload must be at most 20 KB (bigger -> `payloadTooLarge`, no call).

## What the real client does

- Returns `disabled` without calling the server when the user turned
  **"Use AI features"** off in Settings.
- 30-second timeout (then a `NetworkFailure`).
- Retries **once** only for `provider_unavailable`. Never for
  `rate_limited` or the others.
- Never logs the payload or the answer.

## Errors

`AiGatewayFailure.kind` is one of:

| Code | Meaning | `canRetry` |
|---|---|---|
| `unauthenticated` | not signed in | no |
| `invalidFeature` | unknown feature or bad payload | no |
| `payloadTooLarge` | payload over 20 KB | no |
| `rateLimited` | daily limit reached | no |
| `providerUnavailable` | the AI is down | yes |
| `invalidResponse` | the AI answer failed validation | yes |
| `internal` | anything else | yes |
| `disabled` | AI is off in Settings (client only) | no |

`userMessage` is already a friendly sentence: show it as it is, for example
with `AiErrorCard(failure: failure, onRetry: ...)`. Show the retry button
only when `canRetry` is true.

## The mock (develop without the server)

`--dart-define=USE_MOCKS=true` registers `MockAiClient`. It returns realistic
JSON for every feature. Switches for testing every state:

```dart
MockAiClient(delay: Duration(seconds: 2));                  // loading
MockAiClient(error: AiErrorCode.rateLimited);               // an error
MockAiClient(invalidOutput: true);                          // bad answer
MockAiClient(enabled: false);                               // AI off
MockAiClient(fixtures: {AiFeature.chat: {'reply': 'Hi', 'actions': []}});
```

## Shared widgets

- `AiLoadingBubble({label})` — "Brainly AI is typing" bubble.
- `AiErrorCard({required failure, onRetry})` — message from the failure,
  retry button when `onRetry` is given.
- `AiDisclaimer()` — "AI can make mistakes." Put it under every AI answer.
- `AiSuggestionCard({required title, required text, onDismiss})`.

## Adding a new AI feature

1. Server: write `functions/src/ai/features/<name>.ts` matching
   `FeatureModule`, add it to `registry.ts` and `KNOWN_FEATURES`
   (see `functions/README.md`), then `npm test`.
2. App: add the name to `AiFeature` and a fixture in `MockAiClient`.
