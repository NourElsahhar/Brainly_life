import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/features/tasks/data/models/task_category_model.dart';
import 'package:brainly_life/features/tasks/logic/category_cubit.dart';
import 'package:brainly_life/features/tasks/logic/category_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Chips to pick the task's category: "Uncategorized" + the user's
/// categories. Needs [CategoryCubit] above it.
class CategoryPicker extends StatelessWidget {
  const CategoryPicker({
    super.key,
    required this.selectedId,
    required this.onChanged,
  });

  /// null means Uncategorized.
  final String? selectedId;

  /// null disables the chips (while saving).
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final state = context.watch<CategoryCubit>().state;

    return switch (state) {
      CategoryLoaded(:final categories) => Wrap(
        spacing: AppSpacing.s2,
        runSpacing: AppSpacing.s2,
        children: [
          _chip(context, id: null, name: 'Uncategorized'),
          for (final category in categories)
            _chip(
              context,
              id: category.id,
              name: category.name,
              category: category,
            ),
        ],
      ),
      CategoryError() => Row(
        children: [
          Expanded(
            child: Text(
              "Couldn't load categories.",
              style: context.text.bodyMedium?.copyWith(color: p.textSecondary),
            ),
          ),
          TextButton(
            onPressed: context.read<CategoryCubit>().load,
            child: const Text('Retry'),
          ),
        ],
      ),
      _ => const LinearProgressIndicator(),
    };
  }

  Widget _chip(
    BuildContext context, {
    required String? id,
    required String name,
    TaskCategory? category,
  }) {
    final p = context.palette;
    final selected = id == selectedId;
    final change = onChanged;

    return ChoiceChip(
      label: Text(name),
      selected: selected,
      showCheckmark: false,
      avatar: category == null
          ? null
          : CircleAvatar(
              radius: 6,
              backgroundColor: Color(category.colorValue),
            ),
      selectedColor: p.primarySoft,
      labelStyle: TextStyle(
        color: selected ? p.primary : p.textSecondary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
      onSelected: change == null ? null : (_) => change(id),
    );
  }
}
