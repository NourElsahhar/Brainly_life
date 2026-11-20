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

## Home Cubit (`logic/home_cubit.dart`)

Every card has its own state, `HomeCard<T>` (`logic/home_state.dart`):
`HomeCardLoading` (skeleton), `HomeCardLoaded(data)` or
`HomeCardError(failure)` (Retry). One failing card never hides the others.
The study card is `HomeCardLoaded(null)` when no session is planned.

```dart
final cubit = getIt<HomeCubit>()..load();
await cubit.load();                  // again when the user comes back to Home
await cubit.retry(HomeSection.tip);  // a card's Retry button
```

- `load()` asks all five providers at the same time. Cards that already
  show data keep it until the new data comes (no flashing).
- An older answer never replaces a newer one.

## Connecting your card (M2, M4, M5)

Register your provider in your own `<feature>_injection.dart`, for example:

```dart
getIt.registerLazySingleton<HabitSummaryProvider>(
  () => RepositoryHabitSummaryProvider(getIt()),
);
```

That's all. `home_injection.dart` uses your provider when it is
registered, and the mock until then. The order in `injection.dart` does
not matter.