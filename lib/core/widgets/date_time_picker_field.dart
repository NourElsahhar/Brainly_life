// DateTimePickerField = a field that looks like AppTextField, but tapping it
// opens the date picker and/or the time picker.
//
// Usage:
//   DateTimePickerField(
//     label: 'Due date',
//     mode: DateTimePickerMode.dateTime,
//     value: state.dueAt,
//     errorText: state.dueAtError,
//     firstDate: DateTime.now(),            // optional: no dates in the past
//     clearable: true,                      // optional: shows an X button
//     onChanged: cubit.dueAtChanged,        // gets null when cleared
//   )
//
// Modes:
//   date      -> only a date (time is 00:00)
//   time      -> only a time (the date part is the old value's date, or today.
//                Read only hour and minute)
//   dateTime  -> date first, then time
//
// IMPORTANT: the value is LOCAL time. Convert to UTC (toUtc()) when you save,
// and back with toLocal() when you show it.
// Validation errors go in errorText (under the field), never in a snackbar.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/theme.dart';

enum DateTimePickerMode { date, time, dateTime }

class DateTimePickerField extends StatelessWidget {
  const DateTimePickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.mode = DateTimePickerMode.date,
    this.hint,
    this.errorText,
    this.firstDate,
    this.lastDate,
    this.clearable = false,
    this.enabled = true,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final DateTimePickerMode mode;
  final String? hint;
  final String? errorText;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool clearable;
  final bool enabled;

  String get _defaultHint => switch (mode) {
        DateTimePickerMode.date => 'Select date',
        DateTimePickerMode.time => 'Select time',
        DateTimePickerMode.dateTime => 'Select date and time',
      };

  IconData get _icon => switch (mode) {
        DateTimePickerMode.date => Icons.calendar_today_outlined,
        DateTimePickerMode.time => Icons.access_time_rounded,
        DateTimePickerMode.dateTime => Icons.event_outlined,
      };

  String _format(DateTime v) => switch (mode) {
        DateTimePickerMode.date => DateFormat.yMMMd().format(v),
        DateTimePickerMode.time => DateFormat.jm().format(v),
        DateTimePickerMode.dateTime =>
          '${DateFormat.yMMMd().format(v)}, ${DateFormat.jm().format(v)}',
      };

  DateTime _clamp(DateTime d, DateTime first, DateTime last) {
    if (d.isBefore(first)) return first;
    if (d.isAfter(last)) return last;
    return d;
  }

  Future<void> _pick(BuildContext context) async {
    final first = firstDate ?? DateTime(2000);
    final last = lastDate ?? DateTime(2100);
    final initial = _clamp(value ?? DateTime.now(), first, last);

    var pickedDate = initial;
    if (mode != DateTimePickerMode.time) {
      final date = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: first,
        lastDate: last,
      );
      if (date == null) return;
      pickedDate = date;
    }

    TimeOfDay? pickedTime;
    if (mode != DateTimePickerMode.date) {
      if (!context.mounted) return;
      pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initial),
      );
      if (pickedTime == null) return;
    }

    onChanged(
      DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime?.hour ?? 0,
        pickedTime?.minute ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final current = value;
    final radius = BorderRadius.circular(AppRadius.input);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.text.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.s2),
        Material(
          color: enabled ? p.surfaceMuted : p.surfaceSubtle,
          borderRadius: radius,
          child: InkWell(
            onTap: enabled ? () => _pick(context) : null,
            borderRadius: radius,
            child: Container(
              constraints: const BoxConstraints(minHeight: AppSizes.inputHeight),
              padding: const EdgeInsets.only(left: AppSpacing.s4),
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: errorText != null ? p.error : p.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(_icon, color: p.iconMuted, size: AppSizes.iconStandard),
                  const SizedBox(width: AppSpacing.s3),
                  Expanded(
                    child: Text(
                      current == null ? (hint ?? _defaultHint) : _format(current),
                      style: context.text.bodyLarge?.copyWith(
                        color: current == null ? p.textTertiary : null,
                      ),
                    ),
                  ),
                  if (clearable && current != null && enabled)
                    IconButton(
                      tooltip: 'Clear',
                      icon: Icon(
                        Icons.close_rounded,
                        color: p.iconMuted,
                        size: AppSizes.iconStandard,
                      ),
                      onPressed: () => onChanged(null),
                    )
                  else
                    const SizedBox(width: AppSpacing.s4),
                ],
              ),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s4,
              AppSpacing.s1,
              AppSpacing.s4,
              0,
            ),
            child: Text(
              errorText!,
              style: context.text.bodySmall?.copyWith(color: p.error),
            ),
          ),
      ],
    );
  }
}