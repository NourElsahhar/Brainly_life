// FocusCubit drives the Pomodoro screen. It runs the PomodoroEngine, ticks
// every second, saves finished or stopped focus blocks (at least 1 minute),
// reports the minutes to a linked study session, and keeps the running timer
// on the phone so it continues after the app is closed.
//
// A block is saved with an id built from its start time, so saving it twice
// can never create two sessions. Sound, vibration and keep-screen-on are done
// by the screen, not here.
// `timezone` is the user's timezone, used for the dateKey of each session.

// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/core/utils/utils.dart';
import 'package:brainly_life/features/focus/data/datasources/focus_timer_local_data_source.dart';
import 'package:brainly_life/features/focus/data/models/focus_session_model.dart';
import 'package:brainly_life/features/focus/data/models/focus_settings_model.dart';
import 'package:brainly_life/features/focus/data/repositories/focus_repository.dart';
import 'package:brainly_life/features/focus/logic/focus_state.dart';
import 'package:brainly_life/features/focus/logic/pomodoro_engine.dart';
import 'package:brainly_life/features/study_planner/data/repositories/study_session_completion_port.dart';
import 'package:clock/clock.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FocusCubit extends Cubit<FocusState> {
  FocusCubit({
    required FocusRepository repository,
    required FocusTimerLocalDataSource localDataSource,
    required String timezone,
    StudySessionCompletionPort? completionPort,
    String? taskId,
    String? studySessionId,
    Duration tickInterval = const Duration(seconds: 1),
  }) : _repository = repository,
       _localDataSource = localDataSource,
       _timezone = timezone,
       _completionPort = completionPort,
       _taskId = taskId,
       _studySessionId = studySessionId,
       _tickInterval = tickInterval,
       super(const FocusInitial());

  final FocusRepository _repository;
  final FocusTimerLocalDataSource _localDataSource;
  final String _timezone;
  final StudySessionCompletionPort? _completionPort;
  final String? _taskId;
  final String? _studySessionId;
  final Duration _tickInterval;

  late PomodoroEngine _engine;
  FocusSettings _settings = const FocusSettings();
  Timer? _ticker;
  int _finishCount = 0;

  Future<void> load() async {
    emit(const FocusLoading());
    final settingsResult = await _repository.getSettings();
    if (isClosed) return;
    if (settingsResult case Failed(:final failure)) {
      emit(FocusError(failure));
      return;
    }
    _settings = settingsResult.dataOrNull ?? const FocusSettings();

    final saved = await _readSavedState();
    if (isClosed) return;
    _engine = PomodoroEngine(
      settings: _settings,
      state: saved ?? const PomodoroState(),
    );

    Failure? saveFailure;
    if (saved?.status == PomodoroStatus.running) {
      _engine.refresh();
      if (_engine.state.status == PomodoroStatus.finished) {
        // The time ran out while the app was closed.
        _finishCount++;
        saveFailure = await _recordBlock(completed: true);
        if (isClosed) return;
        await _persist();
      }
    }
    _emitLoaded(saveFailure: saveFailure);
    _syncTicker();
  }

  /// Called every second while the timer runs (and by tests).
  Future<void> tick() async {
    if (state is! FocusLoaded) return;
    final before = _engine.state.status;
    _engine.refresh();
    if (before == PomodoroStatus.running &&
        _engine.state.status == PomodoroStatus.finished) {
      await _onFinished();
      return;
    }
    _emitLoaded();
  }

  Future<void> start() async {
    if (state is! FocusLoaded) return;
    _engine.start(taskId: _taskId, studySessionId: _studySessionId);
    await _afterChange();
  }

  /// Starts the block after a finished one (a break, or focus again).
  Future<void> startNext() async {
    if (state is! FocusLoaded) return;
    _engine.startNext();
    await _afterChange();
  }

  Future<void> pause() async {
    if (state is! FocusLoaded) return;
    final before = _engine.state.status;
    _engine.pause();
    if (before == PomodoroStatus.running &&
        _engine.state.status == PomodoroStatus.finished) {
      await _onFinished();
      return;
    }
    await _afterChange();
  }

  Future<void> resume() async {
    if (state is! FocusLoaded) return;
    _engine.resume();
    await _afterChange();
  }

  /// Ends the current block. A focus block of at least 1 minute is saved.
  Future<void> stop() async {
    if (state is! FocusLoaded) return;
    final before = _engine.state.status;
    _engine.refresh();
    if (before == PomodoroStatus.running &&
        _engine.state.status == PomodoroStatus.finished) {
      // The time ran out just before the tap: it counts as a finished block.
      await _onFinished();
      if (isClosed) return;
    }
    Failure? saveFailure;
    if (_engine.state.status == PomodoroStatus.running ||
        _engine.state.status == PomodoroStatus.paused) {
      saveFailure = await _recordBlock(completed: false);
      if (isClosed) return;
    }
    _engine.stop();
    await _afterChange(saveFailure: saveFailure);
  }

  Future<void> skipBreak() async {
    if (state is! FocusLoaded) return;
    _engine.skipBreak();
    await _afterChange();
  }

  /// Reads the settings again (after the settings screen was used).
  Future<void> refreshSettings() async {
    if (state is! FocusLoaded) return;
    final result = await _repository.getSettings();
    if (isClosed) return;
    final settings = result.dataOrNull;
    if (settings == null) return;
    _settings = settings;
    _engine.updateSettings(settings);
    _emitLoaded();
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    return super.close();
  }

  Future<void> _onFinished() async {
    _ticker?.cancel();
    _finishCount++;
    final saveFailure = await _recordBlock(completed: true);
    if (isClosed) return;
    if (_settings.autoStart) _engine.startNext();
    await _afterChange(saveFailure: saveFailure);
  }

  Future<void> _afterChange({Failure? saveFailure}) async {
    await _persist();
    if (isClosed) return;
    _emitLoaded(saveFailure: saveFailure);
    _syncTicker();
  }

  void _emitLoaded({Failure? saveFailure}) {
    final timer = _engine.state;
    final isIdle = timer.status == PomodoroStatus.idle;
    emit(
      FocusLoaded(
        timer: timer,
        remainingSeconds: _engine.remainingSeconds,
        settings: _settings,
        nextMode: _engine.nextMode,
        taskId: isIdle ? _taskId : timer.taskId,
        studySessionId: isIdle ? _studySessionId : timer.studySessionId,
        finishCount: _finishCount,
        saveFailure: saveFailure,
      ),
    );
  }

  void _syncTicker() {
    _ticker?.cancel();
    _ticker = null;
    if (_engine.state.status == PomodoroStatus.running) {
      _ticker = Timer.periodic(_tickInterval, (_) => tick());
    }
  }

  /// Saves a focus block and reports its minutes to the linked study
  /// session. Breaks and blocks shorter than a minute are ignored.
  Future<Failure?> _recordBlock({required bool completed}) async {
    final timer = _engine.state;
    final startedAt = timer.startedAt;
    if (timer.mode != FocusSessionType.focus || startedAt == null) return null;

    final minutes = completed
        ? timer.plannedSeconds ~/ 60
        : _engine.elapsedSeconds ~/ 60;
    if (minutes < 1) return null;

    final now = clock.now().toUtc();
    final session = FocusSession(
      id: 'focus_${startedAt.millisecondsSinceEpoch}',
      type: FocusSessionType.focus,
      startedAt: startedAt,
      endedAt: completed ? (timer.endsAt ?? now) : now,
      plannedMinutes: timer.plannedSeconds ~/ 60,
      actualMinutes: minutes,
      completed: completed,
      dateKey: DateKeyUtils.toDateKey(startedAt, timezone: _timezone),
      taskId: timer.taskId,
      studySessionId: timer.studySessionId,
      createdAt: now,
      updatedAt: now,
    );

    Failure? failure = (await _repository.saveSession(session)).failureOrNull;

    final studyId = timer.studySessionId;
    final port = _completionPort;
    if (studyId != null && port != null) {
      final result = await port.addActualMinutes(
        studySessionId: studyId,
        minutes: minutes,
      );
      failure ??= result.failureOrNull;
    }
    return failure;
  }

  Future<PomodoroState?> _readSavedState() async {
    try {
      final json = await _localDataSource.read();
      return json == null ? null : PomodoroState.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> _persist() async {
    try {
      final timer = _engine.state;
      if (timer.status == PomodoroStatus.idle) {
        await _localDataSource.clear();
      } else {
        await _localDataSource.write(timer.toJson());
      }
    } catch (_) {
      // Keeping the timer on the phone is a bonus. The timer still works.
    }
  }
}
