// FocusSettingsScreen lets the user change the timer lengths and behaviour
// (auto start, sound, vibration, keep screen on). Every change is saved right
// away, so there is no Save button. All colors, text styles and spacing come
// from the theme.

import 'package:brainly_life/core/constants/app_strings.dart';
import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/widgets/widgets.dart';
import 'package:brainly_life/features/focus/data/models/focus_settings_model.dart';
import 'package:brainly_life/features/focus/logic/focus_settings_cubit.dart';
import 'package:brainly_life/features/focus/logic/focus_settings_state.dart';
import 'package:brainly_life/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FocusSettingsScreen extends StatelessWidget {
  const FocusSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<FocusSettingsCubit>()..load(),
      child: const FocusSettingsView(),
    );
  }
}

class FocusSettingsView extends StatelessWidget {
  const FocusSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(AppStrings.focusSettingsTitle),
      ),
      body: BlocConsumer<FocusSettingsCubit, FocusSettingsState>(
        listenWhen: (_, current) =>
            current is FocusSettingsLoaded && current.saveFailure != null,
        listener: (context, state) {
          if (state is FocusSettingsLoaded && state.saveFailure != null) {
            AppSnackBar.error(context, state.saveFailure!.userMessage);
          }
        },
        builder: (context, state) {
          final cubit = context.read<FocusSettingsCubit>();
          return switch (state) {
            FocusSettingsInitial() ||
            FocusSettingsLoading() => const LoadingView(),
            FocusSettingsError(:final failure) => ErrorView(
              failure: failure,
              onRetry: cubit.load,
            ),
            FocusSettingsLoaded(:final settings) => _SettingsList(
              settings: settings,
              cubit: cubit,
            ),
          };
        },
      ),
    );
  }
}

class _SettingsList extends StatelessWidget {
  const _SettingsList({required this.settings, required this.cubit});

  final FocusSettings settings;
  final FocusSettingsCubit cubit;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenMargin,
        AppSpacing.s2,
        AppSpacing.screenMargin,
        AppSpacing.s6,
      ),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.focusSettingsTimerSection,
                style: context.text.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.s2),
              _StepperRow(
                label: AppStrings.focusLabelFocus,
                value: settings.focusMinutes,
                valueText: AppStrings.focusMinutesValue(settings.focusMinutes),
                min: FocusSettingsLimits.focusMin,
                max: FocusSettingsLimits.focusMax,
                step: FocusSettingsLimits.focusStep,
                onChanged: cubit.focusMinutesChanged,
              ),
              const Divider(),
              _StepperRow(
                label: AppStrings.focusLabelShortBreak,
                value: settings.shortBreakMinutes,
                valueText: AppStrings.focusMinutesValue(
                  settings.shortBreakMinutes,
                ),
                min: FocusSettingsLimits.shortBreakMin,
                max: FocusSettingsLimits.shortBreakMax,
                step: FocusSettingsLimits.shortBreakStep,
                onChanged: cubit.shortBreakMinutesChanged,
              ),
              const Divider(),
              _StepperRow(
                label: AppStrings.focusLabelLongBreak,
                value: settings.longBreakMinutes,
                valueText: AppStrings.focusMinutesValue(
                  settings.longBreakMinutes,
                ),
                min: FocusSettingsLimits.longBreakMin,
                max: FocusSettingsLimits.longBreakMax,
                step: FocusSettingsLimits.longBreakStep,
                onChanged: cubit.longBreakMinutesChanged,
              ),
              const Divider(),
              _StepperRow(
                label: AppStrings.focusLabelSessionsBeforeLong,
                value: settings.sessionsBeforeLong,
                valueText: '${settings.sessionsBeforeLong}',
                min: FocusSettingsLimits.sessionsMin,
                max: FocusSettingsLimits.sessionsMax,
                step: FocusSettingsLimits.sessionsStep,
                onChanged: cubit.sessionsBeforeLongChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.cardGap),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.focusSettingsBehaviourSection,
                style: context.text.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.s2),
              _SwitchRow(
                label: AppStrings.focusAutoStart,
                value: settings.autoStart,
                onChanged: cubit.autoStartChanged,
              ),
              const Divider(),
              _SwitchRow(
                label: AppStrings.focusSound,
                value: settings.sound,
                onChanged: cubit.soundChanged,
              ),
              const Divider(),
              _SwitchRow(
                label: AppStrings.focusVibration,
                value: settings.vibration,
                onChanged: cubit.vibrationChanged,
              ),
              const Divider(),
              _SwitchRow(
                label: AppStrings.focusKeepScreenOn,
                value: settings.keepScreenOn,
                onChanged: cubit.keepScreenOnChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        AppButton(
          label: AppStrings.focusResetDefaults,
          type: AppButtonType.text,
          onPressed: cubit.resetToDefaults,
        ),
      ],
    );
  }
}

/// A label with a round minus button, the value, and a round plus button.
/// A button is disabled when the value is at its limit.
class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.value,
    required this.valueText,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
  });

  final String label;
  final int value;
  final String valueText;
  final int min;
  final int max;
  final int step;
  final void Function(int value) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s1),
      child: Row(
        children: [
          Expanded(child: Text(label, style: context.text.bodyLarge)),
          _RoundButton(
            icon: Icons.remove_rounded,
            tooltip: AppStrings.focusDecrease,
            onPressed: value > min ? () => onChanged(value - step) : null,
          ),
          SizedBox(
            width: AppSpacing.s12 + AppSpacing.s4,
            child: Text(
              valueText,
              textAlign: TextAlign.center,
              style: context.text.labelLarge,
            ),
          ),
          _RoundButton(
            icon: Icons.add_rounded,
            tooltip: AppStrings.focusIncrease,
            onPressed: value < max ? () => onChanged(value + step) : null,
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        foregroundColor: p.tealStrong,
        disabledForegroundColor: p.iconMuted,
        side: BorderSide(color: onPressed == null ? p.border : p.teal),
        shape: const CircleBorder(),
        minimumSize: const Size.square(AppSizes.minTouchTarget),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final void Function(bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // The card has a background, so the tile needs its own Material,
    // otherwise its tap effect is hidden.
    return Material(
      type: MaterialType.transparency,
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label, style: context.text.bodyLarge),
        value: value,
        onChanged: onChanged,
        thumbColor: WidgetStatePropertyAll(p.onPrimary),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? p.teal : p.iconMuted,
        ),
      ),
    );
  }
}
