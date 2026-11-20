import 'package:brainly_life/features/home/data/repositories/home_summary_port.dart';
import 'package:brainly_life/features/home/data/repositories/mock_home_summary_providers.dart';
import 'package:brainly_life/features/home/home_injection.dart';
import 'package:brainly_life/features/home/logic/home_cubit.dart';
import 'package:brainly_life/features/home/logic/home_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  late GetIt getIt;

  setUp(() => getIt = GetIt.asNewInstance());

  tearDown(() => getIt.reset());

  test('with no providers registered, every card uses its mock', () async {
    registerHomeFeature(getIt, useMocks: true);

    final cubit = getIt<HomeCubit>();
    await cubit.load();

    expect(cubit.state.tasks, isA<HomeCardLoaded<TaskSummary>>());
    expect(cubit.state.study, isA<HomeCardLoaded<StudySummary?>>());
    expect(cubit.state.habits, isA<HomeCardLoaded<HabitSummary>>());
    expect(cubit.state.focus, isA<HomeCardLoaded<FocusSummary>>());
    expect(cubit.state.tip, isA<HomeCardLoaded<String>>());
    await cubit.close();
  });

  test('uses a real provider registered AFTER home', () async {
    registerHomeFeature(getIt, useMocks: false);
    const real = HabitSummary(
      doneTodayCount: 4,
      dueTodayCount: 4,
      bestCurrentStreak: 30,
      bestStreakHabitName: 'Gym',
    );
    getIt.registerLazySingleton<HabitSummaryProvider>(
      () => MockHabitSummaryProvider(summary: real),
    );

    final cubit = getIt<HomeCubit>();
    await cubit.load();

    expect(cubit.state.habits, const HomeCardLoaded(real));
    await cubit.close();
  });

  test('gives a new HomeCubit to every screen', () async {
    registerHomeFeature(getIt, useMocks: true);

    final first = getIt<HomeCubit>();
    final second = getIt<HomeCubit>();

    expect(identical(first, second), isFalse);
    await first.close();
    await second.close();
  });
}
