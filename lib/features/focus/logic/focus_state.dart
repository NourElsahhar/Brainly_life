// States of the Pomodoro screen: initial, loading, error, and loaded (the
// timer, the time left, the settings). There is no empty state: an idle
// timer is shown as ready to start.

import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/features/focus/data/models/focus_session_model.dart';
import 'package:brainly_life/features/focus/data/models/focus_settings_model.dart';
import 'package:brainly_life/features/focus/logic/pomodoro_engine.dart';
import 'package:equatable/equatable.dart';

sealed class FocusState extends Equatable {
  const FocusState();

  @override
  List<Object?> get props => [];
}

class FocusInitial extends FocusState {
  const FocusInitial();
}

class FocusLoading extends FocusState {
  const FocusLoading();
}

class FocusError extends FocusState {
  const FocusError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

class FocusLoaded extends FocusState {
  const FocusLoaded({
    required this.timer,
    required this.remainingSeconds,
    required this.settings,
    required this.nextMode,
    this.taskId,
    this.studySessionId,
    this.finishCount = 0,
    this.saveFailure,
  });

  final PomodoroState timer;

  /// Seconds left in the current block.
  final int remainingSeconds;

  final FocusSettings settings;

  /// The block that comes after the current one.
  final FocusSessionType nextMode;

  /// Task or study session linked to the timer (from the route or the
  /// running block). Null when there is none.
  final String? taskId;
  final String? studySessionId;

  /// Goes up by one every time a block finishes. The screen uses it to play
  /// the sound and the vibration once.
  final int finishCount;

  /// Set when saving a finished block failed. The screen shows a snackbar.
  final Failure? saveFailure;

  PomodoroStatus get status => timer.status;

  FocusSessionType get mode => timer.mode;

  /// The number shown inside the ring.
  int get displaySeconds => status == PomodoroStatus.idle
      ? settings.focusMinutes * 60
      : remainingSeconds;

  /// How full the ring is, from 1 (just started) to 0 (finished).
  double get ringFraction => switch (status) {
    PomodoroStatus.idle => 1,
    PomodoroStatus.finished => 0,
    PomodoroStatus.running || PomodoroStatus.paused =>
      timer.plannedSeconds == 0
          ? 0
          : (remainingSeconds / timer.plannedSeconds).clamp(0, 1).toDouble(),
  };

  /// Finished focus blocks since the last long break, for the dots.
  int get filledDots =>
      timer.cycle.clamp(0, settings.sessionsBeforeLong).toInt();

  @override
  List<Object?> get props => [
    timer,
    remainingSeconds,
    settings,
    nextMode,
    taskId,
    studySessionId,
    finishCount,
    saveFailure,
  ];
}
