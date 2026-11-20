import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/widgets/widgets.dart';
import 'package:brainly_life/features/tasks/data/models/task_category_model.dart';
import 'package:brainly_life/features/tasks/data/repositories/task_category_repository.dart';
import 'package:brainly_life/features/tasks/logic/category_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A bottom sheet to add a category, or to edit its name and colour.
class CategoryEditorSheet extends StatefulWidget {
  const CategoryEditorSheet({super.key, this.category});

  /// null means a new category.
  final TaskCategory? category;

  /// Opens the sheet. Needs [CategoryCubit] above [context].
  static Future<void> show(BuildContext context, {TaskCategory? category}) {
    final cubit = context.read<CategoryCubit>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true, // moves up with the keyboard
      showDragHandle: true,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: CategoryEditorSheet(category: category),
      ),
    );
  }

  @override
  State<CategoryEditorSheet> createState() => _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends State<CategoryEditorSheet> {
  late final _name = TextEditingController(text: widget.category?.name);
  late int _color =
      widget.category?.colorValue ??
      ColorPickerRow.defaultColors.first.toARGB32();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final cubit = context.read<CategoryCubit>();
    final category = widget.category;
    final name = _name.text.trim();

    Failure? failure;
    if (category == null) {
      failure = await cubit.create(name, _color);
    } else {
      if (name != category.name) {
        failure = await cubit.rename(category, name);
      }
      if (failure == null && _color != category.colorValue) {
        failure = await cubit.recolor(category.copyWith(name: name), _color);
      }
    }
    if (!mounted) return;

    if (failure == null) {
      Navigator.of(context).pop();
      return;
    }
    final message = failure.userMessage;
    setState(() {
      _saving = false;
      _error = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.category == null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenMargin,
        0,
        AppSpacing.screenMargin,
        // Stay above the keyboard.
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.s6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isNew ? 'New category' : 'Edit category',
            style: context.text.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.s5),
          AppTextField(
            label: 'Name',
            hint: 'University, Personal...',
            controller: _name,
            errorText: _error,
            maxLength: TaskCategoryRepository.maxNameLength,
            autofocus: isNew,
            enabled: !_saving,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          const SizedBox(height: AppSpacing.s5),
          ColorPickerRow(
            label: 'Color',
            selectedColorValue: _color,
            onChanged: (value) => setState(() => _color = value),
          ),
          const SizedBox(height: AppSpacing.s6),
          AppButton(
            label: isNew ? 'Add category' : 'Save changes',
            isLoading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
