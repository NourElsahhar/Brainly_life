import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/home/data/repositories/home_summary_port.dart';
import 'package:brainly_life/features/home/data/repositories/mock_home_summary_providers.dart';
import 'package:brainly_life/features/home/logic/home_cubit.dart';
import 'package:brainly_life/features/home/logic/home_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// A tip provider we answer by hand, to test answers that arrive late.
class _ManualTipProvider implements AiTipProvider {
  final List<Completer<Result<String>>> calls = [];

  @override
  Future<Result<String>> dailyTip() {
    final call = Completer<Result<String>>();
    calls.add(call);
    return call.future;
  }
}

void main() {
  late MockTaskSummaryProvider tasks;
  late MockStudySummaryProvider study;
  late MockHabitSummaryProvider habits;
  late MockFocusSummaryProvider focus;
  late MockAiTipProvider tip;

  HomeCubit build({AiTipProvider? tipProvider}) => HomeCubit(
    tasks: tasks,
    study: study,
    habits: habits,
    focus: focus,
    tip: tipProvider ?? tip,
  );

  setUp(() {
    tasks = MockTaskSummaryProvider();
    study = MockStudySummaryProvider(); // no session planned
    habits = MockHabitSummaryProvider();
    focus = MockFocusSummaryProvider();
    tip = MockAiTipProvider(tip: 'Drink water.');
  });

  test('starts with every card loading', () {
    final cubit = build();

    expect(cubit.state, const HomeState());
    expect(cubit.state.tip, isA<HomeCardLoading<String>>());
    cubit.close();
  });

  test('load fills every card', () async {
    final cubit = build();

    await cubit.load();

    expect(cubit.state.tasks, HomeCardLoaded(tasks.summary));
    expect(cubit.state.habits, HomeCardLoaded(habits.summary));
    expect(cubit.state.focus, HomeCardLoaded(focus.summary));
    expect(cubit.state.tip, const HomeCardLoaded('Drink water.'));
    await cubit.close();
  });

  test('no study session is Loaded with null, not an error', () async {
    final cubit = build();

    await cubit.load();

    expect(cubit.state.study, const HomeCardLoaded<StudySummary?>(null));
    await cubit.close();
  });

  test('one failing card does not stop the others', () async {
    tip.failWith = const NetworkFailure();
    final cubit = build();

    await cubit.load();

    expect(cubit.state.tip, const HomeCardError<String>(NetworkFailure()));
    expect(cubit.state.tasks, isA<HomeCardLoaded<TaskSummary>>());
    expect(cubit.state.habits, isA<HomeCardLoaded<HabitSummary>>());
    await cubit.close();
  });

  blocTest<HomeCubit, HomeState>(
    'retry shows loading for that card only, then its data',
    build: build,
    seed: () => HomeState(
      tasks: HomeCardLoaded(MockTaskSummaryProvider().summary),
      tip: const HomeCardError(NetworkFailure()),
    ),
    act: (cubit) => cubit.retry(HomeSection.tip),
    expect: () => [
      HomeState(tasks: HomeCardLoaded(MockTaskSummaryProvider().summary)),
      HomeState(
        tasks: HomeCardLoaded(MockTaskSummaryProvider().summary),
        tip: const HomeCardLoaded('Drink water.'),
      ),
    ],
  );

  test('loading again keeps the shown data and retries the errors', () async {
    tip.failWith = const NetworkFailure();
    final cubit = build();
    await cubit.load();

    tip.failWith = null;
    final states = <HomeState>[];
    final subscription = cubit.stream.listen(states.add);
    await cubit.load();

    // The tasks card never went back to loading.
    expect(states.every((s) => s.tasks is HomeCardLoaded), isTrue);
    // The tip card went to loading, then loaded.
    expect(states.first.tip, isA<HomeCardLoading<String>>());
    expect(cubit.state.tip, const HomeCardLoaded('Drink water.'));
    await subscription.cancel();
    await cubit.close();
  });

  test('an older answer never replaces a newer one', () async {
    final manual = _ManualTipProvider();
    final cubit = build(tipProvider: manual);

    final first = cubit.retry(HomeSection.tip);
    final second = cubit.retry(HomeSection.tip);

    // The second request answers first, then the first one fails late.
    manual.calls[1].complete(const Result.success('New tip'));
    await second;
    manual.calls[0].complete(const Result.failure(NetworkFailure()));
    await first;

    expect(cubit.state.tip, const HomeCardLoaded('New tip'));
    await cubit.close();
  });
}
