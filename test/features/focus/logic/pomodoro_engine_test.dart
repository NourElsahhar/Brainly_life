// Tests for PomodoroEngine: start, pause/resume, background simulation with a
// fake clock, restore after restart, cycles and long break, stop and skip.

import 'package:brainly_life/features/focus/data/models/focus_session_model.dart';
import 'package:brainly_life/features/focus/data/models/focus_settings_model.dart';
import 'package:brainly_life/features/focus/logic/pomodoro_engine.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime.utc(2026, 11, 16, 9);

  /// Runs [body] as if the time were [t0] plus [offset].
  T at<T>(Duration offset, T Function() body) =>
      withClock(Clock.fixed(t0.add(offset)), body);

  const min10 = Duration(minutes: 10);
  const min20 = Duration(minutes: 20);
  const min25 = Duration(minutes: 25);
  const min30 = Duration(minutes: 30);

  late PomodoroEngine engine;

  setUp(() {
    engine = PomodoroEngine(settings: const FocusSettings());
  });

  test('start begins a 25 minute focus block', () {
    final state = at(Duration.zero, () => engine.start());
    expect(state.status, PomodoroStatus.running);
    expect(state.mode, FocusSessionType.focus);
    expect(state.endsAt, t0.add(min25));
    expect(at(Duration.zero, () => engine.remainingSeconds), 1500);
  });

  test('remaining time comes from the clock, not from ticks', () {
    at(Duration.zero, () => engine.start());
    expect(at(min10, () => engine.remainingSeconds), 900);
  });

  test('pause freezes the time and resume continues from it', () {
    at(Duration.zero, () => engine.start());

    final paused = at(min10, () => engine.pause());
    expect(paused.status, PomodoroStatus.paused);
    expect(paused.remainingSeconds, 900);

    expect(at(min20, () => engine.remainingSeconds), 900);

    final resumed = at(min20, () => engine.resume());
    expect(resumed.status, PomodoroStatus.running);
    expect(resumed.endsAt, t0.add(const Duration(minutes: 35)));
    expect(at(min30, () => engine.remainingSeconds), 300);
  });

  test('app in background: refresh finishes the block from endsAt', () {
    at(Duration.zero, () => engine.start());

    final state = at(const Duration(minutes: 26), () => engine.refresh());
    expect(state.status, PomodoroStatus.finished);
    expect(state.cycle, 1);
    expect(state.endsAt, t0.add(min25));
  });

  test('pause after the time is up finishes the block instead', () {
    at(Duration.zero, () => engine.start());
    final state = at(min30, () => engine.pause());
    expect(state.status, PomodoroStatus.finished);
  });

  test('state restored after an app restart keeps counting', () {
    final json = at(Duration.zero, () {
      engine.start(taskId: 't1');
      return engine.state.toJson();
    });

    final restoredState = PomodoroState.fromJson(json);
    expect(restoredState, engine.state);

    final restored = PomodoroEngine(
      settings: const FocusSettings(),
      state: restoredState,
    );
    expect(restored.state.taskId, 't1');
    expect(at(min10, () => restored.remainingSeconds), 900);
    expect(at(min30, () => restored.refresh()).status, PomodoroStatus.finished);
  });

  test('a second start is ignored while a block is running', () {
    at(Duration.zero, () => engine.start());
    final state = at(
      const Duration(minutes: 5),
      () => engine.start(taskId: 'other'),
    );
    expect(state.endsAt, t0.add(min25));
    expect(state.taskId, isNull);
  });

  test('long break comes after sessionsBeforeLong focus blocks', () {
    final engine = PomodoroEngine(
      settings: const FocusSettings(sessionsBeforeLong: 2),
    );

    at(Duration.zero, () => engine.start());
    at(min25, () {
      engine.refresh();
      expect(engine.nextMode, FocusSessionType.shortBreak);
      engine.startNext();
    });
    at(min30, () {
      engine.refresh();
      expect(engine.state.cycle, 1);
      expect(engine.nextMode, FocusSessionType.focus);
      engine.startNext();
    });
    at(const Duration(minutes: 55), () {
      engine.refresh();
      expect(engine.state.cycle, 2);
      expect(engine.nextMode, FocusSessionType.longBreak);
      engine.startNext();
    });
    at(const Duration(minutes: 70), () {
      engine.refresh();
      expect(engine.state.status, PomodoroStatus.finished);
      expect(engine.state.cycle, 0);
    });
  });

  test('stop goes back to idle and keeps the cycle count', () {
    at(Duration.zero, () => engine.start());
    at(min25, () {
      engine.refresh();
      engine.startNext();
    });
    final state = at(const Duration(minutes: 27), () => engine.stop());
    expect(state.status, PomodoroStatus.idle);
    expect(state.cycle, 1);
  });

  test('skipBreak goes to idle and a long break resets the cycle', () {
    final engine = PomodoroEngine(
      settings: const FocusSettings(sessionsBeforeLong: 1),
    );
    at(Duration.zero, () => engine.start());
    at(min25, () {
      engine.refresh();
      engine.startNext();
    });
    expect(engine.state.mode, FocusSessionType.longBreak);

    final state = at(const Duration(minutes: 26), () => engine.skipBreak());
    expect(state.status, PomodoroStatus.idle);
    expect(state.cycle, 0);
  });

  test('elapsedSeconds is the time spent so far in the block', () {
    at(Duration.zero, () => engine.start());
    expect(at(min10, () => engine.elapsedSeconds), 600);
  });
}
