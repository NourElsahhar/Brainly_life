# core/ai — the Flutter AI client (owner: M5)

Every AI call in the app goes through **one** interface, `AiClient`.

**Real mode = `GeminiAiClient`:** the team has no Blaze plan, so the app
talks to Gemini **directly** through Firebase AI Logic (Gemini Developer
API, free on Spark). Firebase keeps the key: never put an API key in the
app. The prompts are in `gemini_prompts.dart` (the same prompts as
`functions/src/ai/features/*.ts`). `CloudFunctionsAiClient` (the
`aiGateway` function) is kept for when the team gets Blaze: switching back
is one line in `ai_assistant_injection.dart`.

Setup (once): Firebase console -> AI Services -> AI Logic -> Get started ->
Gemini Developer API.

```dart
import 'package:brainly_life/core/ai/ai.dart';
```

## Files

| File | What it has |
|---|---|
| `ai_client.dart` | `AiClient` — `Future<Result<AiResponse>> generate(AiRequest request)` |
| `ai_models.dart` | `AiFeature`, `AiRequest`, `AiResponse`, `AiUsage` |
| `ai_failures.dart` | `AiErrorCode` (the gateway codes) and `AiGatewayFailure` |
| `gemini_ai_client.dart` | the real client: Gemini directly (limits, checks, weekly report) |
| `gemini_prompts.dart` | the prompt of every feature |
| `firebase_gemini_call.dart` | the only file that uses `firebase_ai` |
| `shared_prefs_ai_usage_counter.dart` | the daily limits, counted on the phone |
| `cloud_functions_ai_client.dart` | the Cloud Functions client (for Blaze later) |
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
- **Never put the uid, name, e-mail or photo in the payload.**
- The chat also gets the user's data (study planner, tasks, habit streak)
  from `AiChatContext` in the ai_assistant feature.
- The payload must be at most 20 KB (bigger -> `payloadTooLarge`, no call).

## What the real client does

- Returns `disabled` without calling Gemini when the user turned
  **"Use AI features"** off in Settings.
- Daily limit per feature, counted on the phone (studyPlan 5,
  habitSuggest 5, chat 20, dailyTip 3, weeklyInsight 3).
- 60-second timeout (then a `NetworkFailure`).
- A broken answer is retried **once**, then `invalidResponse`.
- `rateLimited` also when the free tier of the whole project is used up.
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

- `AiLoadingBubble({label})` — "Baseet AI is typing" bubble.
- `AiErrorCard({required failure, onRetry})` — message from the failure,
  retry button when `onRetry` is given.
- `AiDisclaimer()` — "AI can make mistakes." Put it under every AI answer.
- `AiSuggestionCard({required title, required text, onDismiss})`.

## Adding a new AI feature

1. Add the name to `AiFeature` and a fixture in `MockAiClient`.
2. Add its prompt to `GeminiPrompts`, its limit and temperature to
   `GeminiAiClient`, and its answer check to `GeminiAiClient.checkAnswer`.
3. (For Blaze later) the server module in `functions/src/ai/features/`.
