// PomodoroEngine is the brain of the timer: idle -> running -> paused -> finished.
// The remaining time is always calculated from `endsAt` minus now (never by
// counting ticks), so it stays correct when the app goes to the background
// or the phone sleeps. Pure Dart: no Flutter, no Firebase.

// ignore_for_file: prefer_initializing_formals

import 'package:brainly_life/features/focus/data/models/focus_session_model.dart';
import 'package:brainly_life/features/focus/data/models/focus_settings_model.dart';
import 'package:clock/clock.dart';
import 'package:equatable/equatable.dart';

enum PomodoroStatus { idle, running, paused, finished }

/// Everything needed to show the timer and to restore it after a restart.
class PomodoroState extends Equatable {
  const PomodoroState({
    this.status = PomodoroStatus.idle,
    this.mode = FocusSessionType.focus,
    this.cycle = 0,
    this.plannedSeconds = 0,
    this.remainingSeconds = 0,
    this.startedAt,
    this.endsAt,
    this.taskId,
    this.studySessionId,
  });

  final PomodoroStatus status;

  /// The current block: focus, short break or long break.
  final FocusSessionType mode;

  /// Focus blocks finished since the last long break.
  final int cycle;

  final int plannedSeconds;

  /// Only used while paused. While running, time comes from [endsAt].
  final int remainingSeconds;

  final DateTime? startedAt;

  /// The moment the block ends (UTC). Kept after the block finishes.
  final DateTime? endsAt;

  final String? taskId;

  final String? studySessionId;

  PomodoroState copyWith({
    PomodoroStatus? status,
    int? cycle,
    int? remainingSeconds,
    DateTime? endsAt,
    bool clearEndsAt = false,
  }) {
    return PomodoroState(
      status: status ?? this.status,
      mode: mode,
      cycle: cycle ?? this.cycle,
      plannedSeconds: plannedSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      startedAt: startedAt,
      endsAt: clearEndsAt ? null : (endsAt ?? this.endsAt),
      taskId: taskId,
      studySessionId: studySessionId,
    );
  }

  /// Plain map for shared_preferences (use jsonEncode on it).
  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'mode': mode.name,
      'cycle': cycle,
      'plannedSeconds': plannedSeconds,
      'remainingSeconds': remainingSeconds,
      'startedAt': startedAt?.toUtc().toIso8601String(),
      'endsAt': endsAt?.toUtc().toIso8601String(),
      'taskId': taskId,
      'studySessionId': studySessionId,
    };
  }

  factory PomodoroState.fromJson(Map<String, dynamic> json) {
    DateTime? readDate(Object? value) =>
        value == null ? null : DateTime.parse(value as String).toUtc();

    return PomodoroState(
      status: PomodoroStatus.values.byName(json['status'] as String),
      mode: FocusSessionType.values.byName(json['mode'] as String),
      cycle: json['cycle'] as int? ?? 0,
      plannedSeconds: json['plannedSeconds'] as int? ?? 0,
      remainingSeconds: json['remainingSeconds'] as int? ?? 0,
      startedAt: readDate(json['startedAt']),
      endsAt: readDate(json['endsAt']),
      taskId: json['taskId'] as String?,
      studySessionId: json['studySessionId'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    mode,
    cycle,
    plannedSeconds,
    remainingSeconds,
    startedAt,
    endsAt,
    taskId,
    studySessionId,
  ];
}

class PomodoroEngine {
  PomodoroEngine({
    required FocusSettings settings,
    PomodoroState state = const PomodoroState(),
  }) : _settings = settings,
       _state = state;

  FocusSettings _settings;
  PomodoroState _state;

  PomodoroState get state => _state;

  /// Seconds left in the current block, calculated from the clock.
  int get remainingSeconds => switch (_state.status) {
    PomodoroStatus.running => _secondsUntilEnd(),
    PomodoroStatus.paused => _state.remainingSeconds,
    PomodoroStatus.idle || PomodoroStatus.finished => 0,
  };

  /// Seconds already spent in the current block (used to save a session).
  int get elapsedSeconds => switch (_state.status) {
    PomodoroStatus.idle => 0,
    PomodoroStatus.finished => _state.plannedSeconds,
    PomodoroStatus.running || PomodoroStatus.paused =>
      (_state.plannedSeconds - remainingSeconds)
          .clamp(0, _state.plannedSeconds)
          .toInt(),
  };

  /// The block that should come after the current one.
  FocusSessionType get nextMode {
    if (_state.mode != FocusSessionType.focus) return FocusSessionType.focus;
    return _state.cycle >= _settings.sessionsBeforeLong
        ? FocusSessionType.longBreak
        : FocusSessionType.shortBreak;
  }

  /// Changing settings does not affect a block that is already running.
  void updateSettings(FocusSettings settings) => _settings = settings;

  /// Starts a block. Ignored while a block is running or paused.
  PomodoroState start({
    FocusSessionType mode = FocusSessionType.focus,
    String? taskId,
    String? studySessionId,
  }) {
    if (_state.status == PomodoroStatus.running ||
        _state.status == PomodoroStatus.paused) {
      return _state;
    }
    final seconds = _minutesFor(mode) * 60;
    final now = clock.now().toUtc();
    _state = PomodoroState(
      status: PomodoroStatus.running,
      mode: mode,
      cycle: _state.cycle,
      plannedSeconds: seconds,
      remainingSeconds: seconds,
      startedAt: now,
      endsAt: now.add(Duration(seconds: seconds)),
      taskId: taskId,
      studySessionId: studySessionId,
    );
    return _state;
  }

  /// Starts the block that follows a finished one (break or focus).
  PomodoroState startNext() {
    if (_state.status != PomodoroStatus.finished) return _state;
    return start(
      mode: nextMode,
      taskId: _state.taskId,
      studySessionId: _state.studySessionId,
    );
  }

  PomodoroState pause() {
    refresh();
    if (_state.status != PomodoroStatus.running) return _state;
    final remaining = remainingSeconds;
    _state = _state.copyWith(
      status: PomodoroStatus.paused,
      remainingSeconds: remaining,
      clearEndsAt: true,
    );
    return _state;
  }

  PomodoroState resume() {
    if (_state.status != PomodoroStatus.paused) return _state;
    final now = clock.now().toUtc();
    _state = _state.copyWith(
      status: PomodoroStatus.running,
      endsAt: now.add(Duration(seconds: _state.remainingSeconds)),
    );
    return _state;
  }

  /// Abandons the current block. The cycle count is kept.
  PomodoroState stop() {
    _state = PomodoroState(cycle: _state.cycle);
    return _state;
  }

  /// Ends a break early and goes back to idle.
  PomodoroState skipBreak() {
    if (_state.status == PomodoroStatus.idle ||
        _state.mode == FocusSessionType.focus) {
      return _state;
    }
    final cycle = _state.mode == FocusSessionType.longBreak ? 0 : _state.cycle;
    _state = PomodoroState(cycle: cycle);
    return _state;
  }

  /// Call this on every tick, when the app returns from the background, and
  /// after restoring a saved state. Moves running -> finished if time is up.
  PomodoroState refresh() {
    if (_state.status == PomodoroStatus.running && remainingSeconds == 0) {
      final cycle = switch (_state.mode) {
        FocusSessionType.focus => _state.cycle + 1,
        FocusSessionType.longBreak => 0,
        FocusSessionType.shortBreak => _state.cycle,
      };
      _state = _state.copyWith(
        status: PomodoroStatus.finished,
        cycle: cycle,
        remainingSeconds: 0,
      );
    }
    return _state;
  }

  int _secondsUntilEnd() {
    final endsAt = _state.endsAt;
    if (endsAt == null) return 0;
    final millis = endsAt.difference(clock.now()).inMilliseconds;
    return millis <= 0 ? 0 : (millis + 999) ~/ 1000;
  }

  int _minutesFor(FocusSessionType mode) => switch (mode) {
    FocusSessionType.focus => _settings.focusMinutes,
    FocusSessionType.shortBreak => _settings.shortBreakMinutes,
    FocusSessionType.longBreak => _settings.longBreakMinutes,
  };
}
