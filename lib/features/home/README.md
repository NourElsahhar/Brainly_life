# home feature

**Owner:** M3

The Home dashboard: one summary card from every feature.
Home only knows the contracts below; each owner implements their own
provider and registers it in their own `<feature>_injection.dart`.

## Contracts (`data/repositories/home_summary_port.dart`)

| Card | Contract | Data | Implemented by |
|---|---|---|---|
| Today's tasks | `TaskSummaryProvider` | due today, overdue, completed today, next task title | M3 |
| Next study session | `StudySummaryProvider` | subject, topic, start time, planned minutes, or `null` when there is no session | M2 |
| Habits | `HabitSummaryProvider` | done today / due today, best current streak and its habit | M4 |
| Focus | `FocusSummaryProvider` | focus minutes and sessions today | M4 |
| AI tip | `AiTipProvider` | one short tip per day | M5 |

Every method returns a `Result`, so one failing card never breaks the others.
`TaskSummary`, `HabitSummary` and `FocusSummary` have `isEmpty` for the
empty state of their card.

## Mocks (`data/repositories/mock_home_summary_providers.dart`)

One mock per contract with sample data, used by Home until the real
provider exists, and by anyone in tests:

```dart
final tasks = MockTaskSummaryProvider();                    // sample numbers
final study = MockStudySummaryProvider.withSampleData();   // session in 2 hours
final none = MockStudySummaryProvider();                    // no session
final failing = MockAiTipProvider(failWith: const NetworkFailure());
```