// HabitFormScreen is the add / edit habit form: name, icon, color, how often
// (daily, chosen weekdays, or times per week) and the start date. Validation
// errors show under the field. The save button shows a spinner while saving.
// It closes after a successful save. All colors, text styles and spacing come
// from the theme.

import 'package:brainly_life/core/constants/app_strings.dart';
import 'package:brainly_life/core/routes/app_routes.dart';
import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/utils/utils.dart';
import 'package:brainly_life/core/widgets/widgets.dart';
import 'package:brainly_life/features/habits/data/models/habit_model.dart';
import 'package:brainly_life/features/habits/logic/habit_form_cubit.dart';
import 'package:brainly_life/features/habits/logic/habit_form_state.dart';
import 'package:brainly_life/features/habits/logic/habit_templates.dart';
import 'package:brainly_life/features/habits/presentation/widgets/habit_icons.dart';
import 'package:brainly_life/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class HabitFormScreen extends StatelessWidget {
  const HabitFormScreen({super.key, this.habit, this.template});

  /// The habit to edit. Null creates a new one.
  final Habit? habit;

  /// A quick-start habit or an AI tip that fills a new habit.
  final HabitTemplate? template;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<HabitFormCubit>(param1: habit, param2: template),
      child: const HabitFormView(),
    );
  }
}

class HabitFormView extends StatefulWidget {
  const HabitFormView({super.key});

  @override
  State<HabitFormView> createState() => _HabitFormViewState();
}

class _HabitFormViewState extends State<HabitFormView> {
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
      text: context.read<HabitFormCubit>().state.name,
    );
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _close(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.habits);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<HabitFormCubit>();
    return BlocListener<HabitFormCubit, HabitFormState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == HabitFormStatus.saved) {
          AppSnackBar.success(context, AppStrings.habitFormSaved);
          _close(context);
        } else if (state.status == HabitFormStatus.failed &&
            state.failure != null) {
          AppSnackBar.error(context, state.failure!.userMessage);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: AppStrings.habitFormClose,
            icon: const Icon(Icons.close_rounded),
            onPressed: () => _close(context),
          ),
          title: Text(
            cubit.state.isEditing
                ? AppStrings.habitEditTitle
                : AppStrings.habitNewTitle,
          ),
        ),
        body: BlocBuilder<HabitFormCubit, HabitFormState>(
          builder: (context, state) =>
              _FormBody(state: state, cubit: cubit, nameController: _name),
        ),
      ),
    );
  }
}

DateTime _localDate(String dateKey) {
  final date = DateKeyUtils.parse(dateKey);
  return DateTime(date.year, date.month, date.day);
}

class _FormBody extends StatelessWidget {
  const _FormBody({
    required this.state,
    required this.cubit,
    required this.nameController,
  });

  final HabitFormState state;
  final HabitFormCubit cubit;
  final TextEditingController nameController;

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
        AppTextField(
          label: AppStrings.habitNameLabel,
          controller: nameController,
          errorText: state.nameError,
          maxLength: Habit.maxNameLength,
          textInputAction: TextInputAction.done,
          onChanged: cubit.nameChanged,
        ),
        const SizedBox(height: AppSpacing.s5),
        _IconPicker(selected: state.icon, onChanged: cubit.iconChanged),
        const SizedBox(height: AppSpacing.s5),
        ColorPickerRow(
          label: AppStrings.habitFormColorLabel,
          selectedColorValue: state.colorValue,
          onChanged: cubit.colorChanged,
        ),
        const SizedBox(height: AppSpacing.s5),
        _FrequencyPicker(state: state, cubit: cubit),
        const SizedBox(height: AppSpacing.s5),
        DateTimePickerField(
          label: AppStrings.habitFormStartDate,
          value: _localDate(state.startDate),
          firstDate: _localDate(cubit.earliestStartDate),
          onChanged: (value) {
            if (value != null) {
              cubit.startDateChanged(DateKeyUtils.fromCalendarDate(value));
            }
          },
        ),
        const SizedBox(height: AppSpacing.s6),
        AppButton(
          label: AppStrings.habitSaveHabit,
          isLoading: state.isSubmitting,
          onPressed: cubit.submit,
        ),
      ],
    );
  }
}

class _IconPicker extends StatelessWidget {
  const _IconPicker({required this.selected, required this.onChanged});

  final String selected;
  final void Function(String key) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.habitFormIconLabel,
          style: context.text.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.s2),
        Wrap(
          spacing: AppSpacing.s2,
          runSpacing: AppSpacing.s2,
          children: [
            for (final entry in habitIcons.entries)
              _IconOption(
                icon: entry.value,
                label: entry.key,
                isSelected: entry.key == selected,
                onTap: () => onChanged(entry.key),
              ),
          ],
        ),
      ],
    );
  }
}

class _IconOption extends StatelessWidget {
  const _IconOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = BorderRadius.circular(AppRadius.md);
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Material(
        color: p.surfaceMuted,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            width: AppSizes.minTouchTarget,
            height: AppSizes.minTouchTarget,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: isSelected ? p.primary : p.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Icon(icon, color: isSelected ? p.primary : p.iconMuted),
          ),
        ),
      ),
    );
  }
}

class _FrequencyPicker extends StatelessWidget {
  const _FrequencyPicker({required this.state, required this.cubit});

  final HabitFormState state;
  final HabitFormCubit cubit;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.habitFormFrequencyLabel,
          style: context.text.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.s2),
        SegmentedButton<HabitFrequencyType>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: HabitFrequencyType.daily,
              label: Text(
                AppStrings.habitFrequencyDaily,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ButtonSegment(
              value: HabitFrequencyType.weekdays,
              label: Text(
                AppStrings.habitFrequencyWeekdays,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ButtonSegment(
              value: HabitFrequencyType.timesPerWeek,
              label: Text(
                AppStrings.habitFrequencyTimesPerWeek,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          selected: {state.frequencyType},
          onSelectionChanged: (selection) =>
              cubit.frequencyChanged(selection.first),
          style: SegmentedButton.styleFrom(
            backgroundColor: p.surfaceMuted,
            foregroundColor: p.textPrimary,
            selectedBackgroundColor: p.primary,
            selectedForegroundColor: p.onPrimary,
            side: BorderSide(color: p.border),
            minimumSize: const Size.fromHeight(AppSizes.minTouchTarget),
          ),
        ),
        if (state.frequencyType == HabitFrequencyType.weekdays) ...[
          const SizedBox(height: AppSpacing.s3),
          _WeekdayRow(state: state, cubit: cubit),
        ],
        if (state.frequencyType == HabitFrequencyType.timesPerWeek) ...[
          const SizedBox(height: AppSpacing.s3),
          _TimesPerWeekStepper(state: state, cubit: cubit),
        ],
      ],
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  const _WeekdayRow({required this.state, required this.cubit});

  final HabitFormState state;
  final HabitFormCubit cubit;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // The 7 days (1 = Monday ... 7 = Sunday), starting on the user's week
    // start day.
    final days = [
      for (var i = 0; i < 7; i++) ((cubit.weekStartDay - 1 + i) % 7) + 1,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final day in days)
              _DayCircle(
                day: day,
                isSelected: state.weekdays.contains(day),
                onTap: () => cubit.weekdayToggled(day),
              ),
          ],
        ),
        if (state.weekdaysError != null) ...[
          const SizedBox(height: AppSpacing.s2),
          Text(
            state.weekdaysError!,
            style: context.text.bodySmall?.copyWith(color: p.error),
          ),
        ],
      ],
    );
  }
}

class _DayCircle extends StatelessWidget {
  const _DayCircle({
    required this.day,
    required this.isSelected,
    required this.onTap,
  });

  final int day;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      selected: isSelected,
      label: AppStrings.habitWeekdayName(day),
      child: InkResponse(
        onTap: onTap,
        radius: AppSizes.minTouchTarget / 2,
        child: SizedBox(
          width: AppSizes.minTouchTarget - AppSpacing.s2,
          height: AppSizes.minTouchTarget,
          child: Center(
            child: Container(
              width: AppSpacing.s10,
              height: AppSpacing.s10,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? p.primary : null,
                border: Border.all(color: isSelected ? p.primary : p.border),
              ),
              child: Text(
                AppStrings.habitWeekdayLetter(day),
                style: context.text.labelLarge?.copyWith(
                  color: isSelected ? p.onPrimary : p.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimesPerWeekStepper extends StatelessWidget {
  const _TimesPerWeekStepper({required this.state, required this.cubit});

  final HabitFormState state;
  final HabitFormCubit cubit;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final value = state.timesPerWeek;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: AppStrings.habitFormDecrease,
              onPressed: value > Habit.minTimesPerWeek
                  ? () => cubit.timesPerWeekChanged(value - 1)
                  : null,
              icon: const Icon(Icons.remove_rounded),
              style: IconButton.styleFrom(
                foregroundColor: p.tealStrong,
                disabledForegroundColor: p.iconMuted,
                side: BorderSide(
                  color: value > Habit.minTimesPerWeek ? p.teal : p.border,
                ),
                shape: const CircleBorder(),
                minimumSize: const Size.square(AppSizes.minTouchTarget),
              ),
            ),
            Expanded(
              child: Text(
                AppStrings.habitFormTimesPerWeekValue(value),
                textAlign: TextAlign.center,
                style: context.text.bodyLarge,
              ),
            ),
            IconButton(
              tooltip: AppStrings.habitFormIncrease,
              onPressed: value < Habit.maxTimesPerWeek
                  ? () => cubit.timesPerWeekChanged(value + 1)
                  : null,
              icon: const Icon(Icons.add_rounded),
              style: IconButton.styleFrom(
                foregroundColor: p.tealStrong,
                disabledForegroundColor: p.iconMuted,
                side: BorderSide(
                  color: value < Habit.maxTimesPerWeek ? p.teal : p.border,
                ),
                shape: const CircleBorder(),
                minimumSize: const Size.square(AppSizes.minTouchTarget),
              ),
            ),
          ],
        ),
        if (state.timesPerWeekError != null)
          Text(
            state.timesPerWeekError!,
            style: context.text.bodySmall?.copyWith(color: p.error),
          ),
      ],
    );
  }
}
