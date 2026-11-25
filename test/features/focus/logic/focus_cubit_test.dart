// Tests for FocusCubit: loading, starting, finishing and saving a block,
// stopping early, pause and resume, the study session minutes, auto start,
// and restoring the timer after the app was closed.

import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/focus/data/datasources/focus_timer_local_data_source.dart';
import 'package:brainly_life/features/focus/data/models/focus_session_model.dart';
import 'package:brainly_life/features/focus/data/models/focus_settings_model.dart';
import 'package:brainly_life/features/focus/data/repositories/mock_focus_repository.dart';
import 'package:brainly_life/features/focus/logic/focus_cubit.dart';
import 'package:brainly_life/features/focus/logic/focus_state.dart';
import 'package:brainly_life/features/focus/logic/pomodoro_engine.dart';
import 'package:brainly_life/features/study_planner/data/repositories/study_session_completion_port.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCompletionPort implements StudySessionCompletionPort {
  final List<(String, int)> calls = [];

  @override
  Future<Result<void>> addActualMinutes({
    required String studySessionId,
    required int minutes,
  }) async {
    calls.add((studySessionId, minutes));
    return const Result.success(null);
  }
}

class _FailingSettingsRepository extends MockFocusRepository {
  @override
  Future<Result<FocusSettings>> getSettings() async =>
      const Result.failure(NetworkFailure());
}

void main() {
  final t0 = DateTime.utc(2026, 11, 16, 9);
  const min10 = Duration(minutes: 10);
  const min20 = Duration(minutes: 20);
  const min26 = Duration(minutes: 26);
  const min30 = Duration(minutes: 30);
  const min40 = Duration(minutes: 40);

  /// Runs [body] as if the time were [t0] plus [offset].
  Future<T> at<T>(Duration offset, Future<T> Function() body) =>
      withClock(Clock.fixed(t0.add(offset)), body);

  late MockFocusRepository repository;
  late MockFocusTimerLocalDataSource store;
  late _FakeCompletionPort port;

  setUp(() {
    repository = MockFocusRepository();
    store = MockFocusTimerLocalDataSource();
    port = _FakeCompletionPort();
  });

  FocusCubit buildCubit({
    String? taskId,
    String? studySessionId,
    FocusSettings? settings,
    MockFocusRepository? repositoryOverride,
  }) {
    if (settings != null) repository = MockFocusRepository(settings: settings);
    final cubit = FocusCubit(
      repository: repositoryOverride ?? repository,
      localDataSource: store,
      timezone: 'UTC',
      completionPort: port,
      taskId: taskId,
      studySessionId: studySessionId,
      tickInterval: const Duration(days: 1),
    );
    addTearDown(cubit.close);
    return cubit;
  }

  FocusLoaded loaded(FocusCubit cubit) => cubit.state as FocusLoaded;

  Future<List<FocusSession>> savedSessions() async =>
      (await repository.getSessions(
        fromDate: '2026-11-01',
        toDate: '2026-11-30',
      )).dataOrNull!;

  test('load shows an idle timer with the focus minutes', () async {
    final cubit = buildCubit();
    await at(Duration.zero, () => cubit.load());

    expect(loaded(cubit).status, PomodoroStatus.idle);
    expect(loaded(cubit).displaySeconds, 1500);
    expect(loaded(cubit).ringFraction, 1);
  });

  test('load emits an error when the settings cannot be loaded', () async {
    final cubit = buildCubit(repositoryOverride: _FailingSettingsRepository());
    await at(Duration.zero, () => cubit.load());

    expect(cubit.state, const FocusError(NetworkFailure()));
  });

  test('start begins a running focus block', () async {
    final cubit = buildCubit();
    await at(Duration.zero, () async {
      await cubit.load();
      await cubit.start();
    });

    expect(loaded(cubit).status, PomodoroStatus.running);
    expect(loaded(cubit).mode, FocusSessionType.focus);
    expect(loaded(cubit).remainingSeconds, 1500);
  });

  test('a finished focus block is saved once and counted', () async {
    final cubit = buildCubit();
    await at(Duration.zero, () async {
      await cubit.load();
      await cubit.start();
    });
    await at(min26, () => cubit.tick());

    expect(loaded(cubit).status, PomodoroStatus.finished);
    expect(loaded(cubit).finishCount, 1);

    final sessions = await savedSessions();
    expect(sessions, hasLength(1));
    expect(sessions.single.id, 'focus_${t0.millisecondsSinceEpoch}');
    expect(sessions.single.actualMinutes, 25);
    expect(sessions.single.completed, isTrue);
    expect(sessions.single.dateKey, '2026-11-16');
  });

  test('the minutes go to the linked study session', () async {
    final cubit = buildCubit(studySessionId: 's1');
    await at(Duration.zero, () async {
      await cubit.load();
      await cubit.start();
    });
    await at(min26, () => cubit.tick());

    expect(port.calls, [('s1', 25)]);
    expect((await savedSessions()).single.studySessionId, 's1');
  });

  test('stop after at least a minute saves a partial session', () async {
    final cubit = buildCubit();
    await at(Duration.zero, () async {
      await cubit.load();
      await cubit.start();
    });
    await at(min10, () => cubit.stop());

    expect(loaded(cubit).status, PomodoroStatus.idle);
    final sessions = await savedSessions();
    expect(sessions.single.actualMinutes, 10);
    expect(sessions.single.completed, isFalse);
  });

  test('stop before one minute saves nothing', () async {
    final cubit = buildCubit();
    await at(Duration.zero, () async {
      await cubit.load();
      await cubit.start();
    });
    await at(const Duration(seconds: 30), () => cubit.stop());

    expect(await savedSessions(), isEmpty);
    expect(loaded(cubit).status, PomodoroStatus.idle);
  });

  test('pause keeps the time and resume continues from it', () async {
    final cubit = buildCubit();
    await at(Duration.zero, () async {
      await cubit.load();
      await cubit.start();
    });
    await at(min10, () => cubit.pause());
    expect(loaded(cubit).status, PomodoroStatus.paused);
    expect(loaded(cubit).remainingSeconds, 900);

    await at(min20, () => cubit.resume());
    await at(min30, () => cubit.tick());
    expect(loaded(cubit).status, PomodoroStatus.running);
    expect(loaded(cubit).remainingSeconds, 300);
  });

  test('auto start begins the next block after a finish', () async {
    final cubit = buildCubit(settings: const FocusSettings(autoStart: true));
    await at(Duration.zero, () async {
      await cubit.load();
      await cubit.start();
    });
    await at(min26, () => cubit.tick());

    expect(loaded(cubit).status, PomodoroStatus.running);
    expect(loaded(cubit).mode, FocusSessionType.shortBreak);
    expect(loaded(cubit).finishCount, 1);
    expect(await savedSessions(), hasLength(1));
  });

  test('a block that ran out while the app was closed is finished', () async {
    final first = buildCubit();
    await at(Duration.zero, () async {
      await first.load();
      await first.start();
    });
    await first.close();

    final second = buildCubit();
    await at(min40, () => second.load());

    expect(loaded(second).status, PomodoroStatus.finished);
    expect(loaded(second).finishCount, 1);
    expect(await savedSessions(), hasLength(1));
  });

  test('a running block continues after the app was closed', () async {
    final first = buildCubit();
    await at(Duration.zero, () async {
      await first.load();
      await first.start();
    });
    await first.close();

    final second = buildCubit();
    await at(min10, () => second.load());

    expect(loaded(second).status, PomodoroStatus.running);
    expect(loaded(second).remainingSeconds, 900);
  });

  test(
    'a finished block restored after a restart is not counted again',
    () async {
      final first = buildCubit(studySessionId: 's1');
      await at(Duration.zero, () async {
        await first.load();
        await first.start();
      });
      await at(min26, () => first.tick());
      await first.close();

      final second = buildCubit(studySessionId: 's1');
      await at(min40, () => second.load());

      expect(loaded(second).status, PomodoroStatus.finished);
      expect(loaded(second).finishCount, 0);
      expect(port.calls, hasLength(1));
      expect(await savedSessions(), hasLength(1));
    },
  );
}
