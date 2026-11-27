// FocusScreen is the Pomodoro screen: the mode, a big ring with the time
// left, the focus-block dots and the buttons that fit the timer status.
// It plays the sound and the vibration when a block finishes (if enabled in
// the settings) and keeps the screen on while the timer runs (if enabled).
// All colors, text styles and spacing come from the theme.

// ignore_for_file: unnecessary_import

import 'dart:ui' show FontFeature;

import 'package:brainly_life/core/constants/app_strings.dart';
import 'package:brainly_life/core/routes/app_routes.dart';
import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/widgets/widgets.dart';
import 'package:brainly_life/features/focus/data/datasources/timer_alert.dart';
import 'package:brainly_life/features/focus/data/models/focus_session_model.dart';
import 'package:brainly_life/features/focus/data/models/focus_settings_model.dart';
import 'package:brainly_life/features/focus/logic/focus_cubit.dart';
import 'package:brainly_life/features/focus/logic/focus_state.dart';
import 'package:brainly_life/features/focus/logic/pomodoro_engine.dart';
import 'package:brainly_life/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class FocusScreen extends StatelessWidget {
  const FocusScreen({super.key, this.taskId, this.studySessionId});

  /// From the route: /focus?taskId=&studySessionId=
  final String? taskId;
  final String? studySessionId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<FocusCubit>(param1: taskId, param2: studySessionId)..load(),
      child: const FocusView(),
    );
  }
}

class FocusView extends StatefulWidget {
  const FocusView({super.key});

  @override
  State<FocusView> createState() => _FocusViewState();
}

class _FocusViewState extends State<FocusView> {
  bool _awake = false;

  void _setKeepAwake(bool on) {
    if (on == _awake) return;
    _awake = on;
    WakelockPlus.toggle(enable: on).catchError((_) {});
  }

  void _alert(FocusSettings settings) {
    TimerAlert.play(sound: settings.sound, vibration: settings.vibration);
  }

  Future<void> _openSettings(BuildContext context) async {
    final cubit = context.read<FocusCubit>();
    await context.push(AppRoutes.focusSettings);
    cubit.refreshSettings();
  }

  @override
  void dispose() {
    if (_awake) WakelockPlus.toggle(enable: false).catchError((_) {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // A block finished: sound and vibration, once.
        BlocListener<FocusCubit, FocusState>(
          listenWhen: (previous, current) =>
              previous is FocusLoaded &&
              current is FocusLoaded &&
              current.finishCount > previous.finishCount,
          listener: (context, state) => _alert((state as FocusLoaded).settings),
        ),
        // Saving a block failed: tell the user.
        BlocListener<FocusCubit, FocusState>(
          listenWhen: (previous, current) =>
              current is FocusLoaded &&
              current.saveFailure != null &&
              (previous is! FocusLoaded ||
                  previous.saveFailure != current.saveFailure),
          listener: (context, state) => AppSnackBar.error(
            context,
            (state as FocusLoaded).saveFailure!.userMessage,
          ),
        ),
        // Keep the screen on while the timer runs, if the user wants it.
        BlocListener<FocusCubit, FocusState>(
          listener: (context, state) {
            if (state is FocusLoaded) {
              _setKeepAwake(
                state.status == PomodoroStatus.running &&
                    state.settings.keepScreenOn,
              );
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text(AppStrings.focusTitle),
          actions: [
            IconButton(
              tooltip: AppStrings.focusStatsTooltip,
              icon: const Icon(Icons.bar_chart_rounded),
              onPressed: () => context.push(AppRoutes.focusStats),
            ),
            IconButton(
              tooltip: AppStrings.focusSettingsTooltip,
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => _openSettings(context),
            ),
            const SizedBox(width: AppSpacing.s2),
          ],
        ),
        body: BlocBuilder<FocusCubit, FocusState>(
          builder: (context, state) {
            final cubit = context.read<FocusCubit>();
            return switch (state) {
              FocusInitial() || FocusLoading() => const LoadingView(),
              FocusError(:final failure) => ErrorView(
                failure: failure,
                onRetry: cubit.load,
              ),
              FocusLoaded() => _TimerBody(state: state, cubit: cubit),
            };
          },
        ),
      ),
    );
  }
}

class _TimerBody extends StatelessWidget {
  const _TimerBody({required this.state, required this.cubit});

  final FocusLoaded state;
  final FocusCubit cubit;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenMargin,
          vertical: AppSpacing.s4,
        ),
        child: Column(
          children: [
            _ModeChip(mode: state.mode),
            Expanded(
              child: Center(child: _TimerRing(state: state)),
            ),
            _CycleDots(
              filled: state.filledDots,
              total: state.settings.sessionsBeforeLong,
            ),
            if (state.taskId != null)
              const _LinkChip(
                icon: Icons.task_alt_rounded,
                label: AppStrings.focusLinkedTask,
              ),
            if (state.studySessionId != null)
              const _LinkChip(
                icon: Icons.menu_book_rounded,
                label: AppStrings.focusLinkedStudySession,
              ),
            const SizedBox(height: AppSpacing.s6),
            _Controls(state: state, cubit: cubit),
          ],
        ),
      ),
    );
  }
}

String _modeLabel(FocusSessionType mode) => switch (mode) {
  FocusSessionType.focus => AppStrings.focusModeFocus,
  FocusSessionType.shortBreak => AppStrings.focusModeShortBreak,
  FocusSessionType.longBreak => AppStrings.focusModeLongBreak,
};

String _formatTime(int totalSeconds) {
  final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.mode});

  final FocusSessionType mode;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isFocus = mode == FocusSessionType.focus;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s4,
        vertical: AppSpacing.s2,
      ),
      decoration: BoxDecoration(
        color: isFocus ? p.tealSoft : p.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        _modeLabel(mode),
        style: context.text.labelMedium?.copyWith(
          color: isFocus ? p.tealStrong : p.primary,
        ),
      ),
    );
  }
}

class _TimerRing extends StatelessWidget {
  const _TimerRing({required this.state});

  final FocusLoaded state;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final size = MediaQuery.sizeOf(context).width * 0.7;
    final base = context.text.displayLarge;
    final isFocus = state.mode == FocusSessionType.focus;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: state.ringFraction,
              strokeWidth: AppSizes.progressActiveStrokeWidth,
              strokeCap: StrokeCap.round,
              color: isFocus ? p.teal : p.primary,
              backgroundColor: p.progressTrack,
            ),
          ),
          Text(
            _formatTime(state.displaySeconds),
            style: base?.copyWith(
              fontSize: (base.fontSize ?? 32) * 1.5,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _CycleDots extends StatelessWidget {
  const _CycleDots({required this.filled, required this.total});

  final int filled;
  final int total;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label: AppStrings.focusCycleLabel(filled, total),
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < total; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s1),
                child: Container(
                  width: AppSpacing.s3,
                  height: AppSpacing.s3,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < filled ? p.teal : p.progressTrack,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LinkChip extends StatelessWidget {
  const _LinkChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSizes.iconSmall, color: p.textSecondary),
          const SizedBox(width: AppSpacing.s2),
          Text(
            label,
            style: context.text.bodySmall?.copyWith(color: p.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.state, required this.cubit});

  final FocusLoaded state;
  final FocusCubit cubit;

  @override
  Widget build(BuildContext context) {
    final isBreak = state.mode != FocusSessionType.focus;

    // Stop for a focus block, Skip break for a break.
    final endButton = isBreak
        ? AppButton(
            label: AppStrings.focusSkipBreakAction,
            type: AppButtonType.text,
            onPressed: cubit.skipBreak,
          )
        : AppButton(
            label: AppStrings.focusStopAction,
            type: AppButtonType.destructive,
            onPressed: cubit.stop,
          );

    return switch (state.status) {
      PomodoroStatus.idle => AppButton(
        label: AppStrings.focusStartAction,
        icon: Icons.play_arrow_rounded,
        onPressed: cubit.start,
      ),
      PomodoroStatus.running => _ButtonPair(
        left: AppButton(
          label: AppStrings.focusPauseAction,
          icon: Icons.pause_rounded,
          type: AppButtonType.secondary,
          onPressed: cubit.pause,
        ),
        right: endButton,
      ),
      PomodoroStatus.paused => _ButtonPair(
        left: AppButton(
          label: AppStrings.focusResumeAction,
          icon: Icons.play_arrow_rounded,
          onPressed: cubit.resume,
        ),
        right: endButton,
      ),
      PomodoroStatus.finished => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isBreak ? AppStrings.focusBreakDone : AppStrings.focusFocusDone,
            textAlign: TextAlign.center,
            style: context.text.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.s3),
          AppButton(
            label: switch (state.nextMode) {
              FocusSessionType.focus => AppStrings.focusStartAction,
              FocusSessionType.shortBreak => AppStrings.focusStartShortBreak,
              FocusSessionType.longBreak => AppStrings.focusStartLongBreak,
            },
            icon: Icons.play_arrow_rounded,
            onPressed: cubit.startNext,
          ),
          const SizedBox(height: AppSpacing.s2),
          AppButton(
            label: AppStrings.focusStopAction,
            type: AppButtonType.text,
            onPressed: cubit.stop,
          ),
        ],
      ),
    };
  }
}

class _ButtonPair extends StatelessWidget {
  const _ButtonPair({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: AppSpacing.s3),
        Expanded(child: right),
      ],
    );
  }
}
