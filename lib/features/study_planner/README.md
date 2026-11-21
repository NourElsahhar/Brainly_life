# study_planner feature

Owner: **M2**. Subjects, topics, AI-generated study plans, the weekly plan,
plan adjustment, and the server prompt module `studyPlan.ts`.

Plans are generated and adjusted **by AI only** (Master Document v1.1).
There is no rule-based planner. An invalid or missing AI answer is never
saved, the current plan stays unchanged, and the screen shows `AiErrorCard`
with "Try again".

## Status

| Part | State |
| --- | --- |
| Models (`Subject`, `Topic`, `StudyPlan`, `StudySession`, `PlanConstraints`) | Done (Freezed, see open decision 1) |
| `StudyRepository`, `MockStudyRepository`, `StudySessionCompletionPort` | Done, mock only |
| `PlanValidator`, `PlanAdjuster` | Done, AI-only (`RuleBasedPlanner` removed) |
| AI contract + prompt module `functions/src/ai/features/studyPlan.ts` | Done, 49 tests |
| Payload builder, AI response parser, `PlanGenerationService` | Not started (needs M5's `AiClient`) |
| Firestore data source, Cubits, screens | Not started |

## Public contracts (what other members may use)

| Contract | Used by | File |
| --- | --- | --- |
| `StudySummaryProvider.nextSession()` | M3 (Home card) | defined by M3 in `home/data/repositories/home_summary_port.dart`, implemented here |
| `StudySessionCompletionPort` | M4 (Focus) | `data/repositories/study_session_completion_port.dart` |
| Focus link | M4 | this feature opens `AppRoutes.focusPath(studySessionId: id)` |

Never import this feature's Cubits, screens or data sources.

## Firestore (Master Document D.3)

All under `users/{uid}/`. Every document has `createdAt` and `updatedAt`
written with `FieldValue.serverTimestamp()`. Exact moments are UTC
`Timestamp`s; whole days are `dateKey` strings (`yyyy-MM-dd`) from
`DateKeyUtils`.

| Collection | Fields |
| --- | --- |
| `subjects` | `name`, `colorValue`, `examDate`, `priority` |
| `topics` | `subjectId`, `title`, `difficulty` (1-5), `estimatedMinutes`, `completedMinutes`, `status` (`notStarted`, `inProgress`, `done`) |
| `studyPlans` | `title`, `startDate`, `endDate`, `promptVersion`, `status` (`active`, `archived`), `constraints` |
| `studySessions` | `planId`, `subjectId`, `topicId`, `date` (dateKey), `startAt`, `plannedMinutes` (10-180), `actualMinutes`, `status` (`planned`, `done`, `skipped`, `missed`) |

Saving a whole plan uses batched writes, at most 500 operations per batch.

Indexes for `firestore.indexes.json` (M1 merges):

```json
{"collectionGroup": "studySessions", "queryScope": "COLLECTION",
 "fields": [{"fieldPath": "status", "order": "ASCENDING"},
            {"fieldPath": "date", "order": "ASCENDING"}]},
{"collectionGroup": "studySessions", "queryScope": "COLLECTION",
 "fields": [{"fieldPath": "planId", "order": "ASCENDING"},
            {"fieldPath": "date", "order": "ASCENDING"}]}
```

## AI contract: feature `studyPlan`, prompt version 1

The app calls M5's `AiClient.generate(AiRequest(feature: AiFeature.studyPlan,
payload: ..., promptVersion: 1))`. M1's gateway runs
`functions/src/ai/features/studyPlan.ts`, which exports `feature`,
`promptVersion`, `dailyLimit` (5), `temperature` (0.3), `payloadSchema`,
`buildPrompt(payload, ctx)`, `responseSchema` and `validateAgainstPayload`.

Registry line for M1: `import * as studyPlan from "./features/studyPlan";`

### Payload (Flutter -> gateway)

Strict: any field not listed here is rejected, so no name, email, uid or
photo can reach the AI provider. Dates are `yyyy-MM-dd`, times `HH:mm`,
both in the user's **local** time.

```json
{
  "mode": "new",
  "today": "2026-11-21",
  "currentTime": "09:00",
  "startDate": "2026-11-21",
  "endDate": "2026-12-02",
  "preferredStudyTime": "evening",
  "completionRatio": 0.8,
  "constraints": {
    "minutesPerWeekday": {"1": 180, "2": 180, "3": 180, "4": 120, "6": 120, "7": 120},
    "daysOff": [5],
    "maxSessionMinutes": 45,
    "breakMinutes": 10
  },
  "subjects": [
    {"id": "subj_physics", "name": "Physics", "examDate": "2026-11-26", "priority": "high"}
  ],
  "topics": [
    {"id": "topic_forces", "subjectId": "subj_physics", "title": "Forces",
     "difficulty": 3, "remainingMinutes": 135}
  ]
}
```

| Field | Rule |
| --- | --- |
| `mode` | `new` (wizard) or `adjust` (adjust plan) |
| `today`, `currentTime` | The user's local day and time at the tap. Nothing may start earlier |
| `startDate`, `endDate` | Days the AI may use, both included, at most 60 days, `startDate >= today` |
| `preferredStudyTime` | Optional, from `settings.preferredStudyTime` |
| `completionRatio` | 0-1. Optional in `new` (previous plan), **required** in `adjust` |
| `bookedMinutesByDate` | `adjust` only, optional. Minutes already used on a day by kept sessions |
| `constraints` | Same map as `PlanConstraints.toFirestore()`. Weekday keys `"1"` (Monday) to `"7"` (Sunday); a missing weekday is 0 minutes |
| `subjects[].priority` | `low`, `medium`, `high` (the model stores 1, 2, 3) |
| `subjects[].examDate` | Local day of the exam, must be after `startDate` |
| `topics[].remainingMinutes` | `estimatedMinutes - completedMinutes`, 1 to 12000. Do not send finished topics |
| ids | Letters, digits, `_`, `-`, max 64 (Firestore auto ids fit) |
| names / titles | Subject name 1-60, topic title 1-100 characters |

Every subject needs at least one topic, every topic's `subjectId` must be
sent, ids are unique, and the window must contain some free time.
**Check these in the wizard too**, so the user gets an inline error and no
AI call is spent.

### Response (gateway -> Flutter, inside `AiResponse.data`)

```json
{"sessions": [
  {"subjectId": "subj_physics", "topicId": "topic_forces",
   "date": "2026-11-21", "startTime": "17:00", "plannedMinutes": 45}
]}
```

1 to 240 sessions, `plannedMinutes` 10-180, each session ends by midnight.
`date` + `startTime` are local: the app turns them into the UTC `startAt`
with the user's timezone before validating and saving.

The gateway also runs `validateAgainstPayload`: only sent ids, topic belongs
to its subject, only free days inside the window, never on or after the
exam day, nothing before `currentTime` today, at most `maxSessionMinutes`,
day totals within the free minutes, no overlaps. The Flutter
`PlanValidator` checks again before saving.

### Prompt safety

Subject names and topic titles go inside one
`<<<STUDY_DATA_BEGIN>>> ... <<<STUDY_DATA_END>>>` block as JSON strings,
with control characters and copies of the markers removed. The prompt says
the block is data. The real protection is the output check: the AI can
only reference ids we sent, so injected text cannot add anything to a plan.

### Tests

```bash
cd functions
npx tsx --test test/ai/features/studyPlan.test.ts
```

This needs `zod` installed in `functions/`, which comes with M1's functions
scaffold (`package.json`). The module and tests work with zod 3 and zod 4,
and pass the ESLint rules of the Firebase TypeScript template.

Fixtures (normal, minimal, hostile, adjust) are in
`functions/test/ai/features/studyPlan.fixtures.ts`.

## Open decisions (need team approval)

1. Freezed models vs. hand-written Equatable models (Master E.2, F.3).
2. `notes` on `studySessions` (shown on Session detail, missing in D.3).
3. Subject priority stored as `1, 2, 3` = low, medium, high.
4. Gateway error code for a payload that fails `payloadSchema` (C.3 has none).
5. A `DateKeyUtils` helper from M1 that turns a local `dateKey` + `HH:mm`
   into UTC correctly on daylight-saving days.