# Baseet Cloud Functions (owner: M1)

| Function | Type | What it does |
|---|---|---|
| `aiGateway` | callable | The ONLY way the app talks to the AI. Checks the user, the limits and the answer. |
| `deleteUserData` | Auth trigger | When an account is deleted, removes `users/{uid}/**` and `users/{uid}/` in Storage. |

TypeScript, Node 22, Cloud Functions v2 (the Auth trigger uses v1: v2 has no delete trigger).

## Commands (inside `functions/`)

```bash
npm install          # once
npm run build        # TypeScript -> lib/
npm test             # all tests, fake AI, no cost   (npm test -- gateway: one file)
npm run serve        # build + emulators (auth, firestore, functions)
npm run deploy       # deploy the functions (M1 / team lead only)
```

## The AI key (never in Git, never in the app)

- **Production** (M1 / team lead): `firebase functions:secrets:set GEMINI_API_KEY`
- **Emulator** (everyone): create `functions/.secret.local` with your own free key:
  ```
  GEMINI_API_KEY=your-personal-key
  ```
  It is in `.gitignore`. If a key is ever pushed, tell M1: it is revoked at once.

## Contract (Master Document C.3)

Request: `{ feature, payload, promptVersion? }` (payload ≤ 20 KB)
Response: `{ ok: true, data, usage: { remainingToday, feature } }`
or `{ ok: false, error: { code, message }, usage? }`

Error codes (do not add new ones): `unauthenticated`, `invalid_feature`
(unknown feature or invalid payload), `payload_too_large`, `rate_limited`,
`provider_unavailable`, `invalid_response`, `internal`.

Limits are in `src/ai/config.ts` (30 calls/day in total; chat 20, studyPlan 5,
weeklyInsight 3). Usage is counted in `users/{uid}/aiUsage/{dateKey}`, by the
user's own day (their time zone).

## How to add your AI feature (3 steps)

1. Write `src/ai/features/<yourFeature>.ts` that exports
   (see `src/ai/types.ts` → `FeatureModule`, and `studyPlan.ts` as a full example):

   ```ts
   export const feature = "habitSuggest";      // one of KNOWN_FEATURES in config.ts
   export const dailyLimit = 10;                // optional
   export const temperature = 0.3;              // optional (0.7 for chat)
   export const payloadSchema = z.object({...}).strict();
   export const responseSchema = z.object({...});
   export function buildPrompt(payload, ctx) {  // ctx = { uid, db, now }
     return {system: "...", user: "<<<DATA_BEGIN>>>...<<<DATA_END>>>"};
   }
   export function validateAgainstPayload(payload, data): string[] {...} // optional
   export async function persist(ctx, data, payload) {...}               // optional
   ```
2. Add ONE import and ONE line in `src/ai/registry.ts`.
3. Add tests with `FakeProvider` (normal, minimal, hostile text) and run `npm test`.

The gateway does the rest: auth, size, payload check (the AI is never called
for an invalid payload), daily limits, JSON mode, `responseSchema`,
`validateAgainstPayload`, ONE repair retry, `persist`, safe logs.

Rules for prompts (C.4): role + rules + exact JSON shape + one example; user
text only inside a delimited data block that the prompt says to treat as data;
never send name, email, uid or photo to the AI; logs never contain prompts,
payloads or answers.

## Deleting an account

The app deletes `users/{uid}` and the Firebase account (Settings → Delete
account). `deleteUserData` then runs by itself and removes every
subcollection with `recursiveDelete`, plus the user's Storage files. Nothing
else to call from the app.
